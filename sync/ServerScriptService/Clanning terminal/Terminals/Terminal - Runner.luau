local metadata = {
	name = "The runner terminal",
	description = "Terminal for the runner game mode, original idea by xionke",
	version = "v2.0",
	author = "Omega77073 & xionke",
	compatibility = ">=2.0.0",
}

local basicZones = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("basicZones"))

local terminalFunctions = {}
function newBindableEvent(name: string)
	local event = Instance.new("BindableEvent")
	event.Name = name
	return event
end

function fetchConfig()
	local basicZones = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("basicZones"))
	local configInstance = script.Configuration
	local defaultConfigInstance = configInstance["Default configuration values"]

	local attackersZones = {}
	local defendersZones = {}

	for _, volumeObject in pairs(configInstance.Safezones.Attackers:GetChildren()) do
		if volumeObject:IsA("ObjectValue") and volumeObject.Value then
			table.insert(attackersZones, basicZones.fromPart(volumeObject.Value))
		end
	end
	for _, volumeObject in pairs(configInstance.Safezones.Defenders:GetChildren()) do
		if volumeObject:IsA("ObjectValue") and volumeObject.Value then
			table.insert(defendersZones, basicZones.fromPart(volumeObject.Value))
		end
	end
	assert(
		#attackersZones > 0,
		"No attackers safezones defined, add at least one ObjectValue pointing to a part inside Configuration > Safezones > Attackers"
	)
	assert(
		#defendersZones > 0,
		"No defenders safezones defined, add at least one ObjectValue pointing to a part inside Configuration > Safezones > Defenders"
	)

	local attackerStarts = {}
	for _, startPoint in pairs(configInstance.Starts.Attackers:GetChildren()) do
		if startPoint:IsA("ObjectValue") and startPoint.Value ~= nil then
			table.insert(attackerStarts, startPoint.Value)
		end
	end
	local defenderStarts = {}
	for _, startPoint in pairs(configInstance.Starts.Defenders:GetChildren()) do
		if startPoint:IsA("ObjectValue") and startPoint.Value ~= nil then
			table.insert(defenderStarts, startPoint.Value)
		end
	end

	assert(
		#attackerStarts > 0,
		"No attackers start points defined, add at least one ObjectValue pointing to a part inside Configuration > StartPoints > Attackers"
	)
	assert(
		#defenderStarts > 0,
		"No defenders start points defined, add at least one ObjectValue pointing to a part inside Configuration > StartPoints > Defenders"
	)

	return {
		attackersZones = attackersZones,
		defendersZones = defendersZones,

		maxPoints = defaultConfigInstance:GetAttribute("max_points"),
		leaderKilledPoints = defaultConfigInstance:GetAttribute("leader_killed_points"),
		safezoneReachedPoints = defaultConfigInstance:GetAttribute("safezone_reached_points"),

		leaderSpeedDebuff = defaultConfigInstance:GetAttribute("leader_speed_debuff"),
		hudAlwaysOnTop = defaultConfigInstance:GetAttribute("hud_always_on_top"),
		oldLeaderTimeout = defaultConfigInstance:GetAttribute("old_leader_pickup_timeout"),

		attackerStarts = attackerStarts,
		defenderStarts = defenderStarts,
	}
end

------ CONTROLS ---------

function terminalFunctions:Lock()
	self.state = "locked"
	self.events.stateChanged:Fire(self.state)
	self.events.partialUpdate:Fire({
		{ stateKey = "state", stateValue = self.state },
	})
end

function terminalFunctions:Unlock()
	self.state = "neutral"
	self.events.stateChanged:Fire(self.state)
	self.events.partialUpdate:Fire({
		{ stateKey = "state", stateValue = self.state },
	})
end

