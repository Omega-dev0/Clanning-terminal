local metadata = {
	name = "CTF Terminal",
	description = "CTF terminal",
	version = "v2.0",
	author = "Omega77073",
	compatibility = ">=2.0.1",
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
		newFlagZones = {},
		flagReturnZones = {},
	}

	-- Checks
	return cfg
end

------ CONTROLS ---------

function terminalFunctions:Lock()
	local newStates = {}

	self.events.stateChanged:Fire(newStates)
	self.events.partialUpdate:Fire({
		{ stateKey = "states", stateValue = newStates },
	})
end

function terminalFunctions:Unlock()
	local newStates = {}

	self.events.stateChanged:Fire(newStates)
	self.events.partialUpdate:Fire({
		{ stateKey = "states", stateValue = newStates },
	})
end

function terminalFunctions:AddProgress(team, progress)
	if team == "defenders" then
	elseif team == "attackers" then
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
	local newStates = {}

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

function terminalFunctions:Tick(tickRate: number)
	local lastState = {}
	local newCounts, nci = self:_updatePlayerCount(tickRate)

	--[[ if self.state == "locked" then
		return
	end ]]
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

	--[[ if #updateObject > 0 then
		self.events.partialUpdate:Fire(updateObject)
	end ]]
end

function terminalFunctions:updatePersistantConfig()
	local terminals = {}
	for terminalName, terminal in pairs(self.terminals) do
		terminals[terminalName] = terminal.index
	end
	self.persistantConfigObject:SetAttribute(
		"terminal_config",
		game:GetService("HttpService"):JSONEncode({
			-- Config data
		})
	)
end

function createNewFlag(flagCfg)
	local flagFunctions = {}
	function flagFunctions:Tick(tickRate: number) end
	function flagFunctions:Destroy() end

	local flag = {}
	flag.zone = flagCfg.zone
	flag.carrierType = nil
	flag.carrier = nil
	flag.createdAt = os.time()
	flag.metadata = {}

	flag.dropped = Instance.new("BindableEvent")
	flag.pickup = Instance.new("BindableEvent")

	return setmetatable(flag, { __index = flagFunctions })
end

return function(wrapper)
	local terminal = setmetatable({}, { __index = terminalFunctions })
	terminal.events = {
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

	terminal.flags = {}
	terminal.zones = {}

	terminal.terminalId = "captureTheFlag"
	terminal.persistantConfigObject = wrapper.persistantConfig

	terminal.components = require(script.DefaultComponents)
	terminal:updatePersistantConfig()
	return {
		terminal = terminal,
		metadata = metadata,
		libraries = script.Libraries:GetChildren(),
	}
end
