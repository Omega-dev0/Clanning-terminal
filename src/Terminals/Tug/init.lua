local metadata = {
	name = "Tug Terminal",
	description = "A tug of war terminal",
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
	local configInstance = script.Configuration
	local defaultConfigInstance = configInstance["Default configuration values"]

	local config = {
		axis1 = {
			attackersPoint = configInstance["Axis 1"]["Attackers endpoint"].Value.Position,
			defendersPoint = configInstance["Axis 1"]["Defenders endpoint"].Value.Position,
		},
		axis2 = {
			attackersPoint = configInstance["Axis 2"]["Attackers endpoint"].Value.Position,
			defendersPoint = configInstance["Axis 2"]["Defenders endpoint"].Value.Position,
		},

		maxPoints = defaultConfigInstance:GetAttribute("max_points"),
		progressSpeed = defaultConfigInstance:GetAttribute("progress_speed"),

		additionalPlayerSpeed = defaultConfigInstance:GetAttribute("additional_player_speed"),
		maxAdditionalPlayers = defaultConfigInstance:GetAttribute("max_additional_players"),

		zoneRadius = defaultConfigInstance:GetAttribute("zone_radius"),
		zoneHeight = defaultConfigInstance:GetAttribute("zone_height"),

		defendersAdvantage = defaultConfigInstance:GetAttribute("defenders_advantage"),

		axisConfig = defaultConfigInstance:GetAttribute("axis_config"), -- "axis1, axis2, axis1+2"
	}

	config.axis1.midPoint = (config.axis1.attackersPoint + config.axis1.defendersPoint) / 2
	config.axis2.midPoint = (config.axis2.attackersPoint + config.axis2.defendersPoint) / 2
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
		newStates[terminalName] = terminal.state
	end
	self.events.stateChanged:Fire(newStates)
	self.events.partialUpdate:Fire({
		{ stateKey = "states", stateValue = newStates },
	})
end

function terminalFunctions:AddProgress(team, progress)
	local newProgresses = {}
	if team == "defenders" then
		for terminalName, terminal in pairs(self.terminals) do
			terminal.progress = math.clamp(terminal.progress - progress * 1, -1, 1)
			newProgresses[terminalName] = terminal.progress
		end
	elseif team == "attackers" then
		for terminalName, terminal in pairs(self.terminals) do
			terminal.progress = math.clamp(terminal.progress + progress * 1, -1, 1)
			newProgresses[terminalName] = terminal.progress
		end
	else
		error("Invalid team: " .. tostring(team))
	end
	self.events.progressChanged:Fire(newProgresses)
	self.events.partialUpdate:Fire({
		{ stateKey = "captureProgress", stateValue = newProgresses },
	})
end

function terminalFunctions:Reset()
	self.attackerPoints = 0
	self.defenderPoints = 0

	local newProgress = {}
	local newStates = {}
	for terminalName, terminal in pairs(self.terminals) do
		terminal.progress = 0
		terminal.lastProgress = 0
		terminal.state = "neutral"

		newProgress[terminalName] = terminal.progress
		newStates[terminalName] = terminal.state
	end

	self.events.pointsChanged:Fire(self.attackerPoints, self.defenderPoints)
	self.events.stateChanged:Fire(newStates)
	self.events.progressChanged:Fire(newProgress)

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

function terminalFunctions:_updateRequiredProgress()
	local requiredProgress = self.components.getRequiredProgress(self)
	if requiredProgress ~= self.requiredProgress then
		self.requiredProgress = requiredProgress
	end
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

function terminalFunctions:_updateProgress(tickRate: number)
	local newProgress = {}
	local count = 0
	for terminalName, terminal in pairs(self.terminals) do
		local progress = self.components.updateProgress(self, terminal, tickRate)
		if progress ~= terminal.progress then
			terminal.progress = progress
			newProgress[terminalName] = progress
			count += 1
		end
	end
	if count > 0 then
		self.events.progressChanged:Fire(newProgress)
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
		attackersPoint = self.attackerPoints,
		defendersPoint = self.defenderPoints,
	}
	local newCounts, nci = self:_updatePlayerCount(tickRate)
	local newStates, ncs = self:_computeState()
	if self.state == "locked" then
		return
	end

	local newProgresses, ncp = self:_updateProgress(tickRate)
	self:_updateRequiredProgress()

	for terminalName, terminal in pairs(self.terminals) do
		if math.abs(terminal.progress) > self.requiredProgress then
			self.components.reachFinish(self, terminal, terminal.progress > 0 and "attackers" or "defenders")
		end
	end

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
			stateKey = "Progresses",
			stateValue = newProgresses,
		})
	end
	if ncs > 0 then
		table.insert(updateObject, {
			stateKey = "states",
			stateValue = newStates,
		})
	end
end

function terminalFunctions:updatePersistantConfig()
	self.persistantConfigObject:SetAttribute("terminal_config", game:GetService("HttpService"):JSONEncode({}))
end

return function(wrapper)
	local terminal = setmetatable({}, { __index = terminalFunctions })
	terminal.events = {

		pointsChanged = newBindableEvent("pointsChanged"),

		progressChanged = newBindableEvent("progressChanged"),
		playerCountChanged = newBindableEvent("playerCountChanged"),
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

	terminal.terminalId = "tug"
	terminal.persistantConfigObject = wrapper.persistantConfig

	terminal.requiredProgress = 1

	terminal.components = require(script.DefaultComponents)

	local basicZones = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("basicZones"))
	terminal.terminals = {
		axis1 = {
			zone = basicZones.New(CFrame.new(terminal.config.axis1.midPoint), {
				zoneShape = "Cylinder",
				Radius = terminal.config.zoneRadius,
				maxHeight = terminal.config.zoneHeight,
			}),
			progress = 0, -- [-1,1]
			lastProgress = 0,
			attackersCount = 0,
			defendersCount = 0,
			state = "neutral", -- "neutral", "locked", "attackers", "defenders"
		},
		axis2 = {
			zone = basicZones.New(CFrame.new(terminal.config.axis2.midPoint), {
				zoneShape = "Cylinder",
				Radius = terminal.config.zoneRadius,
				maxHeight = terminal.config.zoneHeight,
			}),
			progress = 0, -- [-1,1]
			lastProgress = 0,
			attackersCount = 0,
			defendersCount = 0,
			state = "neutral", -- "neutral", "locked", "attackers", "defenders"
		},
	}

	terminal:updatePersistantConfig()
	return {
		terminal = terminal,
		metadata = metadata,
		libraries = script.Libraries:GetChildren(),
	}
end
