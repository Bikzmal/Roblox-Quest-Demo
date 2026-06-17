local RewardService = {}

function RewardService:GiveRewards(player, rewards)
	print("Gave " .. player.Name .. " rewards")

	for rewardName, amount in pairs(rewards) do
		print(rewardName .. " " .. amount)
	end
end

return RewardService
