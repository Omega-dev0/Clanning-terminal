local UIAddon = {}
UIAddon.Libraries = {}

UIAddon.metadata = {
	name = "Terminal UI Boilerplate",
	description = "A boilerplate for creating terminal UI addons",
	version = "v1.1",
	author = "---",
	compatibility = ">=1.2.0",
}
UIAddon.id = "terminalUi"

local terminalType = "default"

UIAddon.init = function(wrapper)
	local terminalId = wrapper.terminal.terminalId
	assert(
		terminalId == terminalType,
		`Expected terminal type "${terminalType}", got "${terminalId}", UI can only be used for ${terminalType} terminals.`
	)
	local client = script.Client
	client.Name = "Terminal UI Client"
	client:SetAttribute("terminalId", terminalId)
	client.Parent = game.StarterPlayer.StarterPlayerScripts
end

return UIAddon