function terminalFunctions:AddProgress(team, progress)
	if team == "defenders" then
		self.defenderPoints = self.defenderPoints + progress * self.config.maxPoints
	elseif team == "attackers" then
		self.attackerPoints = self.attackerPoints + progress * self.config.maxPoints
	else
		error("Invalid team: " .. tostring(team))
	end
	self.events.pointsChanged:Fire(self.defenderPoints, self.attackerPoints)
	self.events.partialUpdate:Fire({
		{ stateKey = "attackerPoints", stateValue = self.attackerPoints },
		{ stateKey = "defenderPoints", stateValue = self.defenderPoints },
	})
end

function terminalFunctions:Reset()
	self.attackerPoints = 0
	self.defenderPoints = 0
	self.events.pointsChanged:Fire(self.attackerPoints, self.defenderPoints)
	self.state = "locked"
	self.events.stateChanged:Fire(self.state)
	self.events.partialUpdate:Fire({
		{ stateKey = "state", stateValue = self.state },
		{ stateKey = "attackerPoints", stateValue = self.attackerPoints },
		{ stateKey = "defenderPoints", stateValue = self.defenderPoints },
	})
end

function terminalFunctions:UpdateConfig(newConfig, player: Player?)
	for key, value in pairs(newConfig) do
		if self.config[key] ~= nil then
			if self.config[key] ~= value then
				if player ~= nil then
					self.logEvent:Fire(
						`Updated terminal config {key} ({self.config[key]} -> {newConfig[key]})`,
						player.UserId
					)
				end
				self.config[key] = newConfig[key]
			end
		else
			warn("Unknown config key: " .. tostring(key))
		end
	end
	self:updatePersistantConfig()
end

-------- TERMINAL ------
function terminalFunctions:_updateWinState()
	local winner = self.components.getWinner(self)
	if winner ~= nil then
		self.events.endEvent:Fire(winner)
		self:Lock()
	end
end

function terminalFunctions:_selectLeader(player: Player, team: string)
	local connection = player.Character.Humanoid.Died:Connect(function()
		self.leaders[team].connection:Disconnect()
		self.lastLeaders[team] = self.leaders[team].player
		self.leaders[team] = nil
		self.events.leaderKilled:Fire(team, player)
		if team == "attackers" then
			self.defenderPoints = self.defenderPoints + self.config.leaderKilledPoints
		else
			self.attackerPoints = self.attackerPoints + self.config.leaderKilledPoints
		end
		self.events.pointsChanged:Fire(self.defenderPoints, self.attackerPoints)
		self.events.partialUpdate:Fire({
			{ stateKey = "attackerPoints", stateValue = self.attackerPoints },
			{ stateKey = "defenderPoints", stateValue = self.defenderPoints },
		})
		self:updatePersistantConfig()
	end)

	self.events.leaderSelected:Fire(team, player)

	self.leaders[team] = {
		connection = connection,
		player = player,
		timeSelected = workspace:GetServerTimeNow(),
	}
	self.components.applyDebufs(self, player)
	self.components.applyMarker(self, player)
	self:updatePersistantConfig()
end

function terminalFunctions:_tickCrownZones()
	if self.crowns.attackers ~= nil then
		local playersInZone = self.crowns.attackers:GetPlayersInZone()
		for _, player in pairs(playersInZone) do
			if player.Team == self.config.attackersTeam then
				if self.lastLeaders.attackers and player == self.lastLeaders.attackers.player then
					if
						workspace:GetServerTimeNow() - self.lastLeaders.attackers.timeSelected
						< self.config.oldLeaderTimeout
					then
						continue
					end
				end
				self:_selectLeader(player, "attackers")
				self.crowns.attackers:_visualize(false)
				self.crowns.attackers = nil
				self:updatePersistantConfig()
			end
		end
	end

	if self.crowns.defenders ~= nil then
		local playersInZone = self.crowns.defenders:GetPlayersInZone()
		for _, player in pairs(playersInZone) do
			if player.Team == self.config.defendersTeam then
				if self.lastLeaders.defenders and player == self.lastLeaders.defenders.player then
					if
						workspace:GetServerTimeNow() - self.lastLeaders.defenders.timeSelected
						< self.config.oldLeaderTimeout
					then
						continue
					end
				end
				self:_selectLeader(player, "defenders")
				self.crowns.defenders:_visualize(false)
				self.crowns.defenders = nil
				self:updatePersistantConfig()
			end
		end
	end
