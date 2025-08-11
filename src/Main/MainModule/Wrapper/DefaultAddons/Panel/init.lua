local panelAddon = {}
local packets = require(game.ReplicatedStorage:WaitForChild("Libraries"):FindFirstChild("OmegasTerminalPackets"))
panelAddon.Libraries = script.Libraries:GetChildren()
panelAddon.metadata = {
	name = "Terminal Panel",
	description = "The default terminal progress panel addon",
	version = "v1.1",
	author = "Omega77073",
	compatibility = ">=1.2.0",
}
panelAddon.id = "default-terminalPanel"

panelAddon.init = function(wrapper)
	local config = wrapper.config

	packets.action.listen(function(data, player)
		local actionKeys = string.split(data.action, "_")
		if not config.isAdmin(player) then
			return
		end
		if actionKeys[1] == "modifyConfig" then
			local mergedConfig = data.data.core
			for key, value in pairs(data.data.terminal) do
				mergedConfig[key] = value
			end
			wrapper.controls:modifyConfig(player, mergedConfig)
			wrapper.updatePersistantConfig()
		elseif actionKeys[1] == "control" then
			local controlType = actionKeys[2]
			local controls = {
				freezeTime = function()
					wrapper.controls:FreezeTime(player)
				end,
				unfreezeTime = function()
					wrapper.controls:UnfreezeTime(player)
				end,
				addTime = function(amount)
					wrapper.controls:AddTime(amount, player)
				end,
				removeTime = function(amount)
					wrapper.controls:AddTime(-amount, player)
				end,

				addProgress = function(team, progress)
					wrapper.controls:AddProgress(player, team, progress)
				end,
				removeProgress = function(team, progress)
					wrapper.controls:AddProgress(player, team, -progress)
				end,

				lockTerminal = function()
					wrapper.controls:Lock()
				end,
				unlockTerminal = function()
					wrapper.controls:Unlock()
				end,

				reset = function()
					wrapper.controls:Reset()
				end,

				stop = function()
					wrapper.controls:Stop()
				end,

				start = function()
					wrapper.controls:Start()
				end,
			}

			if controls[controlType] then
				if data.data ~= nil then
					controls[controlType](table.unpack(data.data))
				else
					controls[controlType]()
				end
			else
				error("Invalid control type: " .. tostring(controlType))
			end
		end
	end)

	local terminalId = wrapper.terminal.terminalId
	local client = script.Client:FindFirstChild(terminalId)
	if client == nil then
		error(`Could not find a panel client for terminal id: {terminalId}`)
	end
	client.Name = "Terminal Panel Client"
	client:SetAttribute("terminalId", terminalId)
	client.Parent = game.StarterPlayer.StarterPlayerScripts
end

return panelAddon
