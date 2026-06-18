local QuestService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Remotes = Shared:WaitForChild("Remotes")
local Services = ServerScriptService:WaitForChild("Services")

local QuestUpdated = Remotes:WaitForChild("QuestUpdated")

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

	print(player.Name .. " started quest " .. questName)
	self:UpdateUi(player)
end

function QuestService:GetObjective(quest, objectiveType)
	for _, obj in ipairs(quest.Objectives) do
		if obj.Type == objectiveType then
			return obj
		end
	end

	return nil
end

function QuestService:AddProgress(player, objectiveType, amount)
	if amount <= 0 then return end

	local playerQuests = QuestStore:Get(player)
	if not playerQuests then return end

	local quest = QuestConfig[playerQuests.QuestName]
	if not quest then return end

	local objective = self:GetObjective(quest, objectiveType)
	if not objective then return end

	playerQuests.Progress[objectiveType] = (playerQuests.Progress[objectiveType] or 0) + amount

	if playerQuests.Progress[objectiveType] > objective.Amount then
		playerQuests.Progress[objectiveType] = objective.Amount
	end

	self:CheckCompletion(player, quest)
	self:UpdateUi(player)
end

function QuestService:CheckCompletion(player, quest)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then return end

	for _, obj in ipairs(quest.Objectives) do
		local progress = playerQuests.Progress[obj.Type] or 0

		if progress < obj.Amount then
			return
		end
	end

	if quest.Rewards then
		RewardService:GiveRewards(player, quest.Rewards)
	end

	print(player.Name .. " completed quest " .. playerQuests.QuestName)
	QuestStore:Remove(player)

	self:UpdateUi(player)
end

function QuestService:HasObjectiveOfType(player, objectiveType)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then return false end

	local quest = QuestConfig[playerQuests.QuestName]
	if not quest then return false end

	for _, obj in ipairs(quest.Objectives) do
		if obj.Type == objectiveType then
			return true
		end
	end

	return false
end

function QuestService:HasObjectiveTarget(player, objectiveType, targetName)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then return false end

	local quest = QuestConfig[playerQuests.QuestName]
	if not quest then return false end

	for _, obj in ipairs(quest.Objectives) do
		if obj.Type == objectiveType and obj.Target == targetName then
			return true
		end
	end

	return false
end

function QuestService:GetCompletionPercentage(player)
	local playerQuests = QuestStore:Get(player)
	if not playerQuests then return 0 end

	local quest = QuestConfig[playerQuests.QuestName]
	if not quest then return 0 end

	if #quest.Objectives == 0 then
		return 0
	end

	local total = 0

	for _, obj in ipairs(quest.Objectives) do
		local progress = playerQuests.Progress[obj.Type] or 0
		local percentage = math.clamp(progress / obj.Amount, 0, 1)

		total += percentage
	end

	return math.floor((total / #quest.Objectives) * 100)
end

function QuestService:UpdateUi(player)
	local playerQuests = QuestStore:Get(player)
	local percentage = self:GetCompletionPercentage(player)

	QuestUpdated:FireClient(player, playerQuests, percentage)
end

return QuestService