end

function terminalFunctions:_tickSafezones()
	for _, zone in pairs(self.config.attackersZones) do
		local playersInZone = zone:GetPlayersInZone()
		for _, player in pairs(playersInZone) do
			if self.leaders.attackers and player == self.leaders.attackers.player then
				self.events.safezoneReached:Fire("attackers", player)
				self.attackerPoints = self.attackerPoints + self.config.safezoneReachedPoints
				self:_safeZoneReached("attackers")
				break
			end
		end
	end

	for _, zone in pairs(self.config.defendersZones) do
		local playersInZone = zone:GetPlayersInZone()
		for _, player in pairs(playersInZone) do
			if self.leaders.defenders and player == self.leaders.defenders.player then
				self.events.safezoneReached:Fire("defenders", player)
				self.defenderPoints = self.defenderPoints + self.config.safezoneReachedPoints
				self:_safeZoneReached("defenders")
				break
			end
		end
	end
end

function terminalFunctions:_safeZoneReached(team: "attackers" | "defenders")
	self.lastLeaders.attackers = self.leaders.attackers
			and {
				player = self.leaders.attackers.player,
				timeSelected = self.leaders.attackers.timeSelected,
			}
		or nil
	self.lastLeaders.defenders = self.leaders.defenders
			and {
				player = self.leaders.defenders.player,
				timeSelected = self.leaders.defenders.timeSelected,
			}
		or nil
	self.leaders.attackers = nil
	self.leaders.defenders = nil
	self.components.safeZoneReached(self, team)
	self:updatePersistantConfig()
end

