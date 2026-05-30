local packets = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("OmegasTerminalPackets"))

packets.systemChat.listen(function(data)
	local message = data.message
	local metadata = data.metadata
	game:GetService("TextChatService").TextChannels.RBXGeneral:DisplaySystemMessage(message, metadata)
end)
