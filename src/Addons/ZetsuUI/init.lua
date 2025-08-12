local UIAddon = {}
UIAddon.Libraries = {}

UIAddon.metadata = {
	name = "Zetsu terminal UI",
	description = "An addon to mimic Zetsu's UI style for the default terminal type",
	version = "v1.1",
	author = "Omega77073",
	compatibility = ">=1.2.0",
}
UIAddon.id = "terminalUi-zetsu"

UIAddon.init = function(wrapper)
	local terminalId = wrapper.terminal.terminalId
	if terminalId ~= "default" then
		error(`[TERMINAL ADDON] - Zetsu UI can only be used with the default terminal, you are using: {terminalId}`)
	end
	local client = script.Client
	client.Name = "Terminal UI Client"
	client:SetAttribute("terminalId", terminalId)
	client.Parent = game.StarterPlayer.StarterPlayerScripts
end

return UIAddon
