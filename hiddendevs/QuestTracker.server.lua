-- Connected Discord-GitHub

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Folders
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local Config = Shared:WaitForChild("Config")
local Services = ServerScriptService:WaitForChild("Services")

-- Remotes
local QuestUpdated = Remotes:WaitForChild("QuestUpdated")
local StartQuest = Remotes:WaitForChild("StartQuest")

-- Modules
local QuestStore = require(Services:WaitForChild("QuestStore"))
local RewardService = require(Services:WaitForChild("RewardService"))
local QuestConfig = require(Config:WaitForChild("QuestConfig"))


-- Quests given to the player are stored separate from the QuestConfig module
-- QuestConfig defines quests while QuestStore tracks the progress of the quest
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

-- Gets the players quest and the config for that quest to avoid repetition in the other quest functions
function getQuest(player)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then
		return nil, nil
	end

	local quest = QuestConfig[playerQuests.QuestName]
	if not quest then
		return playerQuests, nil
	end

	return playerQuests, quest
end

-- Checks whether every objective in the current quest has reached the target
-- Rewards are given serverside before removing the quest from QuestStore
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

		print(player.Name .. " completed quest " .. playerQuests.QuestName)
	end
end

-- Searches the quest objectives for a matching type
-- This allows for multiple objectives of the same type to reuse the same progress system
function getObjective(quest, objectiveType)
	local objective

	for _, obj in ipairs(quest.Objectives) do
		if obj.Type == objectiveType then
			objective = obj
			break
		end
	end

	return objective
end

-- Adds progress to the objective
-- Objectives are stored by type so it can work for all types of objectives like: walk, jump, playtime
function addProgress(player, objectiveType, amount)
	local playerQuests, quest = getQuest(player)
	if not playerQuests or not quest then return end

	local objective = getObjective(quest, objectiveType)
	if not objective then return end
	
	if amount <= 0 then return end

	playerQuests.Progress[objectiveType] = (playerQuests.Progress[objectiveType] or 0) + amount

	if playerQuests.Progress[objectiveType] > objective.Amount then
		playerQuests.Progress[objectiveType] = objective.Amount
	end

	isQuestCompleted(player, quest)
end

-- Used by tracking system to check if a players quest has an objective of a specific type before adding progress
-- This is so it doesnt add progress to an objective type you do not have
function hasObjectiveOfType(player, objectiveType)
	local playerQuests, quest = getQuest(player)
	if not playerQuests or not quest then return false end

	for _, obj in ipairs(quest.Objectives) do
		if obj.Type == objectiveType then
			return true
		end
	end

	return false
end

-- Some objectives have a target, like ReachLocation
-- This validates that the players quest has an objective for this target
function hasObjectiveTarget(player, objectiveType, targetName)
	local playerQuests, quest = getQuest(player)
	if not playerQuests or not quest then return false end

	for _, obj in ipairs(quest.Objectives) do
		if obj.Type == objectiveType and obj.Target == targetName then
			return true
		end
	end

	return false
end

-- Returns the percentage of the quest
-- This can be used for the quest UI
function getQuestCompletionPercentage(player)
	local playerQuests, quest = getQuest(player)
	if not playerQuests or not quest then return 0 end

	if #quest.Objectives == 0 then
		return 0
	end

	local percentages = {}

	for i, obj in ipairs(quest.Objectives) do
		local progress = playerQuests.Progress[obj.Type] or 0

		percentages[i] = math.clamp(progress / obj.Amount, 0, 1)
	end

	local total = 0

	for _, p in ipairs(percentages) do
		total += p
	end

	local average = total / #quest.Objectives
	local final = math.floor(average * 100)

	return final
end

-- Updates the UI
-- This sends the quest data and the completion percentage to the client for the UI to update
function updateUi(player)
	local playerQuests = QuestStore:Get(player)

	QuestUpdated:FireClient(player, playerQuests, getQuestCompletionPercentage(player))
end

-- ReachLocation objectives are handled with trigger parts in the workspace
-- When a player touches a valid trigger part, the progress is given
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

-- Tracks the players movement and adds progress to the "Walk" objective
-- Measured by distance walked every 0.2 seconds, which is then added to the progress
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

		if distance > 80 or distance < 0.1 then
			lastPosition = currentPosition
			continue
		elseif distance > 0 then
			addProgress(player, "Walk", distance)
		end

		lastPosition = currentPosition

		updateUi(player)
	end
end

-- Tracks the players jumping and adds progress to the "Jump" objective
-- This listens for the humanoids jumping state and uses a debounce so it only counts the jump once
-- Using Humanoid.StateChanged because it is more reliable than Humanoid.Jumping
function trackJumping(player, character)
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	if not humanoid then return end

	local canCountJump = true
	
	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping and canCountJump then
			canCountJump = false
			
			if hasObjectiveOfType(player, "Jump") then
				addProgress(player, "Jump", 1)
				updateUi(player)
			end
		end
		
		if newState == Enum.HumanoidStateType.Landed 
			or newState == Enum.HumanoidStateType.Running
			or newState == Enum.HumanoidStateType.RunningNoPhysics then
			canCountJump = true
		end
	end)
end

-- Tracks the players playtime and adds progress to the "Playtime" objective
-- This is done by incrementing the progress every second
function trackPlaytime(player)
	while player.Parent do
		task.wait(1)

		if not hasObjectiveOfType(player, "Playtime") then 
			continue 
		end

		addProgress(player, "Playtime", 1)

		updateUi(player)
	end
end

-- When a player joins, it will track their playtime, movement, and jumping
-- Using task.spawn so the code in the functions does not block the other ones from running
Players.PlayerAdded:Connect(function(player)
	task.spawn(trackPlaytime, player)

	player.CharacterAdded:Connect(function(character)
		task.spawn(trackWalking, player, character)
		task.spawn(trackJumping, player, character)
	end)
end)

-- Quest starting is requested by client, but server validates the quest name to be a string, 
-- and only gives it if it exists in QuestConfig
-- This prevents invalid remote data from being used by the server
-- Quest validation is performed on the server rather than trusting the client
StartQuest.OnServerEvent:Connect(function(player, questName)
	if typeof(questName) ~= "string" then return end

	giveQuest(player, questName)
	updateUi(player)
end)

setupReachLocations()
