local metadata = {
	name = "Domination Terminal",
	description = "Domination terminal",
	version = "v1.0",
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

	local cfg = {
		terminals = {},

		captureTime = defaultConfigInstance:GetAttribute("capture_time"),
		maxPoints = defaultConfigInstance:GetAttribute("max_points"),
		pointsPerSecond = defaultConfigInstance:GetAttribute("points_per_second"),
		rollbackRate = defaultConfigInstance:GetAttribute("rollback_rate"),

		uncaptureIfEmpty = defaultConfigInstance:GetAttribute("uncapture_if_empty"),
	}

	local tcount = 0
	for _, value in pairs(configInstance.Terminals:GetChildren()) do
		tcount += 1
		if value:IsA("ObjectValue") then
			if value.Value == nil then
				warn("[TERMINAL] Terminal " .. value.Name .. " has no value set, skipping.")
				continue
			end
			cfg.terminals[value.Name] = basicZones.fromPart(value.Value)
		end
	end

	assert(
		tcount > 0,
		`[TERMINAL] No terminal volumes found ! Add object values in Configuration > Terminals with the value set as the terminal's volume`
	)

	if defaultConfigInstance:GetAttribute("capture_time") > 15 then
		warn(
			"[TERMINAL] Terminal capture time is very high, it takes "
				.. defaultConfigInstance:GetAttribute("capture_time")
				.. " seconds to capture the terminal, is this intended?"
		)
	end

	return cfg
end

------ CONTROLS ---------

function terminalFunctions:Lock()
	local newStates = {}
	for terminalName, terminal in pairs(self.terminals) do
		terminal.state = "locked"
		newStates[terminalName] = terminal.state
	end
	self.events.stateChanged:Fire(newStates)
	self.events.partialUpdate:Fire({
		{ stateKey = "states", stateValue = newStates },
	})
end

function terminalFunctions:Unlock()
	local newStates = {}
	for terminalName, terminal in pairs(self.terminals) do
		terminal.state = "neutral"
		terminal.captureProgress = 0
		terminal.lastCaptureProgress = 0
		newStates[terminalName] = terminal.state
	end
	self.events.stateChanged:Fire(newStates)
	self.events.partialUpdate:Fire({
		{ stateKey = "states", stateValue = newStates },
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
	local newStates = {}
	for terminalName, _ in pairs(self.terminals) do
		self.terminals[terminalName].captureProgress = 0
		self.terminals[terminalName].lastCaptureProgress = 0
		self.terminals[terminalName].state = "neutral"
		newStates[terminalName] = self.terminals[terminalName].state
	end
	self.events.pointsChanged:Fire(self.attackerPoints, self.defenderPoints)
	self.events.stateChanged:Fire(newStates)

	self.events.partialUpdate:Fire({
		{ stateKey = "states", stateValue = newStates },
		{ stateKey = "attackerPoints", stateValue = self.attackerPoints },
		{ stateKey = "defenderPoints", stateValue = self.defenderPoints },
		{ stateKey = "captureProgress", stateValue = self.captureProgress },
	})
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
	local newStates = {}
	local count = 0
	for terminalName, terminal in pairs(self.terminals) do
		local newState = self.components.computeState(self, terminal)
		if newState ~= terminal.state then
			terminal.state = newState
			newStates[terminalName] = newState
			count += 1
		end
	end
	if count > 0 then
		self.events.stateChanged:Fire(newStates)
	end
	return newStates, count
end
function terminalFunctions:_updatePlayerCount(tickRate: number)
	local newCounts = {}
	local count = 0
	for terminalName, terminal in pairs(self.terminals) do
		local newCount = self.components.getPlayerCount(self, terminal, tickRate)
		if newCount.attackersCount ~= terminal.attackersCount or newCount.defendersCount ~= terminal.defendersCount then
			terminal.attackersCount = newCount.attackersCount
			terminal.defendersCount = newCount.defendersCount
			newCounts[terminalName] = {
				attackersCount = terminal.attackersCount,
				defendersCount = terminal.defendersCount,
			}
			count += 1
		end
	end
	if count > 0 then
		self.events.playerCountChanged:Fire(newCounts)
	end
	return newCounts, count
end
function terminalFunctions:_updateCaptureProgress(tickRate: number)
	local newProgress = {}
	local count = 0
	for terminalName, terminal in pairs(self.terminals) do
		local newCaptureProgress = self.components.updateCaptureProgress(self, terminal, tickRate)
		if newCaptureProgress ~= terminal.captureProgress then
			terminal.lastCaptureProgress = terminal.captureProgress
			terminal.captureProgress = newCaptureProgress
			newProgress[terminalName] = terminal.captureProgress
			count += 1
		end
	end
	if count > 0 then
		self.events.captureProgressChanged:Fire(newProgress)
	end
	return newProgress, count
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
		attackerPoints = self.attackerPoints,
		defenderPoints = self.defenderPoints,
	}
	local newCounts, nci = self:_updatePlayerCount(tickRate)

	if self.state == "locked" then
		return
	end

	local newProgresses, ncp = self:_updateCaptureProgress(tickRate)
	local newStates, ncs = self:_computeState()

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

	if nci > 0 then
		table.insert(updateObject, {
			stateKey = "playerCounts",
			stateValue = newCounts,
		})
	end
	if ncp > 0 then
		table.insert(updateObject, {
			stateKey = "captureProgresses",
			stateValue = newProgresses,
		})
	end
	if ncs > 0 then
		table.insert(updateObject, {
			stateKey = "states",
			stateValue = newStates,
		})
	end

	if #updateObject > 0 then
		self.events.partialUpdate:Fire(updateObject)
	end
end

function terminalFunctions:updatePersistantConfig()
	local terminals = {}
	for terminalName, terminal in pairs(self.terminals) do
		terminals[terminalName] = terminal.index
	end
	self.persistantConfigObject:SetAttribute(
		"terminal_config",
		game:GetService("HttpService"):JSONEncode({
			maxPoints = self.config.maxPoints,
			pointsPerSecond = self.config.pointsPerSecond,
			uncaptureIfEmpty = self.config.uncaptureIfEmpty,
			captureTime = self.config.captureTime,
			rollbackRate = self.config.rollbackRate,
			terminals = terminals,
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
		partialUpdate = newBindableEvent("partialUpdate"),
	}

	terminal.logEvent = wrapper.logEvent

	terminal.timeLeft = math.huge
	terminal.defenderPoints = 0
	terminal.attackerPoints = 0

	terminal.config = fetchConfig()
	terminal.config.attackersTeam = wrapper.config.attackers.team
	terminal.config.defendersTeam = wrapper.config.defenders.team

	terminal.terminals = {}

	local tempTerms = {}
	local keys = {}
	for terminalName, zone in pairs(terminal.config.terminals) do
		tempTerms[terminalName] = {
			captureProgress = 0,
			lastCaptureProgress = 0,
			state = "neutral",
			attackersCount = 0,
			defendersCount = 0,
			name = terminalName,
		}
		table.insert(keys, terminalName)
	end
	table.sort(keys)
	for i, terminalName in pairs(keys) do
		terminal.terminals[terminalName] = tempTerms[terminalName]
		terminal.terminals[terminalName].index = i
	end

	terminal.terminalId = "domination"
	terminal.persistantConfigObject = wrapper.persistantConfig

	terminal.components = require(script.DefaultComponents)
	terminal:updatePersistantConfig()
	return {
		terminal = terminal,
		metadata = metadata,
		libraries = script.Libraries:GetChildren(),
	}
end
