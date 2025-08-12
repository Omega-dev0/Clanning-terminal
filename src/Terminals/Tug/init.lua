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
	local basicZones = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("basicZones"))
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

		axisConfig = defaultConfigInstance:GetAttribute("axis_config"), -- "axis1, axis2, axis1+2"
	}

	config.axis1.midPoint = (config.axis1.attackersPoint + config.axis1.defendersPoint) / 2
	config.axis2.midPoint = (config.axis2.attackersPoint + config.axis2.defendersPoint) / 2
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

function terminalFunctions:AddProgress(team, progress, axisNumber) end

function terminalFunctions:Reset() end

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

function terminalFunctions:Tick(tickRate: number) end

function terminalFunctions:updatePersistantConfig()
	self.persistantConfigObject:SetAttribute(
		"terminal_config",
		game:GetService("HttpService"):JSONEncode({
			maxPoints = self.config.maxPoints,
			progressSpeed = self.config.progressSpeed,
			additionalPlayerSpeed = self.config.additionalPlayerSpeed,
			maxAdditionalPlayers = self.config.maxAdditionalPlayers,
			zoneRadius = self.config.zoneRadius,
			zoneHeight = self.config.zoneHeight,
			axisConfig = self.config.axisConfig,
		})
	)
end

return function(wrapper)
	local terminal = setmetatable({}, { __index = terminalFunctions })
	terminal.events = {

		pointsChanged = newBindableEvent("pointsChanged"),

		axis1 = {
			progressChanged = newBindableEvent("axis1ProgressChanged"),
			playerCountChanged = newBindableEvent("playerCountChanged"),
		},

		axis2 = {
			progressChanged = newBindableEvent("axis2ProgressChanged"),
			playerCountChanged = newBindableEvent("playerCountChanged"),
		},

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
