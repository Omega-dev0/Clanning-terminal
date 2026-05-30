local module = {}


local main = script.Parent.Frame
local top,bottom = main.Top, main.Bottom

local httpService = game:GetService("HttpService")
function newBindableEvent(name: string)
	local event = Instance.new("BindableEvent")
	event.Name = name
	return event
end


module.ui = {
	menu = {
		controlsButton = bottom.Frame.Top.Controls,
		settingsButton = bottom.Frame.Top.Settings,
		miscButton = bottom.Frame.Top.Misc
	},

	titleLogo = top.TitleBar.ImageLabel,
	closeButton = top.Close.ImageButton,

	content = {
		controls = bottom.Frame.Bottom.Controls,
		settings = bottom.Frame.Bottom.Settings,
		misc = bottom.Frame.Bottom.Misc,
		start = bottom.Frame.Bottom.Start
	}
}

module.events = {
	saveConfig = newBindableEvent("saveConfig"), --  new Config
	freezeTime = newBindableEvent("freezeTime"),
	unfreezeTime = newBindableEvent("unfreezeTime"),
	addTime = newBindableEvent("addTime"), -- seconds
	removeTime = newBindableEvent("removeTime"), -- seconds

	removeProgress = newBindableEvent("removeProgress"), -- team, %
	addProgress = newBindableEvent("addProgress"),  -- team, %

	lock = newBindableEvent("lock"),
	unlock = newBindableEvent("unlock"),

	start = newBindableEvent("start"),
	stop = newBindableEvent("stop"),
	reset = newBindableEvent("reset"),
	
	close = newBindableEvent("close"),
	detectGroups = newBindableEvent("detectGroups")
}

type config = {
	core : { -- Invariant data, will always be there
		attackers: {
			name : string,
			icon : string,
			groupId: number
		},
		defenders: {
			name : string,
			icon : string,
			groupId: number
		},
		endTime: number,
		started: boolean,
		startTime: number,
		timeLimit :number,
		timeFrozen : boolean
	},
	terminal : { -- Depends on the terminal loaded, this is for the terminal :"default"
		maxPoints : number,
		rollbackRate : number,
		pointsPerSecond : number,
		uncaptureIfEmpty : boolean,
		captureTime : number
	},
	
	panel: {
		groupLocks : {
			server : boolean,
			attackers : boolean,
			defenders : boolean
		}
	}
}

function toggleSwitchButton(switch:TextButton, state:boolean)
	if(state)then
		switch.Text = "TRUE"
		switch.TextColor3 = Color3.new(0, 1, 0)
	else
		switch.Text = "FALSE"
		switch.TextColor3 = Color3.new(1, 0, 0.0156863)
	end
end

function triggerSave()
	module.events.saveConfig:Fire(module.saveSettings())
end

module.ui.content.misc.Top.Left.TextBox.FocusLost:Connect(triggerSave)
module.ui.content.misc.Top.Right.TextBox.FocusLost:Connect(triggerSave)



local areButtonsLocked = {
	serverLock = true,
	attackersLock = true,
	defendersLock = true
}
module.ui.content.misc.Bottom.serverLock.TextButton.Activated:Connect(function()
	if areButtonsLocked.serverLock == true then
		return
	end
	toggleSwitchButton(module.ui.content.misc.Bottom.serverLock.TextButton, module.ui.content.misc.Bottom.serverLock.TextButton.Text ~= "TRUE")
	triggerSave()
end)
module.ui.content.misc.Bottom.attackersLock.TextButton.Activated:Connect(function()
	if areButtonsLocked.attackersLock == true then
		return
	end
	toggleSwitchButton(module.ui.content.misc.Bottom.attackersLock.TextButton, module.ui.content.misc.Bottom.attackersLock.TextButton.Text ~= "TRUE")
	triggerSave()
end)
module.ui.content.misc.Bottom.defendersLock.TextButton.Activated:Connect(function()
	if areButtonsLocked.defendersLock == true then
		return
	end
	toggleSwitchButton(module.ui.content.misc.Bottom.defendersLock.TextButton, module.ui.content.misc.Bottom.defendersLock.TextButton.Text ~= "TRUE")
	triggerSave()
end)


