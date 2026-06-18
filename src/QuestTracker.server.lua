local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local Services = ServerScriptService:WaitForChild("Services")

local StartQuest = Remotes:WaitForChild("StartQuest")

local QuestService = require(Services:WaitForChild("QuestService"))

local function setupReachLocations()
	local questZones = workspace:WaitForChild("QuestZones")

	for _, zone in ipairs(questZones:GetChildren()) do
		if zone:IsA("BasePart") then
			zone.Touched:Connect(function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				if not character then return end

				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end

				if not QuestService:HasObjectiveTarget(player, "ReachLocation", zone.Name) then
					return
				end

				QuestService:AddProgress(player, "ReachLocation", 1)
			end)

			print("Set up zone " .. zone.Name)
		end
	end
end

local function trackWalking(player, character)
	local root = character:WaitForChild("HumanoidRootPart")
	if not root then return end

	local lastPosition = root.Position

	while root and root.Parent do
		task.wait(0.2)

		if not QuestService:HasObjectiveOfType(player, "Walk") then
			lastPosition = root.Position
			continue
		end

		local currentPosition = root.Position
		local distance = (currentPosition - lastPosition).Magnitude

		if distance > 80 then
			lastPosition = currentPosition
			continue
		end

		if distance < 0.1 then
			lastPosition = currentPosition
			continue
		end

		QuestService:AddProgress(player, "Walk", distance)
		lastPosition = currentPosition
	end
end

local function trackJumping(player, character)
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	if not humanoid then return end

	humanoid.Jumping:Connect(function(isJumping)
		if not isJumping then return end

		QuestService:AddProgress(player, "Jump", 1)
	end)
end

local function trackPlaytime(player)
	while player.Parent do
		task.wait(1)

		if not QuestService:HasObjectiveOfType(player, "Playtime") then
			continue
		end

		QuestService:AddProgress(player, "Playtime", 1)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(trackPlaytime, player)

	player.CharacterAdded:Connect(function(character)
		task.spawn(trackWalking, player, character)
		task.spawn(trackJumping, player, character)
	end)
end)

StartQuest.OnServerEvent:Connect(function(player, questName)
	if typeof(questName) ~= "string" then return end

	QuestService:GiveQuest(player, questName)
end)

setupReachLocations()
