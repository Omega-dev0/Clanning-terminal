local templates = {
	textInput = script.UI.Templates._textSetting,
	boolInput = script.UI.Templates._boolSetting,
}
local reservedSettingsIds = { -- Type will be ignored but the value will be used
	"attackersGroupId",
	"defendersGroupId",
	"attackersTeamLock",
	"defendersTeamLock",
	"serverLock",
}
local panelFunctions = {}

local fillSettings = {
	attackersGroupId = {
		label = "Attackers group ID",
		type = "text",
		value = "",
		validation = function(value)
			return tonumber(value) ~= nil
		end,
	},
	defendersGroupId = {
		label = "Defenders group ID",
		type = "text",
		value = "",
		validation = function(value)
			return tonumber(value) ~= nil
		end,
	},
	attackersTeamLock = {
		label = "Lock attackers to team",
		type = "bool",
		value = false,
	},
	defendersTeamLock = {
		label = "Lock defenders to team",
		type = "bool",
		value = false,
	},
	serverLock = {
		label = "Lock server to match",
		type = "bool",
		value = false,
	},
}

local httpService = game:GetService("HttpService")
local icon = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Icon"))
local TweenService = game:GetService("TweenService")

---- DEFAULTS ----
local defaultSettings = {
	test1 = {
		label = "Test1",
		type = "text", -- text | bool
		value = "3",
	},

	test2 = {
		label = "Test2",
		type = "bool",
		value = true,
	},

	test3 = {
		label = "Test3 - Number validation",
		type = "text",
		value = 1,
		validation = function(value)
			return tonumber(value) ~= nil
		end,
	},
}
local defaultColors = {
	boolEnabled = Color3.fromRGB(0, 255, 0),
	boolDisabled = Color3.fromRGB(255, 0, 0),
	textWhite = Color3.fromRGB(255, 255, 255),
	textDisabled = Color3.fromRGB(150, 150, 150),
}
local defaultIconDetails = {
	image = "rbxassetid://87462366316143",
	imageScale = 0.7,
	align = "Left",
	caption = "Omega's Terminal Manager",
	order = 10,
}
-----

function newBindableEvent(name, parent)
	local event = Instance.new("BindableEvent")
	event.Name = name
	event.Parent = parent
	return event
end