module.ui.content.settings.MaxPoints.TextBox.FocusLost:Connect(triggerSave)
module.ui.content.settings.TimeLimit.TextBox.FocusLost:Connect(triggerSave)
module.ui.content.settings.UncaptureIfTermEmpty.TextButton.Activated:Connect(function()
	toggleSwitchButton(module.ui.content.settings.UncaptureIfTermEmpty.TextButton, module.ui.content.settings.UncaptureIfTermEmpty.TextButton.Text ~= "TRUE")
	triggerSave()
end)
module.ui.content.settings.PointsPerSecond.TextBox.FocusLost:Connect(triggerSave)
module.ui.content.settings.RollbackRate.TextBox.FocusLost:Connect(triggerSave)
module.ui.content.settings.CaptureTime.TextBox.FocusLost:Connect(triggerSave)

module.ui.content.controls.Time.Controls.Unfreeze.Activated:Connect(function()
	module.events.unfreezeTime:Fire()
end)
module.ui.content.controls.Time.Controls.Freeze.Activated:Connect(function()
	module.events.freezeTime:Fire()
end)

module.ui.content.controls.Time.Controls.Plus10.Activated:Connect(function()
	module.events.addTime:Fire(10)
end)
module.ui.content.controls.Time.Controls.Plus30.Activated:Connect(function()
	module.events.addTime:Fire(30)
end)
module.ui.content.controls.Time.Controls.Minus10.Activated:Connect(function()
	module.events.removeTime:Fire(10)
end)
module.ui.content.controls.Time.Controls.Minus30.Activated:Connect(function()
	module.events.removeTime:Fire(30)
end)

module.ui.content.controls.Progress.Controls.Lock.Activated:Connect(function()
	module.events.lock:Fire() 
end)
module.ui.content.controls.Progress.Controls.Unlock.Activated:Connect(function()
	module.events.unlock:Fire() 
end)

module.ui.content.controls.Progress.Controls.AttackersPlus5.Activated:Connect(function()
	module.events.addProgress:Fire("attackers",5/100)
end)
module.ui.content.controls.Progress.Controls.AttackersMinus5.Activated:Connect(function()
	module.events.removeProgress:Fire("attackers",5/100)
end)
module.ui.content.controls.Progress.Controls.DefendersPlus5.Activated:Connect(function()
	module.events.addProgress:Fire("defenders",5/100)
end)
module.ui.content.controls.Progress.Controls.DefendersMinus5.Activated:Connect(function()
	module.events.removeProgress:Fire("defenders",5/100)
end)
module.ui.content.controls.Other.Stop.Activated:Connect(function()
	module.events.stop:Fire()
end)
module.ui.content.controls.Other.Reset.Activated:Connect(function()
	module.events.reset:Fire()
end)
module.ui.content.start.StartButton.Activated:Connect(function()
	module.events.start:Fire()
end)

module.ui.content.misc.Top.Left.Detect.Activated:Connect(function()
	module.events.detectGroups:Fire("attackers")
end)
module.ui.content.misc.Top.Right.Detect.Activated:Connect(function()
	module.events.detectGroups:Fire("defenders")
end)


module.ui.closeButton.Activated:Connect(function()
	module.events.close:Fire()
end)


local currentPage = "start"
function updateVisiblePage()
	for fname,frame in pairs(module.ui.content) do
		if(fname == currentPage)then
			frame.Visible = true
		else
			frame.Visible = false
		end
	end
end



