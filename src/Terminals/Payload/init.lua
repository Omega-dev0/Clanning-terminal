local metadata = {
	name = "Payload Terminal",
	description = "The default terminal for payload game mode.",
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

	local payloadInstance = configInstance["Payload model"].Value
	assert(
		payloadInstance,
		"[TERMINAL] Payload model is not set ! Set the value in Terminal > Configuration > Payload model"
	)
	assert(payloadInstance:IsA("Model"), "[TERMINAL] Payload model is not a Model ! Please set it to a Model instance.")
	assert(
		payloadInstance.PrimaryPart,
		"[TERMINAL] Payload model has no PrimaryPart ! The primary part should be the capture zone of the payload !"
	)

	local zone = basicZones.fromPart(payloadInstance.PrimaryPart)

	local waypointsFolder = configInstance:FindFirstChild("Waypoints folder")
	assert(
		waypointsFolder and waypointsFolder:IsA("Folder"),
		"[TERMINAL] Waypoints folder is not set or is not a Folder ! Set the value in Terminal > Configuration > Waypoints folder"
	)

	local waypointsInstances = waypointsFolder:GetChildren()
	assert(#waypointsInstances > 0, "[TERMINAL] No waypoints found in the waypoints folder !")

	local waypoints = {}

	for _, waypoint in ipairs(waypointsInstances) do

	return {
		attackersSpeed = defaultConfigInstance:GetAttribute("attackers_speed"),
		defendersSpeed = defaultConfigInstance:GetAttribute("defenders_speed"),
		rollbackCooldown = defaultConfigInstance:GetAttribute("rollback_cooldown"),

		payloadModel = payloadInstance,
		zone = zone,
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

function terminalFunctions:_updateProgress(tickRate: number)
	local newProgress = self.components.updateProgress(self, tickRate)
	if newProgress.progress ~= self.progress then
		self.events.progressChanged:Fire(newProgress.progress)
	end

	self.progress = newProgress.progress
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
function terminalFunctions:_updateWinState()
	local winner = self.components.getWinner(self)
	if winner ~= nil then
		self.events.endEvent:Fire(winner)
		self:Lock()
	end
end
function terminalFunctions:_movePayload()
	self.components.movePayloadModel(self)
	self.zone:UpdateCFrame(self.config.payloadModel.PrimaryPart.CFrame)
end

function terminalFunctions:Tick(tickRate: number)
	local lastState = {
		attackersCount = self.attackersCount,
		defendersCount = self.defendersCount,
		progress = self.progress,
		state = self.state,
	}
	self:_updatePlayerCount(tickRate)

	if self.state == "locked" then
		return
	end

	self:_computeState()
	self:_updateProgress(tickRate)

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
end

function terminalFunctions:updatePersistantConfig()
	self.persistantConfigObject:SetAttribute(
		"terminal_config",
		game:GetService("HttpService"):JSONEncode({
			forwardSpeed = self.config.attackers_speed,
			backwardSpeed = self.config.defenders_speed,
		})
	)
end

return function(wrapper)
	local terminal = setmetatable({}, { __index = terminalFunctions })
	terminal.events = {
		playerCountChanged = newBindableEvent("playerCountChanged"),
		progressChanged = newBindableEvent("progressChanged"),
		stateChanged = newBindableEvent("stateChanged"),
		endEvent = newBindableEvent("endEvent"),
		startEvent = newBindableEvent("startEvent"),
		partialUpdate = newBindableEvent("partialUpdate"),
	}

	terminal.logEvent = wrapper.logEvent

	terminal.timeLeft = math.huge
	terminal.state = "locked"
	terminal.progress = 0

	terminal.config = fetchConfig()
	terminal.config.attackersTeam = wrapper.config.attackers.team
	terminal.config.defendersTeam = wrapper.config.defenders.team

	terminal.attackersCount = 0
	terminal.defendersCount = 0
	terminal.lastMoved = os.clock()

	terminal.terminalId = "payload"
	terminal.persistantConfigObject = wrapper.persistantConfig

	terminal.components = require(script.DefaultComponents)
	terminal:updatePersistantConfig()
	return {
		terminal = terminal,
		metadata = metadata,
		libraries = script.Libraries:GetChildren(),
	}
end