function newPanel(settings, colors, iconDetails)
	if settings == nil then
		settings = defaultSettings
	end
	if colors == nil then
		colors = defaultColors
	end
	-- Merge fillSettings into settings
	for id, setting in pairs(fillSettings) do
		if not settings[id] then
			settings[id] = setting
		end
	end

	local ui = script.UI.Base:Clone()
	local blur = script.UI.Blur:Clone()

	local refs = {}

	refs.main = ui.Frame.Frame
	refs.top = refs.main.Top
	refs.bottom = refs.main.Bottom
	refs.BottomBottom = refs.bottom.Frame.Bottom

	refs.title = refs.top.TitleBar.TextLabel
	refs.closeButton = refs.top.Close.ImageButton

	refs.menu = {
		controls = refs.bottom.Frame.Top.Controls,
		misc = refs.bottom.Frame.Top.Misc,
		settings = refs.bottom.Frame.Top.Settings,
	}

	refs.start = {
		content = refs.BottomBottom.Start,
		startButton = refs.BottomBottom.Start.StartButton,
	}

	refs.settings = {
		content = refs.BottomBottom.Settings,
	}

	refs.misc = {
		content = refs.BottomBottom.Misc,

		attackersLock = {
			content = refs.BottomBottom.Misc.Bottom.attackersLock,
			button = refs.BottomBottom.Misc.Bottom.attackersLock.TextButton,
			label = refs.BottomBottom.Misc.Bottom.attackersLock.TextLabel,
		},
		defendersLock = {
			content = refs.BottomBottom.Misc.Bottom.defendersLock,
			button = refs.BottomBottom.Misc.Bottom.defendersLock.TextButton,
			label = refs.BottomBottom.Misc.Bottom.defendersLock.TextLabel,
		},
		serverLock = {
			content = refs.BottomBottom.Misc.Bottom.serverLock,
			button = refs.BottomBottom.Misc.Bottom.serverLock.TextButton,
			label = refs.BottomBottom.Misc.Bottom.serverLock.TextLabel,
		},

		attackersGroup = {
			content = refs.BottomBottom.Misc.Top.Left,
			label = refs.BottomBottom.Misc.Top.Left.TextLabel,
			icon = refs.BottomBottom.Misc.Top.Left.ImageLabel,
			idTextBox = refs.BottomBottom.Misc.Top.Left.TextBox,
			detectButton = refs.BottomBottom.Misc.Top.Left.Detect,
			groupName = refs.BottomBottom.Misc.Top.Left.GroupName,
		},

		defendersGroup = {
			content = refs.BottomBottom.Misc.Top.Right,
			label = refs.BottomBottom.Misc.Top.Right.TextLabel,
			icon = refs.BottomBottom.Misc.Top.Right.ImageLabel,
			idTextBox = refs.BottomBottom.Misc.Top.Right.TextBox,
			detectButton = refs.BottomBottom.Misc.Top.Right.Detect,
			groupName = refs.BottomBottom.Misc.Top.Right.GroupName,
		},
	}

	refs.controls = {
		content = refs.BottomBottom.Controls,
		resetButton = refs.BottomBottom.Controls.Other.Reset,
		stopButton = refs.BottomBottom.Controls.Other.Stop,

		time = {
			label = {
				time1 = refs.BottomBottom.Controls.Time.Time.Time1,
				time2 = refs.BottomBottom.Controls.Time.Time.Time2,
				separator = refs.BottomBottom.Controls.Time.Time.Separator,
			},

			freezeButton = refs.BottomBottom.Controls.Time.Controls.Freeze,
			minus10Button = refs.BottomBottom.Controls.Time.Controls.Minus10,
			minus30Button = refs.BottomBottom.Controls.Time.Controls.Minus30,
			plus10Button = refs.BottomBottom.Controls.Time.Controls.Plus10,
			plus30Button = refs.BottomBottom.Controls.Time.Controls.Plus30,
			unfreezeButton = refs.BottomBottom.Controls.Time.Controls.Unfreeze,
		},

		progress = {
			label = refs.BottomBottom.Controls.Progress.Header,

			lockButton = refs.BottomBottom.Controls.Progress.Controls.Misc.Lock,
			unlockButton = refs.BottomBottom.Controls.Progress.Controls.Misc.Unlock,

			attackersMinus5Button = refs.BottomBottom.Controls.Progress.Controls.Attackers.AttackersMinus5,
			attackersPlus5Button = refs.BottomBottom.Controls.Progress.Controls.Attackers.AttackersPlus5,

			defendersMinus5Button = refs.BottomBottom.Controls.Progress.Controls.Defenders.DefendersMinus5,
			defendersPlus5Button = refs.BottomBottom.Controls.Progress.Controls.Defenders.DefendersPlus5,
		},
	}

	local eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "Events"
	eventsFolder.Parent = ui

	local events = {
		close = newBindableEvent("Close", eventsFolder),
		start = newBindableEvent("Start", eventsFolder),

		reset = newBindableEvent("Reset", eventsFolder),
		stop = newBindableEvent("Stop", eventsFolder),

		timeFreeze = newBindableEvent("TimeFreeze", eventsFolder), -- True/False
		timeChange = newBindableEvent("TimeChange", eventsFolder), -- Number (positive or negative)

		progressLock = newBindableEvent("ProgressLock", eventsFolder), -- True/False
		progressChange = newBindableEvent("ProgressChange", eventsFolder), -- Table { attackers = Number, defenders = Number }

		settingsChange = newBindableEvent("SettingsChange", eventsFolder), -- Table settings

		detectGroup = newBindableEvent("DetectGroup", eventsFolder), -- String team ("attackers" or "defenders")
	}

	local panel = setmetatable({
		UI = ui,
		state = {},
		Events = events,
		iconDetails = iconDetails or defaultIconDetails,
		blur = blur,
		settings = settings,
		colors = colors,
		refs = refs,
	}, { __index = panelFunctions })

	return panel
end

