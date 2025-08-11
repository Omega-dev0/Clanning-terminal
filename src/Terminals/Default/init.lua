local metadata = {
	name = "Default Terminal",
	description = "The default terminal for hardpoint, dualcap and rollback",
	version = "v1.1",
	author = "Omega77073",
	compatibility = ">=1.2.0",
}

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

	assert(
		configInstance["Terminal volume"].Value,
		"[TERMINAL] Terminal volume is not set ! Set the value in Terminal > Configuration > Terminal volume"
	)
	if defaultConfigInstance:GetAttribute("capture_time") > 15 then
		warn(
			"[TERMINAL] Terminal capture time is very high, it takes "
				.. defaultConfigInstance:GetAttribute("capture_time")
				.. " seconds to capture the terminal, is this intended?"
		)
	end

	return {
		zone = basicZones.fromPart(configInstance["Terminal volume"].Value),

		captureTime = defaultConfigInstance:GetAttribute("capture_time"),
		maxPoints = defaultConfigInstance:GetAttribute("max_points"),
		pointsPerSecond = defaultConfigInstance:GetAttribute("points_per_second"),
		rollbackRate = defaultConfigInstance:GetAttribute("rollback_rate"),

		uncaptureIfEmpty = defaultConfigInstance:GetAttribute("uncapture_if_empty"),
	}
end

------ CONTROLS ---------

function terminalFunctions:Lock()
	self.state = "locked"
	self.events.stateChanged:Fire(self.state)
end

function terminalFunctions:Unlock()
	self.state = "neutral"
	self.events.stateChanged:Fire(self.state)
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
end

function terminalFunctions:Reset()
	self.attackerPoints = 0
	self.defenderPoints = 0
	self.captureProgress = 0
	self.events.pointsChanged:Fire(self.attackerPoints, self.defenderPoints)
	self.state = "locked"
	self.events.stateChanged:Fire(self.state)
end

function terminalFunctions:UpdateConfig(newConfig, player: Player?)
	for key, value in pairs(newConfig) do
		if self.config[key] ~= nil then
			if self.config[key] ~= value then
				self.logEvent:Fire(
					`Updated terminal config {key} ({self.config[key]} -> {newConfig[key]})`,
					player.UserId
				)
				self.config[key] = newConfig[key]
			end
		else
			warn("Unknown config key: " .. tostring(key))
		end
	end
	self:updatePersistantConfig()
end

-------- TERMINAL ------

function terminalFunctions:_tickPoints(tickRate: number)
	local newPoints = self.components.updatePoints(self, tickRate)
	if newPoints.attackerPoints ~= self.attackerPoints or newPoints.defenderPoints ~= self.defenderPoints then
		self.events.pointsChanged:Fire(newPoints.attackerPoints, newPoints.defenderPoints)
	end

	self.attackerPoints = newPoints.attackerPoints
	self.defenderPoints = newPoints.defenderPoints
end
function terminalFunctions:_computeState()
	local newState = self.components.computeState(self)
	if newState ~= self.state then
		self.state = newState
		self.events.stateChanged:Fire(self.state)
	end
end
function terminalFunctions:_updatePlayerCount(tickRate: number)
	local newPlayerCount = self.components.getPlayerCount(self, tickRate)
	if newPlayerCount.attackersCount ~= self.attackersCount or newPlayerCount.defendersCount ~= self.defendersCount then
		self.events.playerCountChanged:Fire(newPlayerCount.attackersCount, newPlayerCount.defendersCount)
	end
	self.attackersCount = newPlayerCount.attackersCount
	self.defendersCount = newPlayerCount.defendersCount
end
function terminalFunctions:_updateCaptureProgress(tickRate: number)
	local newCaptureProgress = self.components.updateCaptureProgress(self, tickRate)
	if newCaptureProgress ~= self.captureProgress then
		self.lastCaptureProgress = self.captureProgress
		self.captureProgress = newCaptureProgress
		self.events.captureProgressChanged:Fire(self.captureProgress, self.lastCaptureProgress)
	end
end
function terminalFunctions:_updateWinState()
	local winner = self.components.getWinner(self)
	if winner ~= nil then
		self.events.endEvent:Fire(winner)
		self:Lock()
	end
end

function terminalFunctions:Tick(tickRate: number)
	self:_updatePlayerCount(tickRate)

	if self.state == "locked" then
		return
	end

	self:_updateCaptureProgress(tickRate)
	self:_computeState()

	self:_tickPoints(tickRate)
	self:_updateWinState()
end

function terminalFunctions:updatePersistantConfig()
	self.persistantConfigObject:SetAttribute(
		"terminal_config",
		game:GetService("HttpService"):JSONEncode({
			maxPoints = self.config.maxPoints,
			pointsPerSecond = self.config.pointsPerSecond,
			uncaptureIfEmpty = self.config.uncaptureIfEmpty,
			captureTime = self.config.captureTime,
			rollbackRate = self.config.rollbackRate,
			timeLimit = self.config.timeLimit,
		})
	)
end

return function(wrapper)
	local terminal = setmetatable({}, { __index = terminalFunctions })
	terminal.events = {
		playerCountChanged = newBindableEvent("playerCountChanged"),
		pointsChanged = newBindableEvent("pointsChanged"),
		captureProgressChanged = newBindableEvent("captureProgressChanged"),
		stateChanged = newBindableEvent("stateChanged"),
		endEvent = newBindableEvent("endEvent"),
		startEvent = newBindableEvent("startEvent"),
	}

	terminal.logEvent = wrapper.logEvent

	terminal.timeLeft = math.huge
	terminal.defenderPoints = 0
	terminal.attackerPoints = 0
	terminal.state = "locked"

	terminal.config = fetchConfig()
	terminal.config.attackersTeam = wrapper.config.attackers.team
	terminal.config.defendersTeam = wrapper.config.defenders.team

	terminal.captureProgress = 0
	terminal.lastCaptureProgress = 0
	terminal.attackersCount = 0
	terminal.defendersCount = 0

	terminal.terminalId = "default"
	terminal.persistantConfigObject = wrapper.persistantConfig

	terminal.components = require(script.DefaultComponents)
	terminal:updatePersistantConfig()
	return {
		terminal = terminal,
		metadata = metadata,
		libraries = script.Libraries:GetChildren(),
	}
end