function terminalFunctions:Tick(tickRate: number)
	local lastState = {
		attackerPoints = self.attackerPoints,
		defenderPoints = self.defenderPoints,
		state = self.state,
	}

	if self.state == "locked" then
		return
	end

	self:_updateWinState()

	if self.leaders.attackers == nil and self.crowns.attackers == nil then
		local start = self.components.selectStart(self, self.config.attackerStarts)
		local crownZone = basicZones.New(start.CFrame, {
			Radius = 5,
			zoneShape = "Ball",
		})
		if self.debugEnabled then
			crownZone:_visualize(true)
		end

		self.crowns.attackers = crownZone
		self:updatePersistantConfig()
	end
	if self.leaders.defenders == nil and self.crowns.defenders == nil then
		local start = self.components.selectStart(self, self.config.defenderStarts)
		local crownZone = basicZones.New(start.CFrame, {
			Radius = 5,
			zoneShape = "Ball",
		})
		if self.debugEnabled then
			crownZone:_visualize(true)
		end

		self.crowns.defenders = crownZone
		self:updatePersistantConfig()
	end

	self:_tickCrownZones()
	self:_tickSafezones()

	local updateObject = {}
	for key, value in pairs(lastState) do
		if self[key] ~= value then
			table.insert(updateObject, {
				stateKey = key,
				stateValue = self[key],
			})
		end
	end

	if #updateObject > 0 then
		self.events.partialUpdate:Fire(updateObject)
	end

	self:_updateDisplay(#updateObject, tickRate)
end

function terminalFunctions:updatePersistantConfig()
	local attackersCrownPosition = self.crowns.attackers ~= nil and self.crowns.attackers.CFrame.Position or nil
	local defendersCrownPosition = self.crowns.defenders ~= nil and self.crowns.defenders.CFrame.Position or nil

	local attackersGoals = {}
	local defendersGoals = {}
	for _, zone in pairs(self.config.attackersZones) do
		table.insert(attackersGoals, `{zone.CFrame.Position.X}/{zone.CFrame.Position.Y}/{zone.CFrame.Position.Z}`)
	end
	for _, zone in pairs(self.config.defendersZones) do
		table.insert(defendersGoals, `{zone.CFrame.Position.X}/{zone.CFrame.Position.Y}/{zone.CFrame.Position.Z}`)
	end
	self.persistantConfigObject:SetAttribute(
		"terminal_config",
		game:GetService("HttpService"):JSONEncode({
			maxPoints = self.config.maxPoints,

			leaderKilledPoints = self.config.leaderKilledPoints,
			safezoneReachedPoints = self.config.safezoneReachedPoints,

			leaderSpeedDebuff = self.config.leaderSpeedDebuff,
			hudAlwaysOnTop = self.config.hudAlwaysOnTop,
			oldLeaderTimeout = self.config.oldLeaderTimeout,

			attackersLeaderUserId = self.leaders.attackers and self.leaders.attackers.player.UserId or nil,
			defendersLeaderUserId = self.leaders.defenders and self.leaders.defenders.player.UserId or nil,

			attackersCrownPosition = self.crowns.attackers ~= nil
					and `{attackersCrownPosition.X}/{attackersCrownPosition.Y}/{attackersCrownPosition.Z}`
				or nil,
			defendersCrownPosition = self.crowns.defenders ~= nil
					and `{defendersCrownPosition.X}/{defendersCrownPosition.Y}/{defendersCrownPosition.Z}`
				or nil,

			attackersGoals = attackersGoals,
			defendersGoals = defendersGoals,
		})
	)
end

--- DEBUG ----
local debugUtils = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("debugUtils"))
local debugInstances = {}
function terminalFunctions:toggleDebug(enabled)
	self.debugEnabled = enabled

	for _, zone in self.config.attackersZones do
		zone:_visualize(enabled)
	end
	for _, zone in self.config.defendersZones do
		zone:_visualize(enabled)
	end
end
function terminalFunctions:_updateDisplay(updateEvents, tickRate)
	local display = debugInstances["billboard"]
	if not display then
		return
	end

	local terminalStateText = {}
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("State: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(tostring(self.state), Color3.new(0, 0.882352, 1))
	)
	display.label.Text = table.concat(terminalStateText, "<br/>")
end

return function(wrapper)
	local terminal = setmetatable({}, { __index = terminalFunctions })
	terminal.events = {
		pointsChanged = newBindableEvent("pointsChanged"),
		leaderKilled = newBindableEvent("leaderKilled"),
		safezoneReached = newBindableEvent("safezoneReached"),
		stateChanged = newBindableEvent("stateChanged"),
		endEvent = newBindableEvent("endEvent"),
		startEvent = newBindableEvent("startEvent"),
		partialUpdate = newBindableEvent("partialUpdate"),
		leaderSelected = newBindableEvent("leaderSelected"),
	}

	terminal.logEvent = wrapper.logEvent

	terminal.timeLeft = math.huge
	terminal.defenderPoints = 0
	terminal.attackerPoints = 0
	terminal.state = "locked"

	terminal.config = fetchConfig()
	terminal.config.attackersTeam = wrapper.config.attackers.team
	terminal.config.defendersTeam = wrapper.config.defenders.team

	terminal.leaders = {
		attackers = nil,
		defenders = nil,
	}
	terminal.lastLeaders = {
		attackers = nil,
		defenders = nil,
	}
	terminal.crowns = {
		attackers = nil,
		defenders = nil,
	}

	terminal.terminalId = "runner"
	terminal.persistantConfigObject = wrapper.persistantConfig

	terminal.components = require(script.DefaultComponents)
	terminal:updatePersistantConfig()
	return {
		terminal = terminal,
		metadata = metadata,
		libraries = script.Libraries:GetChildren(),
	}
end
