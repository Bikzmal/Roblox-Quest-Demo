local QuestConfig = {}

QuestConfig.StarterQuest = {
	Name = "Starter Quest",
	
	Objectives = {
		{
			Type = "Walk",
			Amount = 100
		},
		
		{
			Type = "Jump",
			Amount = 10
		}
	},
	
	Rewards = {
		Coins = 100
	}
}

return QuestConfig
