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
	compatibility = ">=1.2.0",
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

		local playTimeList = {}
		task.spawn(function()
			while not sessionData.ended do
				task.wait(1)
				for _, player in pairs(game.Players:GetPlayers()) do
					if not playTimeList[player.UserId] then
						playTimeList[player.UserId] = {
							attackers = 0,
							defenders = 0,
						}
					end
					if player.Team == wrapper.config.attackersTeam then
						playTimeList[player.UserId].attackers += 1
					elseif player.Team == wrapper.config.defendersTeam then
						playTimeList[player.UserId].defenders += 1
					end

					if not sessionData.leaderstats[player.UserId] then
						sessionData.leaderstats[player.UserId] = {}
					end
					if player:FindFirstChild("leaderstats") then
						for _, c in pairs(player:FindFirstChild("leaderstats"):GetChildren()) do
							if not sessionData.leaderstats[player.UserId][c.Name] then
								sessionData.leaderstats[player.UserId][c.Name] = 0
							end
							sessionData.leaderstats[player.UserId][c.Name] = c.Value
						end
					end
				end
			end
		end)

		table.insert(
			sessionConnections,
			wrapper.terminal.events.stateChanged.Event:Connect(function(newState)
				local lastState = sessionData.terminalStateHistory[#sessionData.terminalStateHistory]
				if lastState.state ~= newState then
					table.insert(sessionData.terminalStateHistory, {
						time = os.time() - sessionData.startTime,
						state = newState,
					})
				end
			end)
		)

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

		wrapper.terminal.events.endEvent.Event:Connect(function()
			sessionData.ended = true
			sessionData.endTime = os.time()
			sessionData.playTimeList = playTimeList
			sessionData.config = {
				core = httpService:JSONDecode(
					game.ReplicatedStorage:WaitForChild("OmegasTerminalConfig_Persistant"):GetAttribute("core_config")
				),
				terminal = httpService:JSONDecode(
					game.ReplicatedStorage
						:WaitForChild("OmegasTerminalConfig_Persistant")
						:GetAttribute("terminal_config")
				),
			}
			sessionData.jobId = game.JobId
			sessionData.serverLocation = SERVER_LOCATION or "Unknown"
			sessionData.version = CloudLoggingAddon.metadata.version
			sessionData.attackerPoints = wrapper.terminal.attackerPoints
			sessionData.defenderPoints = wrapper.terminal.defenderPoints
			sessionData.hash = SHA256(buffer.fromstring(httpService:JSONEncode(sessionData)), PRIVATE_KEY_BUFFER)

			local function Upload()
				httpService:PostAsync(
					SERVER_URL,
					httpService:JSONEncode(sessionData),
					Enum.HttpContentType.ApplicationJson,
					true,
					{
						["Authorization"] = `{API_KEY} {game.PlaceId}`,
					}
				)
				game.ReplicatedStorage.Event:Fire(sessionData)
			end

			local success, err = pcall(Upload)
			if not success and RunService:IsStudio() == false then
				warn(`Failed to upload match data: {err}`)
				warn("Retrying in 10 seconds...")
				task.wait(10)
				success, err = pcall(Upload)
				if not success then
					error(`Failed to upload match data: {err}`)
				else
					print("CloudLoggingAddon: Match data uploaded successfully.")
				end
			end

			for _, connection in pairs(sessionConnections) do
				connection:Disconnect()
			end
		end)
	end)
end

return CloudLoggingAddon
