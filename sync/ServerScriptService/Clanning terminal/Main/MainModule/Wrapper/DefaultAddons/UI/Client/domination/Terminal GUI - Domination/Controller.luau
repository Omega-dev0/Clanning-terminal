local module = {}

local main = script.Parent.Frame
local top,bottom,extraBottom = main.Top, main.Bottom, main.Points
local progressContainer = bottom.Frame.Progress


local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

module.ui = {
	timerTextLabel = top.Timer.TextLabel,

	attackersProgressContainer = bottom.Frame.Progress.Attackers,
	defendersProgressContainer = bottom.Frame.Progress.Defenders,
	
	
	pointsContainer = extraBottom
}

module.states = {
	locked = false,
}



module.connections = {
}

module.colors = {
	endColor = Color3.fromRGB(255, 222, 58),
	attackersPrimary = Color3.fromRGB(200, 47, 83),
	attackersDark = Color3.fromRGB(108, 25, 46),

	defendersPrimary = Color3.fromRGB(92, 206, 255),
	defendersDark = Color3.fromRGB(40, 91, 112),

	disabled = Color3.fromRGB(143, 143, 143),
	lockedPrimary = Color3.fromRGB(59, 57, 57),
	lockedSecondary = Color3.fromRGB(211, 211, 211),

	timer = Color3.fromRGB(255, 204, 64)
}


function module:updateTime(timeLeft:number, timeFrozen: boolean)
	if(timeFrozen)then
		self.ui.timerTextLabel.TextColor3 = self.colors.disabled
		return
	else
		self.ui.timerTextLabel.TextColor3 = self.colors.timer
	end
	if(timeLeft <= 0)then
		timeLeft = 0
	end
	local minutes = math.floor(timeLeft / 60)
	local seconds = math.floor(timeLeft % 60)
	local centiseconds = math.floor((timeLeft * 100) % 100)
	self.ui.timerTextLabel.Text = string.format("%02d:%02d:%02d", minutes, seconds, centiseconds)
end

function updatePointColor(point:Frame, color1,color2, progress)
	local colorSequence
	local interval = 0.02
	
	if(progress <= interval)then
		colorSequence = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color2),
			ColorSequenceKeypoint.new(1, color2),
		})
	elseif(progress >= 1-interval)then
		colorSequence = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color1),
			ColorSequenceKeypoint.new(1, color1),
		})
	else
		colorSequence = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color1),
			ColorSequenceKeypoint.new(progress - interval, color1),
			ColorSequenceKeypoint.new(progress + interval, color2),
			ColorSequenceKeypoint.new(1, color2),
		})
	end
	
	local gradient : UIGradient = point.UIGradient
	gradient.Color = colorSequence
end


function module:toggleLock(states)
	
	local allLocked = true
	for name,state in pairs(states) do
		local point = self.ui.pointsContainer:FindFirstChild(name)
		if(point and state == "locked")then
			--updatePointColor(point, self.colors.lockedPrimary, self.colors.lockedPrimary, 1)
		else
			allLocked = false
		end
	end
	
	
	
	
	if(allLocked)then
		self.ui.attackersProgressContainer.BackgroundColor3 = self.colors.lockedPrimary
		self.ui.attackersProgressContainer.Progress.BackgroundColor3  = self.colors.lockedPrimary
		self.ui.defendersProgressContainer.BackgroundColor3 = self.colors.lockedPrimary
		self.ui.defendersProgressContainer.Progress.BackgroundColor3  = self.colors.lockedPrimary
	else
		self.ui.attackersProgressContainer.BackgroundColor3 = self.colors.attackersPrimary
		self.ui.attackersProgressContainer.Progress.BackgroundColor3  = self.colors.attackersPrimary
		self.ui.defendersProgressContainer.BackgroundColor3 = self.colors.defendersPrimary
		self.ui.defendersProgressContainer.Progress.BackgroundColor3  = self.colors.defendersPrimary
	end
end

function module:updateState(state, config)
	self.state = state
	self.config = config
	
	for pointName,index in pairs(config.terminal.terminals)do
		local point = self.ui.pointsContainer:FindFirstChild(pointName)
		if(point == nil)then
			point = script.Point:Clone()
			point.Name = pointName
			point.TextLabel.Text = pointName
			updatePointColor(point, self.colors.attackersPrimary, self.colors.defendersPrimary, 0.5)
			point.Parent = self.ui.pointsContainer
			point.LayoutOrder = index
			
		end
	end
	
	for pointName,state in pairs(state.states)do
		local point = self.ui.pointsContainer:FindFirstChild(pointName)
		if(state == "attackers" or state =="defenders")then
			point.LockedStroke.Enabled = true
		else
			point.LockedStroke.Enabled = false
		end
	end
	
	module:updateProgress()
end

function module:updateProgress()
	self.ui.attackersProgressContainer.Progress.Size = UDim2.new(self.state.attackerPoints/self.config.terminal.maxPoints,0,1,0)
	self.ui.attackersProgressContainer.TextLabel.Text = `{math.floor(self.state.attackerPoints or 0)} / {self.config.terminal.maxPoints}`
	
	self.ui.defendersProgressContainer.Progress.Size = UDim2.new(self.state.defenderPoints/self.config.terminal.maxPoints,0,1,0)
	self.ui.defendersProgressContainer.TextLabel.Text = `{math.floor(self.state.defenderPoints or 0)} / {self.config.terminal.maxPoints}`
	
	
	for pointName,progress  in pairs(self.state.captureProgresses) do
		local point = self.ui.pointsContainer:FindFirstChild(pointName)
		progress = (progress + 1)/2 -- [-1,1] --> [0,1]
		updatePointColor(point,self.colors.attackersPrimary, self.colors.defendersPrimary, progress)
	end
end


return module
