local UIAddon = {}

UIAddon.Libraries = {}

UIAddon.metadata = {
	name = "End sequence",
	description = "The default terminal end sequence addon",
	version = "v1.1",
	author = "Omega77073",
	compatibility = ">=2.0.0",
}
UIAddon.id = "default-terminalEndSequence"

UIAddon.init = function(wrapper)
	local terminalId = wrapper.terminal.terminalId
	local client = script.Client
	client:SetAttribute("terminalId", terminalId)
	client.Name = "Terminal end sequence client"
	client.Parent = game.StarterPlayer.StarterPlayerScripts
end

return UIAddon
