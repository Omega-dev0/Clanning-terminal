local module = {}

local main = script.Parent.Frame
local top,bottom,extraBottom = main.Top, main.Bottom, main.ExtraBottom
local progressContainer = bottom.Frame.Progress


local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

module.ui = {
	timerTextLabel = top.Timer.TextLabel,

	attackersCount= extraBottom.AttackersCount,
	defendersCount= extraBottom.DefendersCount,

	contestedFrame = extraBottom.Contested,
	contestedSideDecorationsRight = extraBottom.Contested.SideDecorations.Right,
	constestedSideBarRight = extraBottom.Contested.SideDecorations.Right.Bar,
	contestedSideDecorationsLeft = extraBottom.Contested.SideDecorations.Left,
	constestedSideBarLeft = extraBottom.Contested.SideDecorations.Left.Bar,
	
	captureProgressFrame = bottom.Frame.CaptureProgress,
	
	attackersProgressContainer = bottom.Frame.Progress.Attackers,
	defendersProgressContainer = bottom.Frame.Progress.Defenders
}


module.trueColors = {
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
function module:updateColors(isRaider)
	self.isRaider = isRaider
	if(isRaider)then
		self.colors = {
			endColor = self.trueColors.endColor,
			attackersPrimary =  self.trueColors.defendersPrimary,
			attackersDark =  self.trueColors.defendersDark,

			defendersPrimary =  self.trueColors.attackersPrimary,
			defendersDark =  self.trueColors.attackersDark,

			disabled =  self.trueColors.disabled,
			lockedPrimary =  self.trueColors.lockedPrimary,
			lockedSecondary =  self.trueColors.lockedSecondary,

			timer =  self.trueColors.timer
		}
	else
		self.colors = self.trueColors
	end


	self.ui.attackersCount.BackgroundColor3 = self.colors.attackersPrimary
	self.ui.attackersCount.TextLabel.TextColor3 = self.colors.attackersDark
	self.ui.defendersCount.BackgroundColor3 = self.colors.defendersPrimary
	self.ui.defendersCount.TextLabel.TextColor3 = self.colors.defendersDark
	
	self.ui.captureProgressFrame.BackgroundColor3 = self.colors.attackersPrimary
	self.ui.captureProgressFrame.Progress.BackgroundColor3 = self.colors.defendersPrimary
	
	self.ui.attackersProgressContainer.BackgroundColor3 = self.colors.attackersPrimary
	self.ui.attackersProgressContainer.Progress.BackgroundColor3 = self.colors.attackersPrimary
	self.ui.defendersProgressContainer.BackgroundColor3 = self.colors.defendersPrimary
	self.ui.defendersProgressContainer.Progress.BackgroundColor3 = self.colors.defendersPrimary
end

module.states = {
	locked = false,
}



module.connections = {
}
module.tweens = {
	["contestedBarLeft"] = nil,
	["contestedBarRight"] = nil
}
--- Contested bars tweens
local constestedBarstweenInfo = TweenInfo.new(0.2,Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, false,0)
module.tweens.contestedBarLeft = tweenService:Create(module.ui.constestedSideBarLeft, constestedBarstweenInfo, {
	Position = UDim2.fromScale(0.6,0),
	BackgroundTransparency = 0.5
})
module.tweens.contestedBarRight = tweenService:Create(module.ui.constestedSideBarRight, constestedBarstweenInfo, {
	Position = UDim2.fromScale(0.4,0),
	BackgroundTransparency = 0.5
})

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

function module:toggleLock(isLocked:boolean)
	self.states.locked = isLocked
	if(isLocked)then
		self.ui.attackersProgressContainer.BackgroundColor3 = self.colors.lockedPrimary
		self.ui.attackersProgressContainer.Progress.BackgroundColor3  = self.colors.lockedPrimary
		self.ui.defendersProgressContainer.BackgroundColor3 = self.colors.lockedPrimary
		self.ui.defendersProgressContainer.Progress.BackgroundColor3  = self.colors.lockedPrimary
		self.ui.attackersCount.Visible = false
		self.ui.attackersCount.Visible = false
	else
		self.ui.attackersProgressContainer.BackgroundColor3 = self.colors.attackersPrimary
		self.ui.attackersProgressContainer.Progress.BackgroundColor3  = self.colors.attackersPrimary
		self.ui.defendersProgressContainer.BackgroundColor3 = self.colors.defendersPrimary
		self.ui.defendersProgressContainer.Progress.BackgroundColor3  = self.colors.defendersPrimary
	end
end

function module:updateState(attackersCount:number,defendersCount:number,attackersProgress: number, defendersProgress:number,attackersPoint:number,defenderPoints:number,isContested:boolean,terminalState: "attackers" | "defenders" | "neutral", maxPoints:number,captureProgress:number?)
	self.ui.defendersCount.TextLabel.Text = defendersCount
	self.ui.attackersCount.TextLabel.Text = attackersCount
	if(defendersCount > 0)then
		self.ui.defendersCount.Visible = true
	else
		self.ui.defendersCount.Visible = false
	end
	if(attackersCount > 0)then
		self.ui.attackersCount.Visible = true
	else
		self.ui.attackersCount.Visible = false
	end
	
	if(terminalState == "attackers")then
		self.ui.captureProgressFrame.LockedStroke.Enabled = true
	elseif(terminalState == "defenders")then
		self.ui.captureProgressFrame.LockedStroke.Enabled = true
	elseif(terminalState == "neutral")then
		self.ui.captureProgressFrame.LockedStroke.Enabled = false
	end
	
	if(captureProgress == nil)then
		self.ui.captureProgressFrame.Visible = false
	else
		-- -1-1
		-- -1 --> defenders
		-- 1 --> attackers
		captureProgress = captureProgress * -1
		captureProgress += 1 -- 0-2
		self.ui.captureProgressFrame.Visible = true
		self.ui.captureProgressFrame.Progress.Size = UDim2.fromScale(1,captureProgress/2)
	end

	if(self.isContested ~= isContested and isContested == true)then
		self.ui.contestedFrame.Visible = true
		self.tweens.contestedBarLeft:Play()
		self.tweens.contestedBarRight:Play()
	elseif(self.isContested ~= isContested and isContested == false)then
		self.ui.contestedFrame.Visible = false
		self.tweens.contestedBarLeft:Cancel()
		self.tweens.contestedBarRight:Cancel()
	end
	self.isContested = isContested
	self.defendersProgress = defendersProgress
	self.attackersProgress = attackersProgress
	self.attackersPoint = attackersPoint
	self.defenderPoints = defenderPoints
	self.maxPoints = maxPoints
	self:updateProgress()
end

function module:updateProgress()
	self.ui.attackersProgressContainer.Progress.Size = UDim2.new(self.attackersProgress,0,1,0)
	self.ui.attackersProgressContainer.TextLabel.Text = `{math.floor(self.attackersPoint)} / {self.maxPoints}`
	
	self.ui.defendersProgressContainer.Progress.Size = UDim2.new(self.defendersProgress,0,1,0)
	self.ui.defendersProgressContainer.TextLabel.Text = `{math.floor(self.defenderPoints)} / {self.maxPoints}`
end

module:updateColors(false)

return module