function addBasicHoverEffect(button)
	button:SetAttribute(
		"baseColor",
		`{button.BackgroundColor3.R}, {button.BackgroundColor3.G}, {button.BackgroundColor3.B}`
	)
	button:GetPropertyChangedSignal("GuiState"):Connect(function()
		local baseColor = button:GetAttribute("baseColor")
		if button.GuiState == Enum.GuiState.Hover and button:GetAttribute("Locked") ~= true then
			TweenService:Create(
				button,
				TweenInfo.new(0.1),
				{ BackgroundColor3 = Color3.fromRGB(baseColor):Lerp(Color3.new(1, 1, 1), 0.1) }
			):Play()
		else
			TweenService:Create(button, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(baseColor) }):Play()
		end
	end)
end

function panelFunctions:Init()
	local i = 0
	for settingId, settingData in pairs(self.settings) do
		local template

		if table.find(reservedSettingsIds, settingId) then
			continue
		end

		if settingData.type == "text" then
			template = templates.textInput
		elseif settingData.type == "bool" then
			template = templates.boolInput
		else
			error("Invalid setting type: " .. tostring(settingData.type))
		end

		local settingUI: Frame = template:Clone()
		settingUI.Name = settingId
		settingUI.TextLabel.Text = settingData.label
		if settingData.order then
			i = settingData.order
		end
		settingUI.LayoutOrder = i
		i = i + 1

		local element = nil
		if settingData.type == "text" then
			settingUI.TextBox.Text = tostring(settingData.value)
			settingUI.TextBox.FocusLost:Connect(function()
				self:_editSetting(settingId, settingUI)
			end)
			element = settingUI.TextBox
		elseif settingData.type == "bool" then
			settingUI.TextButton.Text = settingData.value == true and "ENABLED" or "DISABLED"
			settingUI.TextButton.TextColor3 = settingData.value and self.colors.boolEnabled or self.colors.boolDisabled
			settingUI.TextButton.Activated:Connect(function()
				self:_editSetting(settingId, settingUI)
				settingUI.TextButton.Text = settingData.value and "ENABLED" or "DISABLED"

				if settingUI.TextButton:GetAttribute("Locked") ~= true then
					settingUI.TextButton.TextColor3 = settingData.value and self.colors.boolEnabled
						or self.colors.boolDisabled
				else
					settingUI.TextButton.TextColor3 = self.colors.textDisabled
				end
			end)
			element = settingUI.TextButton
		end

		local baseColor = element.BackgroundColor3
		settingUI:GetPropertyChangedSignal("GuiState"):Connect(function()
			if settingUI.GuiState == Enum.GuiState.Hover then
				TweenService
					:Create(
						element,
						TweenInfo.new(0.1),
						{ BackgroundColor3 = baseColor:Lerp(Color3.new(1, 1, 1), 0.1) }
					)
					:Play()
			else
				TweenService:Create(element, TweenInfo.new(0.1), { BackgroundColor3 = baseColor }):Play()
			end
		end)

		settingUI.Parent = self.refs.settings.content

		self.refs.settings[settingId] = {
			content = settingUI,
			data = settingData,
		}
	end

	local topBarIcon = icon.new()
	topBarIcon:setImage(self.iconDetails.image or defaultIconDetails.image)
	topBarIcon:setImageScale(self.iconDetails.imageScale or defaultIconDetails.imageScale)
	topBarIcon:align(self.iconDetails.align or defaultIconDetails.align)
	topBarIcon:setCaption(self.iconDetails.caption or defaultIconDetails.caption)
	topBarIcon:setOrder(self.iconDetails.order or defaultIconDetails.order)
	topBarIcon:setEnabled(false) -- Will be enabled when permissions are set
	topBarIcon.toggled:Connect(function()
		if not self.UI.Enabled then
			self:Open()
		else
			self:Close()
		end
	end)

	self.icon = topBarIcon

	self.UI.Enabled = false
	self.UI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	self.blur.Enabled = false
	self.blur.Name = `Terminal System Blur - {httpService:GenerateGUID(false)}`
	self.blur.Parent = game.Lighting

	-- Connect buttons

	self.refs.closeButton.Activated:Connect(function()
		self.icon:deselect()
	end)
	self.refs.start.startButton.Activated:Connect(function()
		self.Events.start:Fire()
	end)
	self.refs.controls.resetButton.Activated:Connect(function()
		self.Events.reset:Fire()
	end)
	addBasicHoverEffect(self.refs.controls.resetButton)
	self.refs.controls.stopButton.Activated:Connect(function()
		self.Events.stop:Fire()
	end)
	addBasicHoverEffect(self.refs.controls.stopButton)
	self.refs.controls.time.freezeButton.Activated:Connect(function()
		self.Events.timeFreeze:Fire(true)
	end)
	addBasicHoverEffect(self.refs.controls.time.freezeButton)
	self.refs.controls.time.unfreezeButton.Activated:Connect(function()
		self.Events.timeFreeze:Fire(false)
	end)
	addBasicHoverEffect(self.refs.controls.time.unfreezeButton)
	self.refs.controls.time.minus10Button.Activated:Connect(function()
		self.Events.timeChange:Fire(-10)
	end)
	addBasicHoverEffect(self.refs.controls.time.minus10Button)
	self.refs.controls.time.minus30Button.Activated:Connect(function()
		self.Events.timeChange:Fire(-30)
	end)
	addBasicHoverEffect(self.refs.controls.time.minus30Button)
	self.refs.controls.time.plus10Button.Activated:Connect(function()
		self.Events.timeChange:Fire(10)
	end)
	addBasicHoverEffect(self.refs.controls.time.plus10Button)
	self.refs.controls.time.plus30Button.Activated:Connect(function()
		self.Events.timeChange:Fire(30)
	end)
	addBasicHoverEffect(self.refs.controls.time.plus30Button)
	self.refs.controls.progress.lockButton.Activated:Connect(function()
		self.Events.progressLock:Fire(true)
	end)
	addBasicHoverEffect(self.refs.controls.progress.lockButton)
	self.refs.controls.progress.unlockButton.Activated:Connect(function()
		self.Events.progressLock:Fire(false)
	end)
	addBasicHoverEffect(self.refs.controls.progress.unlockButton)
	self.refs.controls.progress.attackersMinus5Button.Activated:Connect(function()
		self.Events.progressChange:Fire({ attackers = -5 })
	end)
	addBasicHoverEffect(self.refs.controls.progress.attackersMinus5Button)
	self.refs.controls.progress.attackersPlus5Button.Activated:Connect(function()
		self.Events.progressChange:Fire({ attackers = 5 })
	end)
	addBasicHoverEffect(self.refs.controls.progress.attackersPlus5Button)
	self.refs.controls.progress.defendersMinus5Button.Activated:Connect(function()
		self.Events.progressChange:Fire({ defenders = -5 })
	end)
	addBasicHoverEffect(self.refs.controls.progress.defendersMinus5Button)
	self.refs.controls.progress.defendersPlus5Button.Activated:Connect(function()
		self.Events.progressChange:Fire({ defenders = 5 })
	end)
	addBasicHoverEffect(self.refs.controls.progress.defendersPlus5Button)

	-- Bind misc buttons and settings
	self.refs.misc.attackersLock.button.Activated:Connect(function()
		if self.refs.misc.attackersLock.button:GetAttribute("Locked") == true then
			return
		end
		local currentValue = self.settings.attackersTeamLock.value
		self.settings.attackersTeamLock.value = not currentValue
		self.refs.misc.attackersLock.button.Text = self.settings.attackersTeamLock.value == true and "ENABLED"
			or "DISABLED"
		self.refs.misc.attackersLock.button.TextColor3 = self.settings.attackersTeamLock.value
				and self.colors.boolEnabled
			or self.colors.boolDisabled
		self.Events.settingsChange:Fire(self.settings)
	end)
	self.refs.misc.attackersLock.button.Text = self.settings.attackersTeamLock.value == true and "ENABLED" or "DISABLED"
	addBasicHoverEffect(self.refs.misc.attackersLock.button)

	self.refs.misc.defendersLock.button.Activated:Connect(function()
		if self.refs.misc.defendersLock.button:GetAttribute("Locked") == true then
			return
		end
		local currentValue = self.settings.defendersTeamLock.value
		self.settings.defendersTeamLock.value = not currentValue
		self.refs.misc.defendersLock.button.Text = self.settings.defendersTeamLock.value == true and "ENABLED"
			or "DISABLED"
		self.refs.misc.defendersLock.button.TextColor3 = self.settings.defendersTeamLock.value
				and self.colors.boolEnabled
			or self.colors.boolDisabled
		self.Events.settingsChange:Fire(self.settings)
	end)
	self.refs.misc.defendersLock.button.Text = self.settings.defendersTeamLock.value == true and "ENABLED" or "DISABLED"
	addBasicHoverEffect(self.refs.misc.defendersLock.button)

	self.refs.misc.serverLock.button.Activated:Connect(function()
		if self.refs.misc.serverLock.button:GetAttribute("Locked") == true then
			return
		end
		local currentValue = self.settings.serverLock.value
		self.settings.serverLock.value = not currentValue
		self.refs.misc.serverLock.button.Text = self.settings.serverLock.value == true and "ENABLED" or "DISABLED"
		self.refs.misc.serverLock.button.TextColor3 = self.settings.serverLock.value == true and self.colors.boolEnabled
			or self.colors.boolDisabled
		self.Events.settingsChange:Fire(self.settings)
	end)
	self.refs.misc.serverLock.button.Text = self.settings.serverLock.value == true and "ENABLED" or "DISABLED"
	addBasicHoverEffect(self.refs.misc.serverLock.button)

	self.refs.misc.attackersGroup.detectButton.Activated:Connect(function()
		self.Events.detectGroup:Fire("attackers")
	end)
	addBasicHoverEffect(self.refs.misc.attackersGroup.detectButton)

	self.refs.misc.defendersGroup.detectButton.Activated:Connect(function()
		self.Events.detectGroup:Fire("defenders")
	end)
	addBasicHoverEffect(self.refs.misc.defendersGroup.detectButton)

	self.refs.misc.attackersGroup.idTextBox.Text = self.settings.attackersGroupId.value
	addBasicHoverEffect(self.refs.misc.attackersGroup.idTextBox)

	self.refs.misc.defendersGroup.idTextBox.Text = self.settings.defendersGroupId.value
	addBasicHoverEffect(self.refs.misc.defendersGroup.idTextBox)

	self.refs.misc.defendersGroup.idTextBox.FocusLost:Connect(function()
		local newId = self.refs.misc.defendersGroup.idTextBox.Text
		if tonumber(newId) then
			self.settings.defendersGroupId.value = newId
			self.Events.settingsChange:Fire(self.settings)
		else
			self.refs.misc.defendersGroup.idTextBox.Text = self.settings.defendersGroupId.value
		end
	end)
	self.refs.misc.attackersGroup.idTextBox.FocusLost:Connect(function()
		local newId = self.refs.misc.attackersGroup.idTextBox.Text
		if tonumber(newId) then
			self.settings.attackersGroupId.value = newId
			self.Events.settingsChange:Fire(self.settings)
		else
			self.refs.misc.attackersGroup.idTextBox.Text = self.settings.attackersGroupId.value
		end
	end)

	self.currentMenu = "start" -- start | settings | misc
	self.refs.start.content.Visible = true
	self.refs.controls.content.Visible = false
	self.refs.misc.content.Visible = false
	self.refs.settings.content.Visible = false
	self.refs.menu.controls.TextColor3 = self.colors.textWhite
	self.refs.menu.misc.TextColor3 = self.colors.textDisabled
	self.refs.menu.settings.TextColor3 = self.colors.textDisabled
	--- Binding menu buttons

	self.refs.menu.controls:GetPropertyChangedSignal("GuiState"):Connect(function()
		if self.refs.menu.controls.GuiState == Enum.GuiState.Hover then
			if self.currentMenu ~= "controls" and self.currentMenu ~= "start" then
				self.refs.menu.controls.TextColor3 = self.colors.textWhite:Lerp(self.colors.textDisabled, 0.5)
			else
				self.refs.menu.controls.TextColor3 = self.colors.textWhite
			end
		else
			if self.currentMenu ~= "controls" and self.currentMenu ~= "start" then
				self.refs.menu.controls.TextColor3 = self.colors.textDisabled
			end
		end
	end)
	self.refs.menu.misc:GetPropertyChangedSignal("GuiState"):Connect(function()
		if self.refs.menu.misc.GuiState == Enum.GuiState.Hover then
			if self.currentMenu ~= "misc" then
				self.refs.menu.misc.TextColor3 = self.colors.textWhite:Lerp(self.colors.textDisabled, 0.5)
			else
				self.refs.menu.misc.TextColor3 = self.colors.textWhite
			end
		else
			if self.currentMenu ~= "misc" then
				self.refs.menu.misc.TextColor3 = self.colors.textDisabled
			end
		end
	end)
	self.refs.menu.settings:GetPropertyChangedSignal("GuiState"):Connect(function()
		if self.refs.menu.settings.GuiState == Enum.GuiState.Hover then
			if self.currentMenu ~= "settings" then
				self.refs.menu.settings.TextColor3 = self.colors.textWhite:Lerp(self.colors.textDisabled, 0.5)
			else
				self.refs.menu.settings.TextColor3 = self.colors.textWhite
			end
		else
			if self.currentMenu ~= "settings" then
				self.refs.menu.settings.TextColor3 = self.colors.textDisabled
			end
		end
	end)

	self.refs.menu.controls.MouseButton1Click:Connect(function()
		self.refs.menu.controls.TextColor3 = self.colors.textWhite
		self.refs.menu.misc.TextColor3 = self.colors.textDisabled
		self.refs.menu.settings.TextColor3 = self.colors.textDisabled

		if self.state.started == true then
			self.currentMenu = "controls"

			self.refs.settings.content.Visible = false
			self.refs.misc.content.Visible = false

			self.refs.start.content.Visible = false
			self.refs.controls.content.Visible = true
		else
			self.refs.settings.content.Visible = false
			self.refs.misc.content.Visible = false

			self.currentMenu = "start"
			self.refs.start.content.Visible = true
			self.refs.controls.content.Visible = false
		end
	end)
	self.refs.menu.misc.MouseButton1Click:Connect(function()
		self.currentMenu = "misc"
		self.refs.menu.controls.TextColor3 = self.colors.textDisabled
		self.refs.menu.misc.TextColor3 = self.colors.textWhite
		self.refs.menu.settings.TextColor3 = self.colors.textDisabled

		self.refs.settings.content.Visible = false
		self.refs.controls.content.Visible = false
		self.refs.start.content.Visible = false
		self.refs.misc.content.Visible = true
	end)
	self.refs.menu.settings.MouseButton1Click:Connect(function()
		self.currentMenu = "settings"
		self.refs.menu.controls.TextColor3 = self.colors.textDisabled
		self.refs.menu.misc.TextColor3 = self.colors.textDisabled
		self.refs.menu.settings.TextColor3 = self.colors.textWhite

		self.refs.misc.content.Visible = false
		self.refs.controls.content.Visible = false
		self.refs.start.content.Visible = false
		self.refs.settings.content.Visible = true
	end)
