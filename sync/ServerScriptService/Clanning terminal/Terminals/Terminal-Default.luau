local metadata = {
	name = "Default Terminal",
	description = "The default terminal for hardpoint, dualcap and rollback",
	version = "v2.0",
	author = "Omega77073",
	compatibility = ">=2.0.0",
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
	self.captureProgress = 0
	self.events.pointsChanged:Fire(self.attackerPoints, self.defenderPoints)
	self.state = "locked"
	self.events.stateChanged:Fire(self.state)

	self.events.partialUpdate:Fire({
		{ stateKey = "state", stateValue = self.state },
		{ stateKey = "attackerPoints", stateValue = self.attackerPoints },
		{ stateKey = "defenderPoints", stateValue = self.defenderPoints },
		{ stateKey = "captureProgress", stateValue = self.captureProgress },
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
	local lastState = {
		attackersCount = self.attackersCount,
		defendersCount = self.defendersCount,
		attackerPoints = self.attackerPoints,
		defenderPoints = self.defenderPoints,
		captureProgress = self.captureProgress,
		state = self.state,
	}
	self:_updatePlayerCount(tickRate)

	if self.state == "locked" then
		return
	end

	self:_updateCaptureProgress(tickRate)
	self:_computeState()

	self:_tickPoints(tickRate)
	self:_updateWinState()

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
	self.persistantConfigObject:SetAttribute(
		"terminal_config",
		game:GetService("HttpService"):JSONEncode({
			maxPoints = self.config.maxPoints,
			pointsPerSecond = self.config.pointsPerSecond,
			uncaptureIfEmpty = self.config.uncaptureIfEmpty,
			captureTime = self.config.captureTime,
			rollbackRate = self.config.rollbackRate,
		})
	)
end

--- DEBUG ----
local debugUtils = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("debugUtils"))
local debugInstances = {}
function terminalFunctions:toggleDebug(enabled)
	self.debugEnabled = enabled

	local zone = self.config.zone
	zone:_visualize(enabled)

	if enabled then
		local debugBillboard = debugUtils.createDisplay(zone.CFrame.Position + Vector3.new(0, 5, 0))
		debugInstances["billboard"] = debugBillboard
	else
		if debugInstances["billboard"] then
			debugInstances["billboard"].part:Destroy()
			debugInstances["billboard"] = nil
		end
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
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("Attackers Points: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(string.format("%.2f", self.attackerPoints), Color3.new(0, 1, 0))
	)
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("Defenders Points: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(string.format("%.2f", self.defenderPoints), Color3.new(0, 1, 0))
	)
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("Capture Progress: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(
				string.format("%.2f%%", self.captureProgress * 100),
				Color3.new(0, 0.933333, 1)
			)
	)
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("Attackers in zone: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(tostring(self.attackersCount), Color3.new(0.968627, 0, 1))
	)
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("Defenders in zone: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(tostring(self.defendersCount), Color3.new(0.8, 0, 1))
	)
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("Time Left: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(
				self.timeLeft == math.huge and "∞" or debugUtils.formatTime(self.timeLeft),
				Color3.new(1, 0.843137, 0)
			)
	)
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("Last Update: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(tostring(updateEvents), Color3.new(1, 0.647059, 0))
	)

	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("Tick Rate: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(string.format("%.2f Hz", tickRate), Color3.new(0, 0.850980, 1))
	)
	display.label.Text = table.concat(terminalStateText, "<br/>")
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
		partialUpdate = newBindableEvent("partialUpdate"),
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
