local UIAddon = {}
UIAddon.Libraries = {}

UIAddon.metadata = {
	name = "Terminal UI",
	description = "The default terminal progress UI addon",
	version = "v1.1",
	author = "Omega77073",
	compatibility = ">=1.2.0",
}
UIAddon.id = "default-terminalUi"

UIAddon.init = function(wrapper)
	local terminalId = wrapper.terminal.terminalId
	local client = script.Client:FindFirstChild(terminalId)
	if client == nil then
		error(`Could not find a UI client for terminal id: {terminalId}`)
	end
	client.Name = "Terminal UI Client"
	client:SetAttribute("terminalId", terminalId)
	client.Parent = game.StarterPlayer.StarterPlayerScripts
end

return UIAddon