end

type state = {
	attackersProgress: number,
	defendersProgress: number,

	started: boolean,

	timeRemaining: number,
	totalTime: number,
	timeFrozen: boolean,

	locked: boolean,

	attackersName: string,
	defendersName: string,
	attackersIcon: string,
	defendersIcon: string,
	attackersGroupId: string,
	defendersGroupId: string,

	serverLocked: boolean,
	attackersTeamLocked: boolean,
	defendersTeamLocked: boolean,
}

-- Acting upon state changes
function panelFunctions:_stateChange_updateTime()
	local currentState = self.state :: state
	if self.state.started ~= true then
		local total = currentState.totalTime or 0
		if total <= 0 then
			self.refs.controls.time.label.time1.Text = "00:00"
			self.refs.controls.time.label.separator.Text = " / "
			self.refs.controls.time.label.time2.Text = "00:00"
			return
		end
		local totalRemString = string.format("%02d", math.floor(total % 60))
		local totalMinString = string.format("%02d", math.floor(total / 60))
		local totalTimeString = totalMinString .. ":" .. totalRemString
		self.refs.controls.time.label.time1.Text = "00:00"
		self.refs.controls.time.label.separator.Text = " / "
		self.refs.controls.time.label.time2.Text = totalTimeString
		return
	end
	local left = currentState.timeRemaining
	local total = currentState.totalTime

	local remString = string.format("%02d", math.floor(left % 60))
	local minString = string.format("%02d", math.floor(left / 60))
	local timeString = minString .. ":" .. remString

	local totalRemString = string.format("%02d", math.floor(total % 60))
	local totalMinString = string.format("%02d", math.floor(total / 60))
	local totalTimeString = totalMinString .. ":" .. totalRemString

	self.refs.controls.time.label.time1.Text = timeString
	self.refs.controls.time.label.separator.Text = " / "
	self.refs.controls.time.label.time2.Text = totalTimeString
