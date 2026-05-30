local module = {}

local main = script.Parent.Frame
local top,bottom= main.Top, main.Bottom


local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

module.ui = {
	timerTextLabel = top.Timer.TextLabel,
	
	attackersProgressContainer = bottom.Frame.Left.Attackers,
	defendersProgressContainer = bottom.Frame.Right.Defenders,
	
	attackersTextLabel = bottom.Frame.Middle.Attackers,
	defendersTextLabel = bottom.Frame.Middle.Defenders
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


	
	self.ui.attackersProgressContainer.BackgroundColor3 = self.colors.attackersPrimary
	self.ui.attackersProgressContainer.Progress.BackgroundColor3 = self.colors.attackersPrimary
	self.ui.attackersTextLabel.TextColor3 = self.colors.attackersPrimary
	
	self.ui.defendersProgressContainer.BackgroundColor3 = self.colors.defendersPrimary
	self.ui.defendersProgressContainer.Progress.BackgroundColor3 = self.colors.defendersPrimary
	self.ui.defendersTextLabel.TextColor3 = self.colors.defendersPrimary

end

module.states = {
	locked = false,
}



module.connections = {
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

function module:toggleLock(isLocked:boolean)
	self.states.locked = isLocked
	if(isLocked)then
		self.ui.attackersProgressContainer.BackgroundColor3 = self.colors.lockedPrimary
		self.ui.attackersProgressContainer.Progress.BackgroundColor3 = self.colors.lockedPrimary
		self.ui.attackersTextLabel.TextColor3 = self.colors.lockedPrimary

		self.ui.defendersProgressContainer.BackgroundColor3 = self.colors.lockedPrimary
		self.ui.defendersProgressContainer.Progress.BackgroundColor3 = self.colors.lockedPrimary
		self.ui.defendersTextLabel.TextColor3 = self.colors.lockedPrimary
	else
		self.ui.attackersProgressContainer.BackgroundColor3 = self.colors.attackersPrimary
		self.ui.attackersProgressContainer.Progress.BackgroundColor3 = self.colors.attackersPrimary
		self.ui.attackersTextLabel.TextColor3 = self.colors.attackersPrimary

		self.ui.defendersProgressContainer.BackgroundColor3 = self.colors.defendersPrimary
		self.ui.defendersProgressContainer.Progress.BackgroundColor3 = self.colors.defendersPrimary
		self.ui.defendersTextLabel.TextColor3 = self.colors.defendersPrimary
	end
end

function module:updateState(attackersProgress: number, defendersProgress:number,attackersPoint:number,defenderPoints:number, attackersLeaderName: string?, defendersLeaderName: string?,distanceObject)
	self.ui.attackersProgressContainer.Folder.TextLabel.Text = math.floor(attackersPoint)
	self.ui.defendersProgressContainer.Folder.TextLabel.Text = math.floor(defenderPoints)
	
	self.ui.attackersProgressContainer.Progress.Size = UDim2.fromScale(1, attackersProgress)
	self.ui.defendersProgressContainer.Progress.Size = UDim2.fromScale(1, defendersProgress)
	
	local  attackersLeaderDistance, 
	attackersLeaderDistanceToObjective, 
	defendersLeaderDistance, 
	defendersLeaderDistanceToObjective = distanceObject.distanceToAttackersLeader, distanceObject.attackersLeaderDistanceToObjective, distanceObject.distanceToDefendersLeader, distanceObject.defendersLeaderDistanceToObjective
	
	if attackersLeaderName ~= "" then
		self.ui.attackersTextLabel.Text =  `{attackersLeaderName} {math.round(attackersLeaderDistance) > 0 and `({math.round(attackersLeaderDistance)}m)` or ""} → {math.round(attackersLeaderDistanceToObjective)}m`
	else
		self.ui.attackersTextLabel.Text =  `No leader - pickup the crown to become one`
	end
	
	if defendersLeaderName ~= "" then
		self.ui.defendersTextLabel.Text =  `{defendersLeaderName} {math.round(defendersLeaderDistance) > 0 and `({math.round(defendersLeaderDistance)}m)` or ""} → {math.round(defendersLeaderDistanceToObjective)}m`
	else
		self.ui.defendersTextLabel.Text =  `No leader - pickup the crown to become one`
	end
		
end

module:updateColors(false)

return module
