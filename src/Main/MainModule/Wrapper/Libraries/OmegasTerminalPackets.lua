local ByteNet = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("ByteNet"))
local terminalSystem = ByteNet.defineNamespace("terminalSystem", function()
	return {
		statusUpdate = ByteNet.definePacket({
			value = ByteNet.unknown,
			reliabilityType = "reliable",
		}),

		partialStatusUpdate = ByteNet.definePacket({
			value = ByteNet.array(ByteNet.struct({
				stateKey = ByteNet.string,
				stateValue = ByteNet.unknown,
			})),
			reliabilityType = "unreliable",
		}),

		action = ByteNet.definePacket({
			value = ByteNet.struct({
				action = ByteNet.string,
				data = ByteNet.unknown,
			}),
			reliabilityType = "reliable",
		}),

		requestUI = ByteNet.definePacket({
			value = ByteNet.optional(ByteNet.bool),
			reliabilityType = "reliable",
		}),

		terminalEvent = ByteNet.definePacket({
			value = ByteNet.struct({
				eventName = ByteNet.string,
				data = ByteNet.unknown,
			}),
			reliabilityType = "reliable",
		}),
	}
end)

return terminalSystem