end
function panelFunctions:_stateChange_timeFreeze()
	local currentState = self.state :: state
	if currentState.timeFrozen then
		self.refs.controls.time.freezeButton.TextColor3 = self.colors.textDisabled
		self.refs.controls.time.unfreezeButton.TextColor3 = self.colors.textWhite
		self.refs.controls.time.freezeButton:SetAttribute("Locked", true)
		self.refs.controls.time.unfreezeButton:SetAttribute("Locked", false)
	else
		self.refs.controls.time.freezeButton.TextColor3 = self.colors.textWhite
		self.refs.controls.time.unfreezeButton.TextColor3 = self.colors.textDisabled
		self.refs.controls.time.freezeButton:SetAttribute("Locked", false)
		self.refs.controls.time.unfreezeButton:SetAttribute("Locked", true)
	end
end
function panelFunctions:_stateChange_locked()
	local currentState = self.state :: state
	if currentState.locked then
		self.refs.controls.progress.lockButton.TextColor3 = self.colors.textDisabled
		self.refs.controls.progress.unlockButton.TextColor3 = self.colors.textWhite
		self.refs.controls.progress.lockButton:SetAttribute("Locked", true)
		self.refs.controls.progress.unlockButton:SetAttribute("Locked", false)
	else
		self.refs.controls.progress.lockButton.TextColor3 = self.colors.textWhite
		self.refs.controls.progress.unlockButton.TextColor3 = self.colors.textDisabled
		self.refs.controls.progress.lockButton:SetAttribute("Locked", false)
		self.refs.controls.progress.unlockButton:SetAttribute("Locked", true)
	end
