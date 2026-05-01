local terminalId = script:GetAttribute("terminalId")
local httpService = game:GetService("HttpService")
local config = game.ReplicatedStorage:WaitForChild("OmegasTerminalConfig_Persistant") :: Configuration
local packets = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("OmegasTerminalPackets"))
local runService = game:GetService("RunService")
local panelCreator = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("PanelCreator"))

local templateSettingsModule = script.Settings:FindFirstChild(terminalId)
assert(templateSettingsModule, `No settings module found for terminal {terminalId}`)
local settingsTemplate = require(templateSettingsModule)()
local panel = panelCreator.new(table.clone(settingsTemplate))
local state = {}
panel:Init()

packets.requestUI.send()
packets.requestUI.listen(function(isAdmin)
	panel:UpdatePermission(isAdmin)
end)
packets.statusUpdate.listen(function(data)
	for key, value in pairs(data) do
		state[key] = value
	end
	panel:UpdateState({
		attackersProgress = state.attackersProgress or 0,
		defendersProgress = state.defendersProgress or 0,

		locked = state.locked or false,
	})
end)
packets.partialStatusUpdate.listen(function(data)
	for _, value in data do
		state[value.stateKey] = value.stateValue
	end
	panel:UpdateState({
		attackersProgress = state.attackersProgress or 0,
		defendersProgress = state.defendersProgress or 0,

		locked = state.state == "locked" or false,
	})
end)
local cfg
local function updateConfig()
	cfg = {
		core = httpService:JSONDecode(config:GetAttribute("core_config")),
		terminal = httpService:JSONDecode(config:GetAttribute("terminal_config")),
		properties = httpService:JSONDecode(config:GetAttribute("properties")),
	}
	local state = {
		--attackersProgress = 0,
		--defendersProgress = 0,

		started = cfg.core.started,
		--timeRemaining = cfg.core.endTime - workspace:GetServerTimeNow(),
		totalTime = cfg.core.timeLimit * 60,
		timeFrozen = cfg.core.timeFrozen,

		--locked = false,

		attackersName = cfg.core.attackers.name,
		defendersName = cfg.core.defenders.name,
		attackersIcon = cfg.core.attackers.icon,
		defendersIcon = cfg.core.defenders.icon,
		attackersGroupId = cfg.core.attackers.groupId,
		defendersGroupId = cfg.core.defenders.groupId,

		serverLocked = cfg.properties.groupLocks.server,
		attackersTeamLocked = cfg.properties.groupLocks.attackers,
		defendersTeamLocked = cfg.properties.groupLocks.defenders,
	}
	panel:UpdateState(state)
end
config.AttributeChanged:Connect(updateConfig)

local s = 0
game:GetService("RunService").Heartbeat:Connect(function(dt)
	s += dt
	if s > 1 / 10 then
		s = 0
		if panel.UI.Enabled == true and cfg.core.timeFrozen == false then
			panel:UpdateState({
				timeRemaining = math.max(0, cfg.core.endTime - workspace:GetServerTimeNow()),
			})
		end
	end
end)

panel.Events.progressLock.Event:Connect(function(locked)
	packets.action.send({
		action = "control_toggleLock",
		data = { locked },
	})
end)

panel.Events.timeChange.Event:Connect(function(amount)
	packets.action.send({
		action = "control_addTime",
		data = { amount },
	})
end)

panel.Events.timeFreeze.Event:Connect(function(frozen)
	packets.action.send({
		action = "control_toggleTimeFreeze",
		data = { frozen },
	})
end)

panel.Events.progressChange.Event:Connect(function(changes)
	packets.action.send({
		action = "control_addProgress",
		data = {
			changes.attackers and changes.attackers / 100 or 0,
			changes.defenders and changes.defenders / 100 or 0,
		},
	})
end)

panel.Events.reset.Event:Connect(function()
	packets.action.send({
		action = "control_reset",
		data = nil,
	})
end)
panel.Events.stop.Event:Connect(function()
	packets.action.send({
		action = "control_stop",
		data = nil,
	})
end)
panel.Events.start.Event:Connect(function()
	packets.action.send({
		action = "control_start",
		data = nil,
	})
	panel.icon:deselect()
end)
panel.Events.settingsChange.Event:Connect(function(settings)
	-- TODO

	local newConfig = {
		core = { -- Invariant data, will always be there
			attackers = {
				name = cfg.core.attackers.name,
				icon = cfg.core.attackers.icon,
				groupId = settings.attackersGroupId.value,
			},
			defenders = {
				name = cfg.core.defenders.name,
				icon = cfg.core.defenders.icon,
				groupId = settings.defendersGroupId.value,
			},
		},

		panel = {
			groupLocks = {
				server = settings.serverLock.value,
				attackers = settings.attackersTeamLock.value,
				defenders = settings.defendersTeamLock.value,
			},
		},
	}

	for key, _ in settingsTemplate do
		if settings[key] ~= nil then
			if key == "timeLimit" then
				newConfig.core.timeLimit = settings.timeLimit.value
			else
				newConfig.terminal = newConfig.terminal or {}
				newConfig.terminal[key] = settings[key].value
			end
		end
	end

	packets.action.send({
		action = "modifyConfig",
		data = newConfig,
	})
end)
panel.Events.detectGroup.Event:Connect(function(team)
	packets.action.send({
		action = "detectGroup",
		data = team,
	})
end)

panel.Events.close.Event:Connect(function()
	-- Closing panel
	panel:Close()
end)

updateConfig()
