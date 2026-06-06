local metadata = {
	name = "Tug Terminal",
	description = "A tug of war terminal",
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
	local configInstance = script.Configuration
	local defaultConfigInstance = configInstance["Default configuration values"]
	local basicZone = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("basicZones"))
	assert(configInstance["Axis 1"]["Path"]["Attackers endpoint"].Value, "Axis 1 Attackers endpoint is not set")
	assert(configInstance["Axis 1"]["Path"]["Defenders endpoint"].Value, "Axis 1 Defenders endpoint is not set")
	assert(configInstance["Axis 2"]["Path"]["Attackers endpoint"].Value, "Axis 2 Attackers endpoint is not set")
	assert(configInstance["Axis 2"]["Path"]["Defenders endpoint"].Value, "Axis 2 Defenders endpoint is not set")

	assert(configInstance["Axis 1"]["Zone"].Value, "Axis 1 Zone is not set")
	assert(configInstance["Axis 2"]["Zone"].Value, "Axis 2 Zone is not set")

	local config = {
		axis1 = {
			attackersCFrame = configInstance["Axis 1"]["Path"]["Attackers endpoint"].Value.CFrame,
			defendersCFrame = configInstance["Axis 1"]["Path"]["Defenders endpoint"].Value.CFrame,
			zone = basicZone.fromPart(configInstance["Axis 1"]["Zone"].Value),
		},
		axis2 = {
			attackersCFrame = configInstance["Axis 2"]["Path"]["Attackers endpoint"].Value.CFrame,
			defendersCFrame = configInstance["Axis 2"]["Path"]["Defenders endpoint"].Value.CFrame,
			zone = basicZone.fromPart(configInstance["Axis 2"]["Zone"].Value),
		},

		maxPoints = tonumber(defaultConfigInstance:GetAttribute("max_points")),
		progressSpeed = tonumber(defaultConfigInstance:GetAttribute("progress_speed")) / 100,

		additionalPlayerSpeed = tonumber(defaultConfigInstance:GetAttribute("additional_player_speed")) / 100,
		maxAdditionalPlayers = tonumber(defaultConfigInstance:GetAttribute("max_additional_players")),

		defendersAdvantage = defaultConfigInstance:GetAttribute("defenders_advantage"),

		axisConfig = defaultConfigInstance:GetAttribute("axisConfig"), -- "axis1, axis2, axis1+2"

		lockAfterScoring = defaultConfigInstance:GetAttribute("lock_after_scoring"),
	}

	config.axis1.midCFrame = config.axis1.attackersCFrame:Lerp(config.axis1.defendersCFrame, 0.5)
	config.axis2.midCFrame = config.axis2.attackersCFrame:Lerp(config.axis2.defendersCFrame, 0.5)

	return config
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
		{ stateKey = "Progresses", stateValue = newProgresses },
	})
end