end

function toggleButton(btn: TextButton, enabled: boolean, colors: { boolEnabled: Color3, boolDisabled: Color3 })
	btn.Text = enabled and "ENABLED" or "DISABLED"
	btn.TextColor3 = enabled and colors.boolEnabled or colors.boolDisabled
end

function panelFunctions:_stateChange_teamData()
	local currentState = self.state :: state
	self.refs.misc.attackersGroup.groupName.Text = currentState.attackersName
	self.refs.misc.attackersGroup.icon.Image = currentState.attackersIcon
	self.refs.misc.defendersGroup.groupName.Text = currentState.defendersName
	self.refs.misc.defendersGroup.icon.Image = currentState.defendersIcon

	if currentState.attackersGroupId == nil or currentState.attackersGroupId == "" then
		self.refs.misc.attackersLock.button:SetAttribute("Locked", true)
		self.refs.misc.attackersLock.button.TextColor3 = self.colors.textDisabled
	else
		self.refs.misc.attackersLock.button:SetAttribute("Locked", false)
		self.refs.misc.attackersLock.button.TextColor3 = currentState.attackersTeamLocked and self.colors.boolEnabled
			or self.colors.boolDisabled
	end

	if currentState.defendersGroupId == nil or currentState.defendersGroupId == "" then
		self.refs.misc.defendersLock.button:SetAttribute("Locked", true)
		self.refs.misc.defendersLock.button.TextColor3 = self.colors.textDisabled
	else
		self.refs.misc.defendersLock.button:SetAttribute("Locked", false)
		self.refs.misc.defendersLock.button.TextColor3 = currentState.defendersTeamLocked and self.colors.boolEnabled
			or self.colors.boolDisabled
	end

	if
		(currentState.attackersGroupId ~= nil and currentState.attackersGroupId ~= "")
		and (currentState.defendersGroupId ~= nil and currentState.defendersGroupId ~= "")
	then
		self.refs.misc.serverLock.button:SetAttribute("Locked", false)
		self.refs.misc.serverLock.button.TextColor3 = currentState.serverLocked and self.colors.boolEnabled
			or self.colors.boolDisabled
	else
		self.refs.misc.serverLock.button:SetAttribute("Locked", true)
		self.refs.misc.serverLock.button.TextColor3 = self.colors.textDisabled
	end
