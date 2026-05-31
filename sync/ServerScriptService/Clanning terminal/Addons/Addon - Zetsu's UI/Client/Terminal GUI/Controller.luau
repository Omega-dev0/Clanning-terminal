local module = {}
local runService = game:GetService("RunService")



module.states = {
	locked = false,
}



module.connections = {
}

local main = script.Parent.TerminalGui

module.ui = {
	right = {
		bar = main.RightPanel.Team2Bar,
		currentHolder = main.RightPanel.CurrentHolder,
		points = main.RightPanel.Team2Points
	},
	left = {
		bar = main.LeftPanel.Team1Bar,
		points = main.LeftPanel.Team1Points,
		timeDisplay = main.LeftPanel.Time
	},
	attackerIcon = main.RaiderIcon,
	defenderIcon = main.DefenderIcon
}

function module:updateTime(timeLeft:number, timeFrozen: boolean)
	if(timeFrozen)then
		self.ui.left.timeDisplay.TextColor3 = Color3.new(0.227451, 0.227451, 0.227451)
	else
		self.ui.left.timeDisplay.TextColor3 = Color3.new(1, 1, 1)

		if(timeLeft <= 0)then
			timeLeft = 0
		end
		local minutes = math.floor(timeLeft / 60)
		local seconds = math.floor(timeLeft % 60)
		local centiseconds = math.floor((timeLeft * 100) % 100)

		self.ui.left.timeDisplay.Text =  string.format("%02d:%02d:%02d", minutes, seconds, centiseconds)
	end

end

function module:toggleLock(isLocked:boolean)
	self.states.locked = isLocked
	if(isLocked)then
		self.ui.right.bar.BackgroundColor3 = Color3.new(0.266667, 0.266667, 0.266667)
		self.ui.left.bar.BackgroundColor3 = Color3.new(0.266667, 0.266667, 0.266667)	
	else
		self.ui.right.bar.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
		self.ui.left.bar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)	
	end
end

function module:updateSettings(config)
	self.ui.attackerIcon.Icon.Image = config.attackersIcon
	self.ui.defenderIcon.Icon.Image = config.defendersIcon
	self.config = config
end

function module:updateState(attackersCount:number,defendersCount:number,attackersProgress: number, defendersProgress:number,attackersPoint:number,defenderPoints:number,isContested:boolean,terminalState: "attackers" | "defenders" | "neutral", maxPoints:number,captureProgress:number?)





	self.isContested = isContested
	self.defendersProgress = defendersProgress
	self.attackersProgress = attackersProgress
	self.attackersPoint = attackersPoint
	self.defenderPoints = defenderPoints
	self.maxPoints = maxPoints

	self.ui.left.points.Text = `{math.floor(self.defenderPoints)} / {self.maxPoints}`
	self.ui.right.points.Text = `{math.floor(self.attackersPoint)} / {self.maxPoints}`

	self.ui.right.currentHolder.Text = terminalState
	captureProgress += 1 -- 0-2

	self.ui.attackerIcon.Size = UDim2.fromOffset((captureProgress/2) * -51,51)
	self.ui.defenderIcon.Size = UDim2.fromOffset((1 -captureProgress/2) * 51,51)

	self.ui.right.bar.Size = UDim2.new(0,248*attackersProgress,1,0)
	self.ui.left.bar.Size = UDim2.new(0,-248*defendersProgress,1,0)
end



return module