function terminalFunctions:Reset(resetPoints: boolean?)
	if resetPoints == nil then
		resetPoints = true
	end
	if resetPoints ~= false then
		self.attackerPoints = 0
		self.defenderPoints = 0
		self.events.pointsChanged:Fire(self.attackerPoints, self.defenderPoints)
	end

	local newProgress = {}
	local newStates = {}
	for terminalName, terminal in pairs(self.terminals) do
		terminal.progress = 0
		terminal.lastProgress = 0
		terminal.state = "neutral"

		newProgress[terminalName] = terminal.progress
		newStates[terminalName] = terminal.state
	end

	self.events.stateChanged:Fire(newStates)
	self.events.progressChanged:Fire(newProgress)

	self.events.partialUpdate:Fire({
		{ stateKey = "states", stateValue = newStates },
		{ stateKey = "attackerPoints", stateValue = self.attackerPoints },
		{ stateKey = "defenderPoints", stateValue = self.defenderPoints },
		{ stateKey = "Progresses", stateValue = newProgress },
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

function terminalFunctions:_getEnabledSubterminals()
	if self.config.axisConfig == "axis1" then
		return { axis1 = self.terminals.axis1 }
	elseif self.config.axisConfig == "axis2" then
		return { axis2 = self.terminals.axis2 }
	else
		return self.terminals
	end
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
	for terminalName, terminal in pairs(self:_getEnabledSubterminals()) do
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
	for terminalName, terminal in pairs(self:_getEnabledSubterminals()) do
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
function terminalFunctions:_updateZonePosition()
	for terminalName, terminal in pairs(self:_getEnabledSubterminals()) do
		local zoneFrame = self.components.getNewZoneCFrame(self, terminalName)
		terminal.zone.CFrame = zoneFrame
	end
end

function terminalFunctions:Tick(tickRate: number)
	local lastState = {
		attackerPoints = self.attackerPoints,
		defenderPoints = self.defenderPoints,
	}
	local newCounts, nci = self:_updatePlayerCount(tickRate)
	local newStates, ncs = self:_computeState()
	if self.state == "locked" then
		return
	end

	local newProgresses, ncp = self:_updateProgress(tickRate)
	self:_updateRequiredProgress()
	self:_updateZonePosition()

	local updateObject = {}

	for terminalName, terminal in pairs(self:_getEnabledSubterminals()) do
		if math.abs(terminal.progress) >= self.requiredProgress then
			self.components.reachFinish(self, terminal, terminal.progress > 0 and "attackers" or "defenders")
			newProgresses, ncp = self:_updateProgress(tickRate)
			self:_updateZonePosition()
			self.events.progressChanged:Fire({
				axis1 = self.terminals.axis1.progress,
				axis2 = self.terminals.axis2.progress,
			})
			if self.config.lockAfterScoring then
				self:Lock()
				self.wrapper.timeFrozen = true
				self.wrapper.updatePersistantConfig()
			end
			ncs, ncp, nci = 0, 0, 0
			--self.events.partialUpdate:Fire({
			--	{
			--		stateKey = "Progresses",
			--		stateValue = {
			--			axis1 = self.terminals.axis1.progress,
			--			axis2 = self.terminals.axis2.progress,
			--		},
			--	},
			--	{
			--		stateKey = "states",
			--		stateValue = {
			--			axis1 = self.terminals.axis1.state,
			--			axis2 = self.terminals.axis2.state,
			--		},
			--	}
			--})
		end
	end

	self:_updateWinState()

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

	if #updateObject > 0 then
		self.events.partialUpdate:Fire(updateObject)
	end

	if self.attackerPoints ~= lastState.attackerPoints or self.defenderPoints ~= lastState.defenderPoints then
		self.events.pointsChanged:Fire(self.attackerPoints, self.defenderPoints)
	end

	self:_updateDisplay(#updateObject, tickRate)
end

function terminalFunctions:updatePersistantConfig()
	self.persistantConfigObject:SetAttribute(
		"terminal_config",
		game:GetService("HttpService")
			:JSONEncode({ -- Depends on the terminal loaded, this is for the terminal :"default"
				maxPoints = self.config.maxPoints,
				progressSpeed = self.config.progressSpeed,
				additionalPlayerSpeed = self.config.additionalPlayerSpeed,
				maxAdditionalPlayers = self.config.maxAdditionalPlayers,
				defendersAdvantage = self.config.defendersAdvantage,
				axisConfig = self.config.axisConfig,
				lockAfterScoring = self.config.lockAfterScoring,
			})
	)
end

local debugUtils = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("debugUtils"))
local debugInstances = {}
function terminalFunctions:toggleDebug(enabled)
	self.debugEnabled = enabled

	local zone1 = self.config.axis1.zone
	local zone2 = self.config.axis2.zone
	zone1._visualize(enabled)
	zone2._visualize(enabled)

	if enabled then
		local debugBillboard = debugUtils.createDisplay(zone1.CFrame.Position + Vector3.new(0, 5, 0))
		debugInstances["billboard1"] = debugBillboard
		local debugBillboard2 = debugUtils.createDisplay(zone2.CFrame.Position + Vector3.new(0, 5, 0))
		debugInstances["billboard2"] = debugBillboard2
	else
		if debugInstances["billboard1"] then
			debugInstances["billboard1"].part:Destroy()
			debugInstances["billboard1"] = nil
		end
		if debugInstances["billboard2"] then
			debugInstances["billboard2"].part:Destroy()
			debugInstances["billboard2"] = nil
		end
	end
end

function terminalFunctions:_updateDisplay(updateEvents, tickRate)
	local display1 = debugInstances["billboard1"]
	local display2 = debugInstances["billboard2"]
	if not display1 and not display2 then
		return
	end

	local terminalStateText1 = {}
	local terminalStateText2 = {}
	table.insert(
		terminalStateText1,
		debugUtils.getColorCodedText("State: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(tostring(self.axis1.state), Color3.new(0, 0.882352, 1))
	)
	table.insert(
		terminalStateText2,
		debugUtils.getColorCodedText("State: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(tostring(self.axis2.state), Color3.new(0, 0.882352, 1))
	)
	table.insert(
		terminalStateText1,
		debugUtils.getColorCodedText("Attackers Points: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(string.format("%.2f", self.attackerPoints), Color3.new(0, 1, 0))
	)
	table.insert(
		terminalStateText2,
		debugUtils.getColorCodedText("Attackers Points: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(string.format("%.2f", self.attackerPoints), Color3.new(0, 1, 0))
	)
	table.insert(
		terminalStateText1,
		debugUtils.getColorCodedText("Defenders Points: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(string.format("%.2f", self.defenderPoints), Color3.new(0, 1, 0))
	)
	table.insert(
		terminalStateText2,
		debugUtils.getColorCodedText("Defenders Points: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(string.format("%.2f", self.defenderPoints), Color3.new(0, 1, 0))
	)

	table.insert(
		terminalStateText1,
		debugUtils.getColorCodedText("Progress: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(
				string.format("%.2f%%", self.axis1.progress * 100),
				Color3.new(0, 0.933333, 1)
			)
	)
	table.insert(
		terminalStateText2,
		debugUtils.getColorCodedText("Progress: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(
				string.format("%.2f%%", self.axis2.progress * 100),
				Color3.new(0, 0.933333, 1)
			)
	)
	table.insert(
		terminalStateText1,
		debugUtils.getColorCodedText("Attackers in zone: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(tostring(self.axis1.attackersCount), Color3.new(0.968627, 0, 1))
	)
	table.insert(
		terminalStateText1,
		debugUtils.getColorCodedText("Defenders in zone: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(tostring(self.axis1.defendersCount), Color3.new(0.8, 0, 1))
	)

	table.insert(
		terminalStateText2,
		debugUtils.getColorCodedText("Attackers in zone: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(tostring(self.axis2.attackersCount), Color3.new(0.968627, 0, 1))
	)
	table.insert(
		terminalStateText2,
		debugUtils.getColorCodedText("Defenders in zone: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(tostring(self.axis2.defendersCount), Color3.new(0.8, 0, 1))
	)

	table.insert(
		terminalStateText1,
		debugUtils.getColorCodedText("Time Left: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(
				self.timeLeft == math.huge and "∞" or debugUtils.formatTime(self.timeLeft),
				Color3.new(1, 0.843137, 0)
			)
	)
	table.insert(
		terminalStateText2,
		debugUtils.getColorCodedText("Time Left: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(
				self.timeLeft == math.huge and "∞" or debugUtils.formatTime(self.timeLeft),
				Color3.new(1, 0.843137, 0)
			)
	)

	table.insert(
		terminalStateText1,
		debugUtils.getColorCodedText("Tick Rate: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(string.format("%.2f Hz", tickRate), Color3.new(0, 0.850980, 1))
	)
	table.insert(
		terminalStateText2,
		debugUtils.getColorCodedText("Tick Rate: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(string.format("%.2f Hz", tickRate), Color3.new(0, 0.850980, 1))
	)
	display1.label.Text = table.concat(terminalStateText1, "<br/>")
	display2.label.Text = table.concat(terminalStateText2, "<br/>")
end

return function(wrapper)
	local terminal = setmetatable({}, { __index = terminalFunctions })
	terminal.wrapper = wrapper
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
			zone = terminal.config.axis1.zone,
			progress = 0, -- [-1,1]
			lastProgress = 0,
			attackersCount = 0,
			defendersCount = 0,
			state = "neutral", -- "neutral", "locked", "attackers", "defenders"
		},
		axis2 = {
			zone = terminal.config.axis2.zone,
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
