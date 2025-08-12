local gui = script:FindFirstChildOfClass("ScreenGui")
gui.Enabled = false
gui.Parent = game.Players.LocalPlayer.PlayerGui

local httpService = game:GetService("HttpService")
local config = game.ReplicatedStorage:WaitForChild("OmegasTerminalConfig_Persistant") :: Configuration

type sequenceController = {
	display: (config: any, data: any) -> (),
	hide: () -> (),

	showCloudLogging: (toggle: boolean) -> ()?,
}

local controller = require(gui.Controller) :: sequenceController

local packets = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("OmegasTerminalPackets"))
packets.terminalEvent.listen(function(data)
	if data.eventName == "end" then
		local cfg = {
			core = httpService:JSONDecode(config:GetAttribute("core_config")),
			terminal = httpService:JSONDecode(config:GetAttribute("terminal_config")),
			properties = httpService:JSONDecode(config:GetAttribute("properties")),
		}
		if controller.showCloudLogging ~= nil then
			controller.showCloudLogging(cfg.properties.isCloudLoggingEnabled)
		end
		controller.display(cfg, data.data)
	end
end)
