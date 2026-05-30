local OptimizationAddon = {}
local RunService = game:GetService("RunService")

OptimizationAddon.Libraries = script.Libraries:GetChildren()
OptimizationAddon.metadata = {
	name = "Payload Network optimization",
	description = "An addon to reduce network usage for payload terminals",
	version = "v1.0",
	author = "Omega77073",
	compatibility = ">=2.0.0",
}

OptimizationAddon.init = function(wrapper)
	local clientHelper = script.clientHelper
	clientHelper.Name = "Payload Terminal Optimization Client Helper"
	clientHelper.Parent = game.StarterPlayer.StarterPlayerScripts

	local packets = require(game.ReplicatedStorage.Libraries:WaitForChild("payloadOptimizationPackets"))

	local payloadModel, waypoints = wrapper.terminal.config.payloadModel, wrapper.terminal.config.waypoints
	local splineAlpha, splineTension = wrapper.terminal.config.splineAlpha, wrapper.terminal.config.splineTension

	packets.requestConfig.listen(function(data, player)
		packets.getConfig.sendTo({
			model = payloadModel,
			waypoints = waypoints,
			splineTension = splineTension,
			splineAlpha = splineAlpha,
		}, player)
	end)

	--payloadModel.Parent = workspace.CurrentCamera

	wrapper:SwitchTerminalComponent("movePayloadModel", function(terminal, newCFrame, newProgress)
		packets.move.sendToAll(math.round(newProgress * 100))
	end)
end

return OptimizationAddon
