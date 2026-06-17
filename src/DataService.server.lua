local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("Services")

local QuestStore = require(Services:WaitForChild("QuestStore"))
local QuestService = require(Services:WaitForChild("QuestService"))

local QuestDataStore = DataStoreService:GetDataStore("QuestData_v1")

local function savePlayer(player)
	local questData = QuestStore:Get(player)

	local success, err = pcall(function()
		if questData then
			QuestDataStore:SetAsync(
				player.UserId,
				questData
			)
		else
			QuestDataStore:RemoveAsync(player.UserId)
		end
	end)

	if not success then
		warn("Failed to save for " .. player.Name .. " , error: " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(function(player)
	local success, data = pcall(function()
		return QuestDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		QuestStore:Set(player, data)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
	QuestStore:Remove(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayer(player)
	end
end)
