local HttpService = game:GetService("HttpService")
local metadata = {
	name = "Payload Terminal",
	description = "The default terminal for payload game mode.",
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
	local basicZones = require(script:WaitForChild("Libraries"):WaitForChild("basicZones"))
	local catRom = require(script:WaitForChild("Libraries"):WaitForChild("CatRom"))
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

	local waypointsFolder = configInstance:FindFirstChild("Waypoints folder").Value
	assert(
		waypointsFolder and waypointsFolder:IsA("Folder"),
		"[TERMINAL] Waypoints folder is not set or is not a Folder ! Set the value in Terminal > Configuration > Waypoints folder"
	)

	assert(
		waypointsFolder:FindFirstChild("START"),
		"[TERMINAL] No START waypoint found in the waypoints folder ! There should be a waypoint named 'START' to indicate the starting point of the payload."
	)

	local waypointsInstances = waypointsFolder:GetChildren()
	assert(#waypointsInstances > 0, "[TERMINAL] No waypoints found in the waypoints folder !")

	local waypoints = {}
	local waypointsI = {}
	local function processWaypoint(waypointInstance)
		assert(
			waypointInstance:IsA("BasePart"),
			"[TERMINAL] Waypoint "
				.. waypointInstance.Name
				.. " is not a BasePart ! All waypoints should be BasePart instances."
		)

		if waypointInstance.Name == "END" then
			table.insert(waypoints, waypointInstance.CFrame)
			return
		end

		assert(
			(waypointInstance:FindFirstChild("Next") and waypointInstance.Next:IsA("ObjectValue")),
			"[TERMINAL] Waypoint "
				.. waypointInstance.Name
				.. " has no 'next' attribute ! Each waypoint should have an ObjectValue named 'next' pointing to the next waypoint. If its the last waypoint, name it 'END'."
		)
		table.insert(waypoints, waypointInstance.CFrame)
		table.insert(waypointsI, waypointInstance)
		local nextWaypoint = waypointInstance.Next.Value
		processWaypoint(nextWaypoint)
	end

	processWaypoint(waypointsFolder.START)

	local splineTension = defaultConfigInstance:GetAttribute("spline_tension")
	local splineAlpha = defaultConfigInstance:GetAttribute("spline_alpha")

	local spline = catRom.new(waypoints, splineAlpha, splineTension)
	spline:PrecomputeUnitSpeedData()

	return {
		attackersSpeed = defaultConfigInstance:GetAttribute("attackers_speed"),
		defendersSpeed = defaultConfigInstance:GetAttribute("defenders_speed"),
		rollbackCooldown = tonumber(defaultConfigInstance:GetAttribute("rollback_cooldown")),

		payloadModel = payloadInstance,
		zone = zone,
		spline = spline,
		pathLength = spline:SolveLength(0, 1),
		waypoints = waypoints,
		waypointsInstances = waypointsI,
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
		progress = -progress
	elseif team == "attackers" then
		-- progress is positive
	else
		error("Invalid team: " .. tostring(team))
	end

	self.progress += progress
	if self.progress < 0 then
		self.progress = 0
	end
	if self.progress > 100 then
		self.progress = 100
	end

	self.events.progressChanged:Fire(self.progress)
	self.events.partialUpdate:Fire({
		{ stateKey = "progress", stateValue = self.progress },
	})
	self:_movePayload()
end

function terminalFunctions:Reset()
	self.progress = 0
	self.events.progressChanged:Fire(self.progress)
	self.state = "locked"
	self.events.stateChanged:Fire(self.state)

	self.events.partialUpdate:Fire({
		{ stateKey = "state", stateValue = self.state },
		{ stateKey = "progress", stateValue = self.progress },
	})

	self:_movePayload()
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
	local newCFrame = self.config.spline:SolveCFrameLookAlong(self.progress / 100)
	self.components.movePayloadModel(self, newCFrame)
	self.config.zone:UpdateCFrame(self.config.payloadModel.PrimaryPart.CFrame)

	local lastWaypointIndex = self.currentWaypointIndex
	for i = 1, #self.config.waypoints - 1 do
		local distance = (self.config.payloadModel.PrimaryPart.Position - self.config.waypoints[i].Position).Magnitude
		if distance < 0.5 then
			self.currentWaypointIndex = i
			break
		end
	end

	if self.currentWaypointIndex ~= lastWaypointIndex then
		self:_activateWaypoint()
	end
end

function terminalFunctions:_activateWaypoint()
	self.components.activateWaypoint(self, self.currentWaypointIndex)
	local waypoint = self.config.waypointsInstances[self.currentWaypointIndex]

	if waypoint and waypoint:FindFirstChildOfClass("BindableEvent") then
		waypoint:FindFirstChildOfClass("BindableEvent"):Fire({
			waypointIndex = self.currentWaypointIndex,
			distanceToWaypoint = (self.config.payloadModel.PrimaryPart.Position - waypoint.Position).Magnitude,

			forwardSpeed = self.config.attackersSpeed,
			backwardSpeed = self.config.defendersSpeed,

			progress = self.progress,
			state = self.state,

			timeLeft = self.timeLeft,
		})
	end

	if waypoint and waypoint:FindFirstChild("Instructions") and waypoint.Instructions:IsA("StringValue") then
		local success, err = pcall(function()
			local instructions = HttpService:JSONDecode(waypoint.Instructions.Value)
			for _, instruction in pairs(instructions) do
				local action, value = instruction.action, instruction.value

				--[[
					Supported actions:
					- wait --> v:seconds (number): waits for the specified number of seconds
					- lock --> locks the terminal
					- moveProgress --> value is progress to move (positive or negative)
					- moveDistance --> value is distance in studs to move (positive or negative)
					- moveTime --> value is time in seconds to move forward (only positive)
					- setAsMinimumProgress --> sets the current progress as the minimum progress (prevents rollback beyond this point)
				
					Eg. [{"action":"wait","value":"5"},{"action":"moveDistance","value":40}]
					]]

				if action == "wait" then
					local oldMaximumProgress, oldMinimumProgress =
						self.locks.maximumProgress, self.locks.minimumProgress
					self.locks.maximumProgress = self.progress
					task.spawn(function()
						local waitTime = tonumber(value)
						task.wait(waitTime)
						self.locks.maximumProgress = oldMaximumProgress
						self.locks.minimumProgress = oldMinimumProgress
					end)
				elseif action == "lock" then
					self:Lock()
				elseif action == "moveProgress" then
					local targetProgress = tonumber(value)
					self.locks.targetProgress = self.progress + targetProgress
				elseif action == "moveDistance" then
					local distance = tonumber(value)
					local currentProgress = self.progress
					local targetProgress = currentProgress + (distance / self.config.pathLength) * 100
					self.locks.targetProgress = targetProgress
				elseif action == "moveTime" then
					local t = tonumber(value)
					local currentProgress = self.progress
					local targetProgress = currentProgress
						+ (t * self.config.attackersSpeed / self.config.pathLength) * 100
					self.locks.targetProgress = targetProgress
				elseif action == "setAsMinimumProgress" then
					self.locks.minimumProgress = self.progress
				else
					warn("[TERMINAL] Unknown waypoint instruction action: " .. tostring(action))
				end
			end
		end)

		if not success then
			warn("[TERMINAL] Error processing waypoint instructions: " .. tostring(err))
		end
	end
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
	if self.stopped then
		return
	end
	self:_updateProgress(tickRate)

	if self.progress > lastState.progress then
		self.lastMoved = os.clock()
	end

	self:_movePayload()
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

	self:_updateDisplay(updateObject, tickRate)
end

function terminalFunctions:updatePersistantConfig()
	self.persistantConfigObject:SetAttribute(
		"terminal_config",
		game:GetService("HttpService"):JSONEncode({
			attackersSpeed = self.config.attackersSpeed,
			defendersSpeed = self.config.defendersSpeed,
			rollbackCooldown = self.config.rollbackCooldown,
			pathLength = self.config.pathLength,
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

		if debugInstances.waypoints == nil then
			debugInstances.waypoints = {}
			local lastPart = nil
			for i = 0, 100 do
				local t = i / 100
				local cframe = self.config.spline:SolveCFrameLookAlong(t)
				local waypointPart = Instance.new("Part")
				waypointPart.Name = "Debug Waypoint " .. tostring(t)
				waypointPart.Size = Vector3.new(0.5, 0.5, 0.5)
				waypointPart.Anchored = true
				waypointPart.CanCollide = false
				waypointPart.CFrame = cframe
				waypointPart.Transparency = 0.5
				waypointPart.Material = Enum.Material.Neon
				waypointPart.Color = Color3.fromRGB(255, 0, 0)
				waypointPart.Parent = workspace
				debugInstances.waypoints[i] = waypointPart
				if lastPart then
					local attachment0 = Instance.new("Attachment")
					attachment0.Parent = lastPart
					local attachment1 = Instance.new("Attachment")
					attachment1.Parent = waypointPart
					local beam = Instance.new("Beam")
					beam.Attachment0 = attachment0
					beam.Attachment1 = attachment1
					beam.Parent = lastPart
				end
				lastPart = waypointPart
			end
		end
	else
		if debugInstances["billboard"] then
			debugInstances["billboard"].part:Destroy()
			debugInstances["billboard"] = nil
		end

		if debugInstances.waypoints then
			for _, part in pairs(debugInstances.waypoints) do
				part:Destroy()
			end
			debugInstances.waypoints = nil
		end
	end
end
function terminalFunctions:_updateDisplay(updateEvents, tickRate)
	local display = debugInstances["billboard"]
	if not display then
		return
	end
	display.part.Position = self.config.zone.CFrame.Position + Vector3.new(0, 5, 0)

	local terminalStateText = {}
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("State: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(tostring(self.state), Color3.new(0, 0.882352, 1))
	)
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("Progress: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(string.format("%.2f", self.progress) .. "%", Color3.new(0, 1, 0))
	)

	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("Waypoint: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(
				self.currentWaypointIndex .. "/" .. #self.config.waypoints,
				Color3.new(0.831372, 0, 1)
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
			.. debugUtils.getColorCodedText(tostring(#updateEvents), Color3.new(1, 0.647059, 0))
	)

	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("Tick Rate: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(string.format("%.2f Hz", tickRate), Color3.new(0, 0.850980, 1))
	)

	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("minimumProgress: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(
				string.format("%.2f%%", self.locks.minimumProgress or 0),
				Color3.new(0.066666, 0.015686, 0.776470)
			)
	)
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("maximumProgress: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(
				string.format("%.2f%%", self.locks.maximumProgress or 100),
				Color3.new(0.776470, 0.015686, 0.121568)
			)
	)
	table.insert(
		terminalStateText,
		debugUtils.getColorCodedText("targetProgress: ", Color3.new(1, 1, 1))
			.. debugUtils.getColorCodedText(
				string.format("%.2f%%", self.locks.targetProgress or -1),
				Color3.new(0.121568, 0.776470, 0.015686)
			)
	)
	display.label.Text = table.concat(terminalStateText, "<br/>")
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
	terminal.stopped = false

	terminal.currentWaypointIndex = 1

	terminal.locks = {
		minimumProgress = 0, -- Used to lock the payload from moving backwards past a certain point
		targetProgress = nil, -- If set to a number, the payload will move towards the target progress without being affected by players
		maximumProgress = 100, -- Used to lock the payload from moving forwards past a certain point
	}

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

	terminal:_movePayload()

	return {
		terminal = terminal,
		metadata = metadata,
		libraries = script.Libraries:GetChildren(),
	}
end
