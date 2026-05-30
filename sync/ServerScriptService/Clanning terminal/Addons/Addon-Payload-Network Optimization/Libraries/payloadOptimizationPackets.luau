local ByteNet = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("ByteNet"))
local po = ByteNet.defineNamespace("terminal-payloadOptimization", function()
	return {
		move = ByteNet.definePacket({
			value = ByteNet.uint16,
		}),

		getConfig = ByteNet.definePacket({
			value = ByteNet.struct({
				model = ByteNet.inst,
				waypoints = ByteNet.array(ByteNet.cframe),
				splineTension = ByteNet.float,
				splineAlpha = ByteNet.float64,
			}),
		}),

		requestConfig = ByteNet.definePacket({
			value = ByteNet.nothing,
		}),
	}
end)

return po
