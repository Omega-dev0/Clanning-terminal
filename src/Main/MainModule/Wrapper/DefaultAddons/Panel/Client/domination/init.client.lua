local terminalId = script:GetAttribute("terminalId")
local httpService = game:GetService("HttpService")
local config = game.ReplicatedStorage:WaitForChild("OmegasTerminalConfig_Persistant") :: Configuration
local packets = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("OmegasTerminalPackets"))
local Icon = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Icon"))
local runService = game:GetService("RunService")

local gui = script:FindFirstChildOfClass("ScreenGui")
gui.Enabled = false
gui.Parent = game.Players.LocalPlayer.PlayerGui

type panelController = {

	events: {
		saveConfig: BindableEvent, --  new Config
		freezeTime: BindableEvent,
		unfreezeTime: BindableEvent,
		addTime: BindableEvent, -- seconds
		removeTime: BindableEvent, -- seconds

		removeProgress: BindableEvent, -- team, %
		addProgress: BindableEvent, -- team, %

		lock: BindableEvent,
		unlock: BindableEvent,

		start: BindableEvent,
		stop: BindableEvent,
		reset: BindableEvent,

		close: BindableEvent,
	},

	open: () -> (),
	close: () -> (),

	updateTime: () -> (),
	updateConfig: (config: any) -> (),
}
local controller = require(gui.Controller) :: panelController

local icon
local function createIcon()
	if icon ~= nil then
		return
	end
	icon = Icon.new()
	icon:setImage("rbxassetid://115700460128166")
	icon:setImageScale(0.7)
	icon:align("Left")
	icon:setCaption("Omega's Terminal Manager")
	icon:setOrder(10)
	icon.toggled:Connect(function(isSelected)
		if isSelected then
			controller:open()
		else
			controller:close()
		end
	end)
end
packets.requestUI.send()
packets.requestUI.listen(function(isAdmin)
	if isAdmin then
		createIcon()
		icon:unlock()
	else
		icon:deselect()
		icon:lock()
		icon:destroy()
		icon = nil
	end
end)
local cfg
local function updateConfig()
	cfg = {
		core = httpService:JSONDecode(config:GetAttribute("core_config")),
		terminal = httpService:JSONDecode(config:GetAttribute("terminal_config")),
	}
	controller:updateConfig(cfg)
end
config.AttributeChanged:Connect(updateConfig)

local s = 0
game:GetService("RunService").Heartbeat:Connect(function(dt)
	s += dt
	if s > 1 / 10 then
		s = 0
		if gui.Enabled == true and cfg.core.timeFrozen == false then
			controller:updateTime()
		end
	end
end)

controller.events.lock.Event:Connect(function()
	packets.action.send({
		action = "control_lockTerminal",
		data = nil,
	})
end)
controller.events.unlock.Event:Connect(function()
	packets.action.send({
		action = "control_unlockTerminal",
		data = nil,
	})
end)
controller.events.addTime.Event:Connect(function(amount)
	packets.action.send({
		action = "control_addTime",
		data = { amount },
	})
end)
controller.events.removeTime.Event:Connect(function(amount)
	packets.action.send({
		action = "control_removeTime",
		data = { amount },
	})
end)
controller.events.freezeTime.Event:Connect(function()
	packets.action.send({
		action = "control_freezeTime",
		data = nil,
	})
end)
controller.events.unfreezeTime.Event:Connect(function()
	packets.action.send({
		action = "control_unfreezeTime",
		data = nil,
	})
end)
controller.events.addProgress.Event:Connect(function(team, progress)
	packets.action.send({
		action = "control_addProgress",
		data = { team, progress },
	})
end)
controller.events.removeProgress.Event:Connect(function(team, progress)
	packets.action.send({
		action = "control_removeProgress",
		data = { team, progress },
	})
end)
controller.events.reset.Event:Connect(function()
	packets.action.send({
		action = "control_reset",
		data = nil,
	})
end)
controller.events.stop.Event:Connect(function()
	packets.action.send({
		action = "control_stop",
		data = nil,
	})
end)
controller.events.start.Event:Connect(function()
	packets.action.send({
		action = "control_start",
		data = nil,
	})
	controller:close()
end)
controller.events.saveConfig.Event:Connect(function(newConfig)
	packets.action.send({
		action = "modifyConfig",
		data = newConfig,
	})
end)

controller.events.close.Event:Connect(function()
	icon:deselect()
end)

updateConfig()
