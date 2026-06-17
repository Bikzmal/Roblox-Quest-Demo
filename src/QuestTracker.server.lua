local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local Services = ServerScriptService:WaitForChild("Services")

local QuestUpdated = Remotes:WaitForChild("QuestUpdated")
local StartQuest = Remotes:WaitForChild("StartQuest")

local QuestService = require(Services:WaitForChild("QuestService"))
local QuestStore = require(Services:WaitForChild("QuestStore"))


function trackWalking(player, character)
	local root = character:WaitForChild("HumanoidRootPart")
	if not root then return end
	
	local lastPosition = root.Position
	
	while root and root.Parent do
		task.wait(1)
		
		if not QuestService:HasObjectiveOfType(player, "Walk") then continue end
		
		local currentPosition = root.Position
		local distance = (currentPosition - lastPosition).Magnitude
		
		if distance > 0 then
			QuestService:AddProgress(player, "Walk", distance)
		end
		
		lastPosition = currentPosition
	end
end

function trackJumping(player, character)
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	if not humanoid then return end
	
	humanoid.Jumping:Connect(function(isJumping)
		if not isJumping then return end
		QuestService:AddProgress(player, "Jump", 1)
	end)
end

function updateUi(player)
	while true do
		local playerQuests = QuestStore:Get(player)

		QuestUpdated:FireClient(player, playerQuests)
		
		task.wait(.2)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(updateUi, player)
	
	player.CharacterAdded:Connect(function(character)
		task.spawn(trackWalking, player, character)
		task.spawn(trackJumping, player, character)
	end)
end)

StartQuest.OnServerEvent:Connect(function(player, questName)
	QuestService:GiveQuest(player, questName)
end)
