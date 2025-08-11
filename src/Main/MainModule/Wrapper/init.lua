--[[
   ____                            ______ ______ ___ ______ ____
  / __ \                          |____  |____  / _ \____  |___ \
 | |  | |_ __ ___   ___  __ _  __ _   / /    / / | | |  / /  __) |
 | |  | | '_ ` _ \ / _ \/ _` |/ _` | / /    / /| | | | / /  |__ <
 | |__| | | | | | |  __/ (_| | (_| |/ /    / / | |_| |/ /   ___) |
  \____/|_| |_| |_|\___|\__, |\__,_/_/    /_/   \___//_/   |____/
                         __/ |
                        |___/
Made by Omega77073, 2025
Check out the documentation at terminal-doc.omegadev.xyz
Check out the website for results at terminal.omegadev.xyz
--]]
local httpService = game:GetService("HttpService")
local runService = game:GetService("RunService")
local groupService = game:GetService("GroupService")
-------------- TYPES -----------------
type terminal = {

	components: { [string]: any },

	events: {
		playerCountChanged: BindableEvent,
		pointsChanged: BindableEvent,
		captureProgressChanged: BindableEvent,
		stateChanged: BindableEvent,
		endEvent: BindableEvent,
		startEvent: BindableEvent,
	},

	timeLeft: number,
	defenderPoints: number,
	attackerPoints: number,
	state: "attackers" | "defenders" | "neutral" | "locked",

	captureProgress: number?,
	attackersCount: number?,
	defendersCount: number?,

	Lock: () -> nil,
	Unlock: () -> nil,
	AddProgress: (team: "attackers" | "defenders", progress: number) -> nil,
	Reset: () -> nil,
	Tick: (tickRate: number) -> nil,

	UpdateConfig: (newConfig: any) -> nil,

	terminalId: string,
}

type addon = {
	metadata: { [string]: any }?,
	init: (any) -> nil,
	Libraries: { Instance }?,
	id: string?,
}

local Libraries
if game.ReplicatedStorage:FindFirstChild("Libraries") ~= nil then
	Libraries = script:FindFirstChild("Libraries")
	if Libraries ~= nil then
		for _, lib in pairs(Libraries:GetChildren()) do
			if lib:IsA("ModuleScript") and game.ReplicatedStorage.Libraries:FindFirstChild(lib.Name) == nil then
				lib.Parent = game.ReplicatedStorage.Libraries
			end
		end
	end
	Libraries = game.ReplicatedStorage:FindFirstChild("Libraries")
else
	Libraries = script:FindFirstChild("Libraries")
	if Libraries ~= nil then
		Libraries.Parent = game.ReplicatedStorage
	end
end

local configModule = script.Parent.Parent.Config
local config = require(configModule)
configModule.Name = "OmegasTerminalConfig"
configModule.Parent = game.ReplicatedStorage

local module = {}
module.controls = {}
local packets = require(Libraries:FindFirstChild("OmegasTerminalPackets"))
module.defaultAddons = script.DefaultAddons

function module.updatePersistantConfig()
	module.persistantConfig:SetAttribute(
		"core_config",
		httpService:JSONEncode({
			timeLimit = module.config.timeLimit,

			attackers = {
				groupId = module.config.attackers.groupId,
				icon = module.config.attackers.icon,
				name = module.config.attackers.name,
			},

			defenders = {
				groupId = module.config.defenders.groupId,
				icon = module.config.defenders.icon,
				name = module.config.defenders.name,
			},

			endTime = module.endTime,
			timeFrozen = module.timeFrozen,
			started = module.started,
			startTime = module.startTime,
		})
	)
end

