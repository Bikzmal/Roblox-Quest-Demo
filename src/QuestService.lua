local QuestService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Services = ServerScriptService:WaitForChild("Services")

local QuestConfig = require(Config:WaitForChild("QuestConfig"))
local QuestStore = require(Services:WaitForChild("QuestStore"))
local RewardService = require(Services:WaitForChild("RewardService"))

function QuestService:GiveQuest(player, questName)
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
end

function QuestService:AddProgress(player, objectiveType, amount)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then return end
	
	local quest = QuestConfig[playerQuests.QuestName]
	if not quest then return end
	
	local objective

	for _, obj in ipairs(quest.Objectives) do
		if obj.Type == objectiveType then
			objective = obj
			break
		end
	end

	if not objective then return end
	
	playerQuests.Progress[objectiveType] = (playerQuests.Progress[objectiveType] or 0) + amount
	
	if playerQuests.Progress[objectiveType] > objective.Amount then
		playerQuests.Progress[objectiveType] = objective.Amount
	end
	
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
	end
end

function QuestService:HasObjectiveOfType(player, objectiveType)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then return false end
	
	for _, obj in ipairs(QuestConfig[playerQuests.QuestName].Objectives) do
		if obj.Type == objectiveType then
			return true
		end
	end
	
	return false
end

return QuestService
