local module = {}
local runService = game:GetService("RunService")



module.states = {
	locked = false,
}



module.connections = {
}

local main = script.Parent.Frame

module.ui = {
	attackerPoints = main.AttackerPoints,
	defenderPoints = main.DefenderPoints,
	stateText = main.State,
	timeText = main.Time,
	attackersBar = main.Attackers.Bar,
	defendersBar = main.Defenders.Bar,
	captureGradient = main.CaptureIndicator.UIGradient,

	attackersIcon = main.StateIndicator.Attackers.Icon,
	defendersIcon = main.StateIndicator.Defenders.Icon
}



function module:updateTime(timeLeft:number, timeFrozen: boolean)
	if(timeFrozen)then
		-- Style if time is frozen
		self.ui.timeText.TextColor3 = Color3.new(0.227451, 0.227451, 0.227451)
	else
		-- Style if time is unfrozen
		self.ui.timeText.TextColor3 = Color3.new(1, 1, 1)
		if(timeLeft <= 0)then
			timeLeft = 0
		end
		local minutes = math.floor(timeLeft / 60)
		local seconds = math.floor(timeLeft % 60)
		local centiseconds = math.floor((timeLeft * 100) % 100)


		-- Update your timer text here
		self.ui.timeText.Text =  string.format("%02d:%02d:%02d", minutes, seconds, centiseconds)
	end

end

function module:toggleLock(isLocked:boolean)
	self.states.locked = isLocked
	if(isLocked)then
		-- Style if locked
		self.ui.attackersBar.BackgroundColor3 = Color3.new(0.266667, 0.266667, 0.266667)
		self.ui.defendersBar.BackgroundColor3 = Color3.new(0.266667, 0.266667, 0.266667)	
	else
		-- Style if unlocked
		self.ui.attackersBar.BackgroundColor3 = Color3.fromRGB(181, 2, 5)
		self.ui.defendersBar.BackgroundColor3 = Color3.fromRGB(0, 112, 181)
	end
end

function module:updateSettings(config)
	self.ui.attackersIcon.Image = config.attackersIcon
	self.ui.defendersIcon.Image = config.defendersIcon
	self.config = config
end

function module:updateState(attackersCount:number,defendersCount:number,attackersProgress: number, defendersProgress:number,attackersPoint:number,defenderPoints:number,isContested:boolean,terminalState: "attackers" | "defenders" | "neutral", maxPoints:number,captureProgress:number?)


	-- Update the UI elements related to the provided variables here

	self.isContested = isContested
	self.defendersProgress = defendersProgress
	self.attackersProgress = attackersProgress
	self.attackersPoint = attackersPoint
	self.defenderPoints = defenderPoints
	self.maxPoints = maxPoints

	self.ui.attackerPoints.Text = `{math.floor(self.defenderPoints)} / {self.maxPoints}`
	self.ui.defenderPoints.Text = `{math.floor(self.attackersPoint)} / {self.maxPoints}`

	self.ui.stateText.Text = terminalState:sub(1,1):upper() .. terminalState:sub(2,-1)

	local gradient = self.ui.captureGradient :: UIGradient
	if(terminalState == "attackers")then
		--gradient.Color = ColorSequence.new(Color3.fromRGB(255,56,59))
		self.ui.attackersIcon.Visible = true
		self.ui.defendersIcon.Visible = false
	elseif terminalState == "defenders" then
		--gradient.Color = ColorSequence.new(Color3.fromRGB(65,116,255))
		self.ui.attackersIcon.Visible = false
		self.ui.defendersIcon.Visible = true
	else
		self.ui.attackersIcon.Visible = false
		self.ui.defendersIcon.Visible = false
	end

	local color
	if(captureProgress > 0)then
		color = Color3.fromRGB(255,56,59)
	elseif captureProgress < 0 then
		color = Color3.fromRGB(65,116,255)
		captureProgress *= -1
	else
		color = Color3.fromRGB(32,31,30)
	end
	captureProgress = 1 - captureProgress
	local startColor = ColorSequenceKeypoint.new(0, Color3.fromRGB(32,31,30))
	local endColor  = ColorSequenceKeypoint.new(1, color)


	local SPACE = 0.04

	local mid = ColorSequenceKeypoint.new(captureProgress, color:Lerp(Color3.new(1,1,1),0.1))
	local upperMid, underMid, cs
	if(captureProgress > SPACE)then
		underMid = ColorSequenceKeypoint.new(captureProgress-SPACE, Color3.fromRGB(32,31,30))
	end
	if(captureProgress < 1 - SPACE)then
		upperMid = ColorSequenceKeypoint.new(captureProgress+SPACE, color)
	end
	if(captureProgress <= SPACE)then
		cs =ColorSequence.new({
			startColor,
			mid,
			upperMid,
			endColor
		})
	elseif(captureProgress >= 1 - SPACE)then
		cs =ColorSequence.new({
			startColor,
			underMid,
			mid,
			endColor
		})
	else
		cs =ColorSequence.new({
			startColor,
			underMid,
			mid,
			upperMid,
			endColor
		})
	end

	gradient.Color = cs

	self.ui.attackersBar.Size = UDim2.fromScale(attackersProgress,1)
	self.ui.defendersBar.Size = UDim2.fromScale(defendersProgress,1)
end



return module