module.ui.menu.miscButton.Activated:Connect(function()
	currentPage = "misc"
	updateVisiblePage()
	module.ui.menu.miscButton.FontFace = Font.new("rbxasset://fonts/families/Zekton.json",Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	module.ui.menu.settingsButton.FontFace = Font.new("rbxasset://fonts/families/Zekton.json",Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	module.ui.menu.controlsButton.FontFace = Font.new("rbxasset://fonts/families/Zekton.json",Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end)
module.ui.menu.settingsButton.Activated:Connect(function()
	currentPage = "settings"
	updateVisiblePage()
	module.ui.menu.miscButton.FontFace = Font.new("rbxasset://fonts/families/Zekton.json",Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	module.ui.menu.settingsButton.FontFace = Font.new("rbxasset://fonts/families/Zekton.json",Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	module.ui.menu.controlsButton.FontFace = Font.new("rbxasset://fonts/families/Zekton.json",Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end)
module.ui.menu.controlsButton.Activated:Connect(function()
	if(module.settings.core.started)then
		currentPage = "controls"
	else
		currentPage = "start"
	end
	updateVisiblePage()
	module.ui.menu.miscButton.FontFace = Font.new("rbxasset://fonts/families/Zekton.json",Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	module.ui.menu.settingsButton.FontFace = Font.new("rbxasset://fonts/families/Zekton.json",Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	module.ui.menu.controlsButton.FontFace = Font.new("rbxasset://fonts/families/Zekton.json",Enum.FontWeight.Bold, Enum.FontStyle.Normal)
end)



function module:updateConfig(config: config)
	module.ui.content.misc.Top.Left.GroupName.Text = config.core.attackers.name
	module.ui.content.misc.Top.Left.ImageLabel.Image = config.core.attackers.icon
	module.ui.content.misc.Top.Left.TextBox.Text = config.core.attackers.groupId
	module.ui.content.misc.Top.Right.GroupName.Text = config.core.defenders.name
	module.ui.content.misc.Top.Right.ImageLabel.Image = config.core.defenders.icon
	module.ui.content.misc.Top.Right.TextBox.Text = config.core.defenders.groupId
	
	areButtonsLocked.attackersLock = config.core.attackers.groupId == nil or  config.core.attackers.groupId == ""
	areButtonsLocked.defendersLock = config.core.defenders.groupId ==  nil or  config.core.defenders.groupId == ""
	if (config.core.defenders.groupId ~= "" and config.core.defenders.groupId ~= nil) or (config.core.attackers.groupId ~= "" and config.core.attackers.groupId ~= nil) then
		areButtonsLocked.serverLock = false
	else
		areButtonsLocked.serverLock = true
	end

	if areButtonsLocked.serverLock == true then
		module.ui.content.misc.Bottom.serverLock.TextButton.TextColor3 = Color3.new(0.313725, 0.313725, 0.313725)
		module.ui.content.misc.Bottom.serverLock.TextButton.Text = "LOCKED"
	else
		toggleSwitchButton(module.ui.content.misc.Bottom.serverLock.TextButton, config.properties.groupLocks.server)
	end
	
	if areButtonsLocked.attackersLock == true  then
		module.ui.content.misc.Bottom.attackersLock.TextButton.TextColor3 = Color3.new(0.313725, 0.313725, 0.313725)
		module.ui.content.misc.Bottom.attackersLock.TextButton.Text = "LOCKED"
	else
		toggleSwitchButton(module.ui.content.misc.Bottom.attackersLock.TextButton, config.properties.groupLocks.attackers)
	end
	
	if areButtonsLocked.defendersLock == true then
		module.ui.content.misc.Bottom.defendersLock.TextButton.TextColor3 = Color3.new(0.313725, 0.313725, 0.313725)
		module.ui.content.misc.Bottom.defendersLock.TextButton.Text = "LOCKED"
	else
		toggleSwitchButton(module.ui.content.misc.Bottom.defendersLock.TextButton, config.properties.groupLocks.defenders)
	end
	

	module.ui.content.settings.MaxPoints.TextBox.Text = config.terminal.maxPoints
	module.ui.content.settings.TimeLimit.TextBox.Text = config.core.timeLimit
	toggleSwitchButton(module.ui.content.settings.UncaptureIfTermEmpty.TextButton, config.terminal.uncaptureIfEmpty)
	module.ui.content.settings.PointsPerSecond.TextBox.Text = config.terminal.pointsPerSecond
	module.ui.content.settings.RollbackRate.TextBox.Text = config.terminal.rollbackRate
	module.ui.content.settings.CaptureTime.TextBox.Text = config.terminal.captureTime
	if(config.core.started and currentPage == "start")then
		currentPage = "controls"
		updateVisiblePage()
	end
	if(config.core.started == false and currentPage == "controls")then
		currentPage = "start"
		updateVisiblePage()
	end
	module.settings = config
end

function module.saveSettings() : settings
	local oldconfig = module.settings :: config
	local config = {
		core = { -- Invariant data, will always be there
			attackers= {
				name = oldconfig.core.attackers.name,
				icon = oldconfig.core.attackers.icon,
				groupId= module.ui.content.misc.Top.Left.TextBox.Text
			},
			defenders= {
				name = oldconfig.core.defenders.name,
				icon = oldconfig.core.defenders.icon,
				groupId= module.ui.content.misc.Top.Right.TextBox.Text
			},
			timeLimit = tonumber(module.ui.content.settings.TimeLimit.TextBox.Text),
		},
		terminal = { -- Depends on the terminal loaded, this is for the terminal :"default"
			maxPoints = tonumber(module.ui.content.settings.MaxPoints.TextBox.Text),
			rollbackRate = tonumber(module.ui.content.settings.RollbackRate.TextBox.Text),
			pointsPerSecond = tonumber(module.ui.content.settings.PointsPerSecond.TextBox.Text),
			uncaptureIfEmpty = module.ui.content.settings.UncaptureIfTermEmpty.TextButton.Text == "TRUE",
			captureTime = tonumber(module.ui.content.settings.CaptureTime.TextBox.Text)
		},

		panel= {
			groupLocks = {
				server = module.ui.content.misc.Bottom.serverLock.TextButton.Text == "TRUE",
				attackers = module.ui.content.misc.Bottom.attackersLock.TextButton.Text == "TRUE",
				defenders = module.ui.content.misc.Bottom.defendersLock.TextButton.Text == "TRUE",
			}
		}
	}
	return config
end

local tweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.2)
local originalMainPosition = main.Position
local openTween = tweenService:Create(main, tweenInfo, {Position = originalMainPosition})
local closeTween =  tweenService:Create(main, tweenInfo, {Position = UDim2.new(originalMainPosition.X.Scale - 1,originalMainPosition.X.Offset,originalMainPosition.Y.Scale,originalMainPosition.Y.Offset)})
function module:open()
	task.spawn(function()
		if(game.Lighting:FindFirstChild("TerminalSystemPanelBlur") == nil)then
			script.TerminalSystemPanelBlur:Clone().Parent = game.Lighting
		end
		script.Parent.Enabled = true
		openTween:Play()
	end)
end

function module:close()
	task.spawn(function()
		if(game.Lighting:FindFirstChild("TerminalSystemPanelBlur") ~= nil)then
			game.Lighting:FindFirstChild("TerminalSystemPanelBlur"):Destroy()
		end
		closeTween:Play()
		task.wait(0.2)
		script.Parent.Enabled = false
	end)
end

function module:updateTime()
	local timeLeft = module.settings.core.endTime - workspace:GetServerTimeNow()
	local minutesLeft = timeLeft // 60
	local seconds = timeLeft % 60
	module.ui.content.controls.Time.TimeProgress.Text = `Time left: {minutesLeft}min {math.floor(seconds)}s / {math.floor(module.settings.core.timeLimit)}min`
end





return module
