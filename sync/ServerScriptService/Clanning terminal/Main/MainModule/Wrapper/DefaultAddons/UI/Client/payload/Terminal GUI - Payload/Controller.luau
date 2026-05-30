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

	progressContainer = bottom.Frame.Progress.Bar
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
	self.colors = self.trueColors
	if(1+1==2)then
		return
	end
	
	--Unused

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
		--self.ui.instructionsLabel.Text = "Push the payload !"
	else
		self.colors = self.trueColors
		
		--self.ui.instructionsLabel.Text = "Stop the payload !"
	end


	self.ui.progressContainer.BackgroundColor3 = self.colors.attackersPrimary
	
	
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
		self.ui.progressContainer.BackgroundColor3 = self.colors.lockedPrimary
		self.ui.progressContainer.Progress.BackgroundColor3  = self.colors.lockedPrimary
		self.ui.attackersCount.Visible = false
		self.ui.attackersCount.Visible = false
	else
		self.ui.progressContainer.BackgroundColor3 = self.colors.attackersPrimary
		self.ui.progressContainer.Progress.BackgroundColor3  = self.colors.attackersPrimary
	end
end

function module:updateState(attackersCount:number,defendersCount:number,progress:number,isContested:boolean,terminalState: "attackers" | "defenders" | "neutral", maxDistance:number)
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
	self.progress = progress
	self.maxDistance = maxDistance
	self:updateProgress()
end

function module:updateProgress()
	self.ui.progressContainer.Progress.Size = UDim2.new(self.progress/100,0,1,0)
	local distanceString = ("%.1f"):format(self.progress * self.maxDistance*0.01)
	self.ui.progressContainer.TextLabel.Text = `{distanceString}m / {math.round(self.maxDistance*10)/10}m`
end

module:updateColors(false)

return module
