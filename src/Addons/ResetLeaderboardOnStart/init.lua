local Addon = {}

Addon.Libraries = {}
Addon.metadata = {
	name = "Reset leaderboard on start",
	description = "Reset players' leaderboard stats on terminal start",
	version = "v1.1",
	author = "Omega77073",
	compatibility = ">=1.2.0",
}
Addon.id = "resetLeaderboardOnStart"
Addon.init = function(wrapper)
	wrapper.terminal.events.startEvent.Event:Connect(function()
		for _, player in pairs(game.Players:GetPlayers()) do
			if player:FindFirstChild("leaderstats") ~= nil then
				for _, stat: Instance in pairs(player.leaderstats:GetChildren()) do
					if stat:IsA("NumberValue") or stat:IsA("IntValue") then
						stat.Value = 0
					end
				end
			end
		end
	end)
end

return Addon