end

function panelFunctions:_stateChange_groupLocks()
	local currentState = self.state :: state
	toggleButton(self.refs.misc.attackersLock.button, currentState.attackersTeamLocked, self.colors)
	toggleButton(self.refs.misc.defendersLock.button, currentState.defendersTeamLocked, self.colors)
	toggleButton(self.refs.misc.serverLock.button, currentState.serverLocked, self.colors)

	if currentState.attackersGroupId == nil or currentState.attackersGroupId == "" then
		self.refs.misc.attackersLock.button:SetAttribute("Locked", true)
		self.refs.misc.attackersLock.button.TextColor3 = self.colors.textDisabled
	end

	if currentState.defendersGroupId == nil or currentState.defendersGroupId == "" then
		self.refs.misc.defendersLock.button:SetAttribute("Locked", true)
		self.refs.misc.defendersLock.button.TextColor3 = self.colors.textDisabled
	end

	if
		(currentState.attackersGroupId ~= nil and currentState.attackersGroupId ~= "")
		and (currentState.defendersGroupId ~= nil and currentState.defendersGroupId ~= "")
	then
		self.refs.misc.serverLock.button:SetAttribute("Locked", false)
		self.refs.misc.serverLock.button.TextColor3 = self.colors.textWhite
	else
		self.refs.misc.serverLock.button:SetAttribute("Locked", true)
		self.refs.misc.serverLock.button.TextColor3 = self.colors.textDisabled
	end
