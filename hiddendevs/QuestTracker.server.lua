local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local Config = Shared:WaitForChild("Config")
local Services = ServerScriptService:WaitForChild("Services")

local QuestUpdated = Remotes:WaitForChild("QuestUpdated")
local StartQuest = Remotes:WaitForChild("StartQuest")

local QuestStore = require(Services:WaitForChild("QuestStore"))
local RewardService = require(Services:WaitForChild("RewardService"))
local QuestConfig = require(Config:WaitForChild("QuestConfig"))


function giveQuest(player, questName)
	local playerQuests = QuestStore:Get(player)
	if playerQuests then return end

	local quest = QuestConfig[questName]
	if not quest then
		warn("Quest not found, " .. questName)
		return
	end

	QuestStore:Set(player, {
		QuestName = questName,
		Progress = {}
	})
	
	print(player.Name .. " started quest " .. questName)
end

function isQuestCompleted(player, quest)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then return end
	
	local completed = true

	for _, obj in ipairs(quest.Objectives) do
		local progress = playerQuests.Progress[obj.Type] or 0

		if progress < obj.Amount then
			completed = false
			break
		end
	end

	if completed then
		if quest.Rewards then
			RewardService:GiveRewards(player, quest.Rewards)
		end
		QuestStore:Remove(player)
		
		print(player.Name .. " completed quest " .. questName)
	end
end

function getObjective(player, quest, objectiveType)
	local objective

	for _, obj in ipairs(quest.Objectives) do
		if obj.Type == objectiveType then
			objective = obj
			break
		end
	end

	if not objective then 
		return nil
	else
		return objective
	end
end

function addProgress(player, objectiveType, amount)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then return end

	local quest = QuestConfig[playerQuests.QuestName]
	if not quest then return end

	local objective = getObjective(player, quest, objectiveType)
	if not objective then return end

	playerQuests.Progress[objectiveType] = (playerQuests.Progress[objectiveType] or 0) + amount

	if playerQuests.Progress[objectiveType] > objective.Amount then
		playerQuests.Progress[objectiveType] = objective.Amount
	end

	isQuestCompleted(player, quest)
end

function hasObjectiveOfType(player, objectiveType)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then return false end

	for _, obj in ipairs(QuestConfig[playerQuests.QuestName].Objectives) do
		if obj.Type == objectiveType then
			return true
		end
	end

	return false
end

function hasObjectiveTarget(player, objectiveType, targetName)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then
		return false
	end

	local quest = QuestConfig[playerQuests.QuestName]
	if not quest then
		return false
	end

	for _, obj in ipairs(quest.Objectives) do
		if obj.Type == objectiveType and obj.Target == targetName then
			return true
		end
	end

	return false
end

function getQuestCompletionPercentage(player)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then 
		return 0 
	end
	
	local quest = QuestConfig[playerQuests.QuestName]
	if not quest then 
		return 0 
	end
	
	if #quest.Objectives == 0 then
		return 0
	end
	
	local percentages = {}
	
	for i, obj in ipairs(quest.Objectives) do
		local progress = playerQuests.Progress[obj.Type] or 0
		
		percentages[i] = progress / obj.Amount
	end
	
	local total = 0
	
	for _, p in ipairs(percentages) do
		total += p
	end
	
	local average = total / #quest.Objectives
	local final = math.floor(average * 100)
	
	return final
end

function setupReachLocations()
	local questZones = workspace:WaitForChild("QuestZones")

	for _, zone in ipairs(questZones:GetChildren()) do
		if zone:IsA("BasePart") then
			zone.Touched:Connect(function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				if not character then return end

				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end

				if not hasObjectiveTarget(player, "ReachLocation", zone.Name) then
					return
				end

				addProgress(player, "ReachLocation", 1)
				updateUi(player)
			end)
			
			print("Set up zone " .. zone.Name)
		end
	end
end

function trackWalking(player, character)
	local root = character:WaitForChild("HumanoidRootPart")
	if not root then return end
	
	local lastPosition = root.Position
	
	while root and root.Parent do
		task.wait(.2)
		
		if not hasObjectiveOfType(player, "Walk") then 
			continue
		end
		
		local currentPosition = root.Position
		local distance = (currentPosition - lastPosition).Magnitude
		
		if distance > 80 then
			lastPosition = currentPosition
			continue
		elseif distance < 0.1 then
			lastPosition = currentPosition
			continue
		elseif distance > 0 then
			addProgress(player, "Walk", distance)
		end
		
		lastPosition = currentPosition
		
		updateUi(player)
	end
end

function trackJumping(player, character)
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	if not humanoid then return end
	
	humanoid.Jumping:Connect(function(isJumping)
		if not isJumping then return end
		addProgress(player, "Jump", 1)
		
		updateUi(player)
	end)
end

function trackPlaytime(player)
	local startTime = os.time()
	
	while player.Parent do
		task.wait(1)
		
		if not hasObjectiveOfType(player, "Playtime") then 
			continue 
		end
		
		addProgress(player, "Playtime", 1)
		
		updateUi(player)
	end
end

function updateUi(player)
	local playerQuests = QuestStore:Get(player)

	QuestUpdated:FireClient(player, playerQuests, getQuestCompletionPercentage(player))
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
	
	giveQuest(player, questName)
	updateUi(player)
end)

setupReachLocations()
