local Addon = {}

Addon.Libraries = {}
Addon.metadata = {
	name = "Respawn on start",
	description = "Respawn players in playing teams on terminal start",
	version = "v1.1",
	author = "Omega77073",
	compatibility = ">=1.2.0",
}
Addon.id = "respawnOnStart"
Addon.init = function(wrapper)
	wrapper.terminal.events.startEvent.Event:Connect(function()
		for _, player in pairs(game.Players:GetPlayers()) do
			if player.Team == wrapper.config.attackers.team or player.Team == wrapper.config.defenders.team then
				player:LoadCharacter()
			end
		end
	end)
end

return Addon