end

function panelFunctions:_statChange_started()
	if self.currentMenu == "start" and self.state.started then
		self.currentMenu = "controls"
		self.refs.start.content.Visible = false
		self.refs.controls.content.Visible = true
	end

	if self.currentMenu == "controls" and not self.state.started then
		self.currentMenu = "start"
		self.refs.start.content.Visible = true
		self.refs.controls.content.Visible = false
	end
end

local actions = {
	timeRemaining = panelFunctions._stateChange_updateTime,
	totalTime = panelFunctions._stateChange_updateTime,
	timeFrozen = panelFunctions._stateChange_timeFreeze,

	locked = panelFunctions._stateChange_locked,

	attackersName = panelFunctions._stateChange_teamData,
	attackersIcon = panelFunctions._stateChange_teamData,
	defendersName = panelFunctions._stateChange_teamData,
	defendersIcon = panelFunctions._stateChange_teamData,

	attackersTeamLock = panelFunctions._stateChange_groupLocks,
	defendersTeamLock = panelFunctions._stateChange_groupLocks,
	serverLock = panelFunctions._stateChange_groupLocks,

	started = panelFunctions._statChange_started,
}

function panelFunctions:UpdateState(state)
	local oldState = table.clone(self.state)
	for key, value in pairs(state) do
		self.state[key] = value
	end

	for key, action in pairs(actions) do
		if oldState[key] ~= self.state[key] then
			action(self)
		end
	end
end

function panelFunctions:_editSetting(id, item)
	local settingData = self.settings[id]

	local newValue
	if settingData.type == "text" then
		if item.TextBox:GetAttribute("Locked") == true then
			return
		end
		newValue = item.TextBox.Text
		if settingData.validation then
			if not settingData.validation(newValue) then
				item.TextBox.Text = tostring(settingData.value)
				return
			end
		end
	else
		if item.TextButton:GetAttribute("Locked") == true then
			return
		end
		newValue = item.TextButton.Text == "DISABLED"
	end

	settingData.value = settingData.transform and settingData.transform(newValue) or newValue
	self.Events.settingsChange:Fire(self.settings)
end

function panelFunctions:Open()
	self.UI.Enabled = true
	self.blur.Enabled = true
	self.icon:select()
end

function panelFunctions:Close()
	self.UI.Enabled = false
	self.blur.Enabled = false
	self.icon:deselect()
end

function panelFunctions:UpdatePermission(isAdmin)
	self.icon:setEnabled(isAdmin)
end

return {
	new = newPanel,
}
