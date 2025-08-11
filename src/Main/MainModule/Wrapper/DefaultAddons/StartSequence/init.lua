local UIAddon = {}

UIAddon.Libraries = {}

UIAddon.metadata = {
	name = "Start sequence",
	description = "The default terminal start sequence addon",
	version = "v1.1",
	author = "Omega77073",
	compatibility = ">=1.2.0",
}
UIAddon.id = "default-terminalStartSequence"

UIAddon.init = function(wrapper)
	local terminalId = wrapper.terminal.terminalId
	local client = script.Client
	client:SetAttribute("terminalId", terminalId)
	client.Name = "Terminal start sequence client"
	client.Parent = game.StarterPlayer.StarterPlayerScripts
end

return UIAddon
