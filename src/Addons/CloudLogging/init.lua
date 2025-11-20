local CloudLoggingAddon = {}
local httpService = game:GetService("HttpService")
local LocalizationService = game:GetService("LocalizationService")
local RunService = game:GetService("RunService")

CloudLoggingAddon.Libraries = script.Libraries:GetChildren()
CloudLoggingAddon.metadata = {
	name = "Cloud Logging",
	description = "The default cloud logging addon",
	version = "v1.1",
	author = "Omega77073",
	compatibility = ">=2.0.0",
}
CloudLoggingAddon.id = "default-cloudLogging"
local locationConnection
CloudLoggingAddon.init = function(wrapper)
	local configInstance = script.Configuration

	local PRIVATE_KEY_BUFFER = buffer.fromstring(configInstance:GetAttribute("_Private_Key"))
	local API_KEY = configInstance:GetAttribute("_API_Key")
	local SHA256 = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("SHA"))
	local serverLocationModule = require(script.serverLocation)
	local SERVER_LOCATION

	local SERVER_URL = RunService:IsStudio() and configInstance:GetAttribute("StudioServerURL")
		or configInstance:GetAttribute("ServerURL")

	if configInstance:GetAttribute("Enabled") == false or configInstance:GetAttribute("_API_Key") == "" then
		print("CloudLoggingAddon: Online reporting is disabled in the config, skipping initialization.")
		wrapper.properties.isCloudLoggingEnabled = false
		return
	end
	wrapper.properties.isCloudLoggingEnabled = true

	locationConnection = game.Players.PlayerAdded:Connect(function(player)
		local success, translator = pcall(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(player)
		end)
		local country = serverLocationModule(translator)
		if country then
			SERVER_LOCATION = country
			locationConnection:Disconnect()
		end
	end)
	wrapper.terminal.events.startEvent.Event:Connect(function()
		--New session
		local sessionId = httpService:GenerateGUID(false)
		local sessionConnections = {}
		local sessionData = {
			sessionId = sessionId,
			placeId = game.PlaceId,
			placeName = workspace:GetAttribute("GameName"),
			startTime = os.time(),
			ended = false,
			terminalStateHistory = {
				{
					time = 0,
					state = "neutral",
				},
			},
			logs = {},
			leaderstats = {},
		}

		table.insert(
			sessionConnections,
			game.ReplicatedStorage:WaitForChild("Terminal-LogEvent").Event:Connect(function(message, UserId)
				table.insert(sessionData.logs, {
					time = os.time(),
					message = `[TERMINAL] - {message}`,
					userId = UserId,
				})
			end)
		)

		table.insert(
			sessionConnections,
			game:GetService("LogService").MessageOut:Connect(function(message, messageType)
				local command = message:match("^> (.*)")
				if messageType == Enum.MessageType.MessageOutput and command then
					table.insert(sessionData.logs, {
						time = os.time(),
						message = `[CONSOLE] - {message}`,
						userId = "UNKNOWN",
					})
				end
			end)
		)

		local _K = shared._K_INTERFACE
		if _K then
			table.insert(
				sessionConnections,
				_K.Hook.runPreparedCommands:Connect(function(from, result, rawText)
					table.insert(sessionData.logs, {
						time = os.time(),
						message = `[COMMAND] - {rawText}`,
						userId = from,
					})
				end)
			)
		end
	end)
end

return CloudLoggingAddon
