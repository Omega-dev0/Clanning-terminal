local CloudLoggingAddon = {}
local httpService = game:GetService("HttpService")
local LocalizationService = game:GetService("LocalizationService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local packets = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("OmegasTerminalPackets"))

CloudLoggingAddon.Libraries = script.Libraries:GetChildren()
CloudLoggingAddon.metadata = {
	name = "Cloud Logging",
	description = "The default cloud logging addon",
	version = "v1.3",
	author = "Omega77073",
	compatibility = ">=2.0.0",
}
CloudLoggingAddon.id = "default-cloudLogging"
local locationConnection

CloudLoggingAddon.init = function(wrapper)
	local helper = script:FindFirstChild("clientHelper")
	helper.Name = "CloudLogging client helper"
	helper.Parent = game.StarterPlayer.StarterPlayerScripts

	local configInstance = script.Configuration
	local API_KEY = configInstance:GetAttribute("_API_Key")
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

	local started = false
	wrapper.terminal.events.startEvent.Event:Connect(function()
		started = true
		--New session

		local sessionConnections = {}
		local logs = {}
		local startTime = os.time()

		local leaderboard = {}

		local playtimes = {}
		task.spawn(function()
			while started do
				task.wait(1)
				for _, player in pairs(game.Players:GetPlayers()) do
					if not playtimes[player.UserId] then
						playtimes[player.UserId] = {
							attackers = 0,
							defenders = 0,
						}
					end
					if player.Team == wrapper.config.attackers.team then
						playtimes[player.UserId].attackers = playtimes[player.UserId].attackers + 1
					elseif player.Team == wrapper.config.defenders.team then
						playtimes[player.UserId].defenders = playtimes[player.UserId].defenders + 1
					end
				end
			end
		end)

		-- LOGS --
		table.insert(
			sessionConnections,
			game.ReplicatedStorage:WaitForChild("Terminal-LogEvent").Event:Connect(function(message, UserId)
				table.insert(logs, {
					timestamp = os.time() - startTime,
					username = game.Players:GetNameFromUserIdAsync(UserId),
					content = message,
					type = "info",
				})
			end)
		)

		table.insert(
			sessionConnections,
			game:GetService("LogService").MessageOut:Connect(function(message, messageType)
				local command = message:match("^> (.*)")
				if messageType == Enum.MessageType.MessageOutput and command then
					table.insert(logs, {
						timestamp = os.time() - startTime,
						username = "System",
						content = command,
						type = "command",
					})
				end
			end)
		)

		local _K = shared._K_INTERFACE
		if _K then
			table.insert(
				sessionConnections,
				_K.Hook.runPreparedCommands:Connect(function(from, result, rawText)
					table.insert(logs, {
						timestamp = os.time() - startTime,
						username = game.Players:GetNameFromUserIdAsync(from),
						content = rawText,
						type = "command",
					})
				end)
			)
		end

		local function handlePlayer(player)
			table.insert(logs, {
				timestamp = os.time() - startTime,
				username = player.Name,
				content = `{player.DisplayName} joined the game`,
				type = "info",
			})

			player.Chatted:Connect(function(message)
				table.insert(logs, {
					timestamp = os.time() - startTime,
					username = player.Name,
					content = message,
					type = "chat",
				})
			end)
		end
		table.insert(sessionConnections, game.Players.PlayerAdded:Connect(handlePlayer))
		for _, player in pairs(game.Players:GetPlayers()) do
			handlePlayer(player)
		end

		table.insert(
			sessionConnections,
			game.Players.PlayerRemoving:Connect(function(player)
				table.insert(logs, {
					timestamp = os.time() - startTime,
					username = player.Name,
					content = `{player.DisplayName} left the game`,
					type = "info",
				})

				local leaderstat = {}
				for _, stat in pairs(player:WaitForChild("leaderstats"):GetChildren()) do
					table.insert(leaderstat, {
						name = stat.Name,
						value = stat.Value,
					})
				end
				leaderboard[player.UserId] = {
					username = player.Name,
					userId = player.UserId,
					displayName = player.DisplayName,
					statistics = leaderstat,
				}
			end)
		)

		-- GET MATCH CODE --
		local matchCode = "UNKNOWN"
		local tries = 0
		local function getMatchCode()
			local success, response = pcall(function()
				local response = httpService:GetAsync(SERVER_URL .. "/api/getMatchCode", false, {
					["x-api-key"] = API_KEY,
				})
				return response
			end)
			warn(success, response)
			if success then
				local data = httpService:JSONDecode(response)
				if data.matchCode then
					matchCode = data.matchCode
				end
			else
				if tries >= 5 then
					warn(
						"CloudLoggingAddon: Failed to get match code after multiple attempts. Match will not be logged."
					)
					wrapper.properties.isCloudLoggingEnabled = false
					return
				end
				task.wait(5 + 5 * tries)
				tries = tries + 1
				getMatchCode()
			end
		end

		getMatchCode()
		wrapper.properties.matchCode = matchCode
		wrapper.updatePersistantConfig()

		local function onEnd(winner)
			started = false
			local matchData = {
				attackersId = wrapper.config.attackers.groupId, -- Repalced by attackersLogo at ingest
				attackersName = wrapper.config.attackers.name or "Attackers",
				attackersScore = "NA",

				defendersId = wrapper.config.defenders.groupId, -- Repalced by defendersLogo at ingest
				defendersName = wrapper.config.defenders.name or "Defenders",
				defendersScore = "NA",

				terminalType = wrapper.properties.currentTerminal or "Unknown Terminal",
				terminalVersion = wrapper.VERSION,
				gameName = wrapper.gameName,
				matchTime = os.time(),
				matchStartTime = startTime,
				matchCode = matchCode,
				region = SERVER_LOCATION or "UNKNOWN",

				gameId = game.GameId,
				placeId = game.PlaceId, -- Replaced by game logo by server

				winner = nil,

				accentColor = configInstance:GetAttribute("PrimaryColor"),
				backgroundColor = configInstance:GetAttribute("BackgroundColor"),

				attackersPlayerList = {},
				defendersPlayerList = {},
			}
			-- Snapshot of leaderboard
			for _, player in pairs(game.Players:GetPlayers()) do
				local leaderstat = {}
				if player:FindFirstChild("leaderstats") then
					for _, stat in pairs(player.leaderstats:GetChildren()) do
						table.insert(leaderstat, {
							name = stat.Name,
							value = stat.Value,
						})
					end
				end
				leaderboard[player.UserId] = {
					username = player.Name,
					userId = player.UserId,
					displayName = player.DisplayName,
					statistics = leaderstat,
				}
			end

			matchData.winner = winner
			matchData.telemetryCode = wrapper.properties.telemetryCode
			matchData.logs = logs

			for _, player in pairs(game.Players:GetPlayers()) do
				local playerTeam = nil
				local playtimeData = playtimes[player.UserId] or { attackers = 0, defenders = 0 }
				local totalPlaytime = playtimeData.attackers + playtimeData.defenders
				if totalPlaytime > 10 then
					playerTeam = playtimeData.attackers > playtimeData.defenders and "attackers" or "defenders"
				else
					playerTeam = player.Team == wrapper.config.attackers.team and "attackers"
						or player.Team == wrapper.config.defenders.team and "defenders"
						or "unknown"
				end

				if playerTeam == "attackers" then
					leaderboard[player.UserId].Playtime = string.format("%.2f minutes", playtimeData.attackers / 60)
					table.insert(matchData.attackersPlayerList, leaderboard[player.UserId])
				elseif playerTeam == "defenders" then
					leaderboard[player.UserId].Playtime = string.format("%.2f minutes", playtimeData.defenders / 60)
					table.insert(matchData.defendersPlayerList, leaderboard[player.UserId])
				end
			end

			if wrapper.terminal.attackerPoints ~= nil and wrapper.terminal.defenderPoints ~= nil then
				matchData.attackersScore = wrapper.terminal.attackerPoints
				matchData.defendersScore = wrapper.terminal.defenderPoints
			elseif wrapper.terminal.progress ~= nil then
				matchData.attackersScore = `{math.floor(wrapper.terminal.progress * 100)}%`
				matchData.defendersScore = `{math.floor((1 - wrapper.terminal.progress) * 100)}%`
			end

			matchData.discordWebhookURL = configInstance:GetAttribute("NewMatchWebhookURL")

			for _, connection in pairs(sessionConnections) do
				connection:Disconnect()
			end

			local s, r = pcall(function()
				return httpService:PostAsync(
					SERVER_URL .. "/api/uploadResults",
					httpService:JSONEncode(matchData),
					Enum.HttpContentType.ApplicationJson,
					false,
					{
						["x-api-key"] = API_KEY,
					}
				)
			end)
			if not s then
				warn("CloudLoggingAddon: Failed to upload match results:", r)
				return
			else
				packets.systemChat.sendToAll({
					message = `[TERMINAL] Match results uploaded, match code: {matchCode}`,
					metadata = "",
				})

				wrapper.logEvent:Fire(`Cloud logging: Match results uploaded successfully. Match code: {matchCode}`, 1)
			end
		end

		table.insert(sessionConnections, wrapper.terminal.events.endEvent.Event:Connect(onEnd))
	end)
end

return CloudLoggingAddon
