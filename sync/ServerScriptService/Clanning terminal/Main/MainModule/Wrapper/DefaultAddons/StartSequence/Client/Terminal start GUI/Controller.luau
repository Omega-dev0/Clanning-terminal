local module = {}
local tweenService = game:GetService("TweenService")
function displayText(animationDuration, textLabel)

	local tweenInfo = TweenInfo.new(animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {TextTransparency = 0}

	local tween = tweenService:Create(textLabel, tweenInfo, goal)
	tween:Play()
end


local team1 = script.Parent.Frame.Main.Team1
local team2 =script.Parent.Frame.Main.Team2
local center = script.Parent.Frame.Main.Center

local tweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.2)
local openTween = tweenService:Create(script.Parent.Frame, tweenInfo, {Position = UDim2.fromScale(0,0)})
local closeTween = tweenService:Create(script.Parent.Frame, tweenInfo, {Position = UDim2.fromScale(0,-2)})

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
	}
}

function module.display(cfg:config)
	
	team1.displayName.TextTransparency = 1
	team2.displayName.TextTransparency = 1
	team1.subtext.TextTransparency = 1
	team2.subtext.TextTransparency = 1
	
	team1.Icon.Image = cfg.core.attackers.icon
	team1.displayName.Text = cfg.core.attackers.name
	team1.subtext.Text = ""

	team2.Icon.Image = cfg.core.defenders.icon
	team2.displayName.Text = cfg.core.defenders.name
	team2.subtext.Text = ""
	
	center.startTitle.Text = workspace:GetAttribute("GameName")
	
	if(game.Lighting:FindFirstChild("TermGUIBlur") == nil)then
		script.TermGUIBlur:Clone().Parent = game.Lighting
	end
	
	script.Parent.Frame.Position = UDim2.fromScale(0,-2)
	script.Parent.Enabled = true
	task.spawn(function()
		local timeLeft = 5
		c = game:GetService("RunService").RenderStepped:Connect(function(dt)
			timeLeft -= dt
			if(timeLeft <= 0)then
				c:Disconnect()
				module.hide()
			end
			local minutes = math.floor(timeLeft / 60)
			local seconds = math.floor(timeLeft % 60)
			local centiseconds = math.floor((timeLeft * 100) % 100)
			center.Timer.Text = string.format("%02d:%02d:%02d", minutes, seconds, centiseconds)
		end)
	end)
	openTween:Play()
	task.wait(0.2)
	
	displayText(1, team1.displayName)
	displayText(1, team2.displayName)

	displayText(3, team1.subtext)
	displayText(3, team2.subtext)
	
end

function module.hide()
	
	closeTween:Play()
	task.wait(0.2)
	
	if(game.Lighting:FindFirstChild("TermGUIBlur") ~= nil)then
		game.Lighting:FindFirstChild("TermGUIBlur"):Destroy()
	end
	
	script.Parent.Enabled = false
end


return module
