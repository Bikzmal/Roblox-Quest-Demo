local QuestStore = {}

local PlayerQuests = {}

function QuestStore:Set(player, data)
	PlayerQuests[player] = data
end

function QuestStore:Get(player)
	return PlayerQuests[player]
end

function QuestStore:Remove(player)
	PlayerQuests[player] = nil
end

return QuestStore