function checkConfig(cfg)
	assert(cfg.attackers.team ~= nil, "[TERMINAL] Attackers team is not set")
	assert(cfg.defenders.team ~= nil, "[TERMINAL] Defenders team is not set")

	if cfg.attackers.groupId == "" and (cfg.attackers.icon == "" or cfg.attackers.name == "") then
		warn("[TERMINAL] Attackers groupId is empty but attackers are missing a name/icon, you may want to set one")
	end
	if cfg.defenders.groupId == "" and (cfg.defenders.icon == "" or cfg.defenders.name == "") then
		warn("[TERMINAL] Defenders groupId is empty but defenders are missing a name/icon, you may want to set one")
	end

	if cfg.telemetry == false then
		warn("[TERMINAL] Telemetry is disabled, please consider enabling to help development.")
	end

	if cfg.terminalTickRate > 30 then
		warn("[TERMINAL] Terminal tick rate is set above 30Hz, this may impact performance.")
	end

	if cfg.timeLimit < 5 then
		warn("[TERMINAL] Terminal time limit is set below 5 minutes, is this intended?")
	end
end

function module.Init()
	module.config = config
	checkConfig(module.config)

	module.terminal = nil
	module.terminalConnections = {}
	module.terminalMetadata = {}

	module.addons = {}
	module.properties = {} -- space used by addons

	module.endTime = 0
	module.startTime = 0
	module.started = false
	module.timeFrozen = false

	module.tickCallbacks = {}

	local persistantConfigInstance = Instance.new("Configuration")
	persistantConfigInstance.Name = "OmegasTerminalConfig_Persistant"
	module.persistantConfig = persistantConfigInstance
	persistantConfigInstance.Parent = game.ReplicatedStorage
	module.updatePersistantConfig()

	packets.requestUI.listen(function(data, player)
		local isAdmin = module.config.isAdmin(player)
		packets.requestUI.sendTo(isAdmin, player)
	end)

	local logEvent = Instance.new("BindableEvent")
	logEvent.Name = "Terminal-LogEvent"
	module.logEvent = logEvent
	logEvent.Parent = game.ReplicatedStorage

	module.initiated = true

	task.spawn(function()
		while shared._K_INTERFACE == nil do
			task.wait(1)
		end
		local _K = shared._K_INTERFACE

		module.logEvent.Event:Connect(function(message, UserId)
			_K.log(`[TERMINAL] - {message}`, "COMMAND", UserId)
		end)

		while task.wait(5) do
			for _, player in pairs(game.Players:GetPlayers()) do
				if module.config.isAdmin(player) then
					packets.requestUI.sendTo(true, player)
				else
					packets.requestUI.sendTo(false, player)
				end
			end
		end
	end)

	task.spawn(function()
		if module.config.attackers.groupId ~= "" then
			if module.config.attackers.icon == "" or module.config.attackers.name == "" then
				local groupInfo = groupService:GetGroupInfoAsync(module.config.attackers.groupId)
				module.config.attackers.icon = module.config.attackers.icon == "" and groupInfo.EmblemUrl
					or module.config.attackers.icon
				module.config.attackers.name = module.config.attackers.name == "" and groupInfo.Name
					or module.config.attackers.name
			end

			if module.config.defenders.groupId ~= "" then
				if module.config.defenders.icon == "" or module.config.defenders.name == "" then
					local groupInfo = groupService:GetGroupInfoAsync(module.config.defenders.groupId)
					module.config.defenders.icon = module.config.defenders.icon == "" and groupInfo.EmblemUrl
						or module.config.defenders.icon
					module.config.defenders.name = module.config.defenders.name == "" and groupInfo.Name
						or module.config.defenders.name
				end
			end
		end
	end)

	task.spawn(require(script.telemetry), script:GetAttribute("version"), module)

	workspace:SetAttribute("GameName", "Unknown game")
	task.spawn(function()
		pcall(function()
			workspace:SetAttribute("GameName", game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
		end)
	end)
end

--- Controls ---

function module.controls:modifyConfig(player: Player, newConfig: any)
	-- Updating group icon and name
	if newConfig.attackers.groupId ~= module.config.attackers.groupId and newConfig.attackers.groupId ~= "" then
		local groupInfo = groupService:GetGroupInfoAsync(newConfig.attackers.groupId)
		if groupInfo then
			module.config.attackers.name = groupInfo.Name
			module.config.attackers.icon = groupInfo.EmblemUrl
			module.config.attackers.groupId = newConfig.attackers.groupId
		end
	end
	if newConfig.defenders.groupId ~= module.config.defenders.groupId and newConfig.defenders.groupId ~= "" then
		local groupInfo = groupService:GetGroupInfoAsync(newConfig.defenders.groupId)
		if groupInfo then
			module.config.defenders.name = groupInfo.Name
			module.config.defenders.icon = groupInfo.EmblemUrl
			module.config.defenders.groupId = newConfig.defenders.groupId
		end
	end

	if module.started then
		module.endTime = module.startTime + (module.config.timeLimit * 60)
	end

	local remainingKeys = {}
	for key, value in pairs(newConfig) do
		if key == "attackers" or key == "defenders" then
			continue
		end
		if module.config[key] ~= nil then
			if module.config[key] == value then
				continue
			end
			module.logEvent:Fire(`Updated wrapper config {key} ({module.config[key]} -> {value})`, player.UserId)
			module.config[key] = value
		else
			remainingKeys[key] = value
		end
	end

	module.terminal:UpdateConfig(remainingKeys, player)
	module.updatePersistantConfig()
end

function module.controls:FreezeTime(player: Player)
	module.timeFrozen = true
	module.updatePersistantConfig()
	module.logEvent:Fire("Froze time", player.UserId)
end
function module.controls:UnfreezeTime(player: Player)
	module.timeFrozen = false
	module.updatePersistantConfig()
	module.logEvent:Fire("Unfroze time", player.UserId)
end
function module.controls:AddTime(player: Player, seconds: number)
	module.endTime = module.endTime + seconds
	module.updatePersistantConfig()
	module.logEvent:Fire(`{seconds > 0 and "Added" or "Removed"} {seconds} seconds to timer`, player.UserId)
end

function module.controls:AddProgress(player: Player, team: "attackers" | "defenders", progress: number)
	if module.terminal ~= nil then
		module.terminal:AddProgress(team, progress)
		module.logEvent:Fire(`Added {progress}% to {team}`, player.UserId)
	end
end

function module.controls:Lock(player: Player)
	if module.terminal then
		module.terminal:Lock()
		module.logEvent:Fire("Locked terminal", player.UserId)
	end
end
function module.controls:Unlock(player: Player)
	if module.terminal then
		module.terminal:Unlock()
		module.logEvent:Fire("Unlocked terminal", player.UserId)
	end
end
function module.controls:Reset(player: Player)
	if module.terminal then
		module.terminal:Reset()
		module.logEvent:Fire("Reset terminal", player.UserId)
	end
end
function module.controls:Stop(player: Player)
	if module.started == false then
		warn("Terminal is not started, cannot stop it.")
		return
	end
	if module.terminal ~= nil then
		module.terminal:Lock()
		module.terminal.events.endEvent:Fire("draw")
		module.terminal:Reset()
	end
	module.started = false
	module.timeFrozen = false

	module.updatePersistantConfig()
	module.logEvent:Fire("Stopped the terminal", player.UserId)
end
function module.controls:Start(player: Player, immediate: boolean?)
	if module.started == true then
		warn("Terminal is already started.")
		return
	end
	module.started = true
	module.timeFrozen = false
	module.startTime = workspace:GetServerTimeNow()
	module.endTime = module.startTime + (module.config.timeLimit * 60)
	module.updatePersistantConfig()

	if module.terminal ~= nil then
		module.terminal.events.startEvent:Fire()
		if immediate ~= true then
			task.wait(5)
		end
		module.terminal:Unlock()
	else
		warn("Starting but no terminal loaded")
	end
end

--- Management ---
function module:AddAddon(moduleScript: ModuleScript)
	if not module.initiated then
		error("Module not initiated. Call module.Init() first.")
	end
	local m = require(moduleScript) :: addon
	local uniqueId = httpService:GenerateGUID(false)
	local addonId = m.id or uniqueId
	for _, lib in pairs(m.Libraries or {}) do
		if game.ReplicatedStorage:FindFirstChild(lib.Name) == nil then
			lib.Parent = game.ReplicatedStorage.Libraries
		end
	end

	if module.addons[addonId] ~= nil then
		warn(`Duplicate addon id:{addonId}, changing id to {uniqueId}`)
		addonId = uniqueId
	end

	module.addons[addonId] = m.metadata or {}

	m.init(self)

	print(`[TERMINAL] Loaded addon: {m.metadata.name} ({addonId}, {m.metadata.version})`)
end

function module:SwitchTerminalComponent(name: string, newComponent: (any) -> any)
	if not module.initiated then
		error("Module not initiated. Call module.Init() first.")
	end
	if not module.terminal then
		error("Terminal not initialized.")
	end

	if module.terminal.components[name] == nil then
		local availableComponents = table.concat(table.keys(module.terminal.components), ", ")
		error("Terminal component '" .. name .. "' does not exist, available components: " .. availableComponents)
	else
		module.terminal.components[name] = newComponent
	end
end

function module:AddTickCallback(f: () -> nil)
	table.insert(self.tickCallbacks, f)
end

function module:LoadTerminal(moduleScript: ModuleScript)
	local terminalModule = require(moduleScript)
	local data = terminalModule(self)
	local terminal, metadata, libraries = data.terminal, data.metadata, data.libraries
	for _, connection in pairs(module.terminalConnections) do
		connection:Disconnect()
	end
	for _, lib in pairs(libraries) do
		if game.ReplicatedStorage:FindFirstChild(lib.Name) == nil then
			lib.Parent = game.ReplicatedStorage.Libraries
		end
	end
	module.terminalConnections = {}

	table.insert(
		module.terminalConnections,
		terminal.events.playerCountChanged.Event:Connect(function(attackersCount, defendersCount)
			packets.partialStatusUpdate.sendToAll({
				{
					stateKey = "attackersCount",
					stateValue = attackersCount,
				},
				{
					stateKey = "defendersCount",
					stateValue = defendersCount,
				},
			})
		end)
	)
	table.insert(
		module.terminalConnections,
		terminal.events.pointsChanged.Event:Connect(function(attackerPoints, defenderPoints)
			packets.partialStatusUpdate.sendToAll({
				{
					stateKey = "attackerPoints",
					stateValue = attackerPoints,
				},
				{
					stateKey = "defenderPoints",
					stateValue = defenderPoints,
				},
			})
		end)
	)

	table.insert(
		module.terminalConnections,
		terminal.events.captureProgressChanged.Event:Connect(function(captureProgress)
			packets.partialStatusUpdate.sendToAll({
				{
					stateKey = "captureProgress",
					stateValue = captureProgress,
				},
			})
		end)
	)
	table.insert(
		module.terminalConnections,
		terminal.events.stateChanged.Event:Connect(function(state)
			packets.partialStatusUpdate.sendToAll({
				{
					stateKey = "state",
					stateValue = state,
				},
			})
		end)
	)
	table.insert(
		module.terminalConnections,
		terminal.events.endEvent.Event:Connect(function(winner)
			module.timeFrozen = true
			module.started = false
			module.updatePersistantConfig()
			packets.terminalEvent.sendToAll({
				eventName = "end",
				data = winner,
			})
		end)
	)

	table.insert(
		module.terminalConnections,
		terminal.events.startEvent.Event:Connect(function()
			module.timeFrozen = false
			module.updatePersistantConfig()
			packets.terminalEvent.sendToAll({
				eventName = "start",
				data = nil,
			})
		end)
	)

	local s = 0
	table.insert(
		module.terminalConnections,
		runService.Heartbeat:Connect(function(deltaTime)
			s = s + deltaTime
			if s >= 1 / module.config.terminalTickRate then
				s = 0
				task.spawn(function()
					module.terminal.timeLeft = module.endTime - workspace:GetServerTimeNow()
					module.terminal:Tick(module.config.terminalTickRate)
					for _, f in pairs(module.tickCallbacks) do
						pcall(f)
					end
				end)
			end
		end)
	)

	module.terminal = terminal
	module.terminalMetadata = metadata

	print("Loaded terminal:", terminal, metadata)
end

return module
