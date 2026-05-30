local module = {}
local tweenService = game:GetService("TweenService")
function displayText(animationDuration, textLabel)

	local tweenInfo = TweenInfo.new(animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {TextTransparency = 0}

	local tween = tweenService:Create(textLabel, tweenInfo, goal)
	tween:Play()
end


local center = script.Parent.Frame.Main.Center

local tweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.2)
local openTween = tweenService:Create(script.Parent.Frame, tweenInfo, {Position = UDim2.fromScale(0,0)})
local closeTween = tweenService:Create(script.Parent.Frame, tweenInfo, {Position = UDim2.fromScale(0,-2)})


function upperCaseFirstLetter(str:string)
	return str:gsub("^%l", string.upper)
end
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

function module.showCloudLogging(toggle, matchCode)
	script.Parent.Frame.Main.Center.cloudLogging.Text = `Match results uploaded ! Code: {matchCode}`
	script.Parent.Frame.Main.Center.cloudLogging.Visible = toggle
end

function module.display(config:config, winningTeam)
	if(winningTeam == "draw")then
		center.Icon.Visible = false
		center.displayName.Visible = false
		center.startSubtext.Text = "Draw"
	elseif(winningTeam == "attackers")then
		center.Icon.Visible = true
		center.displayName.Visible = true
		center.startSubtext.Text = `{upperCaseFirstLetter(config.core.attackers.name)} won`
		center.Icon.Image = config.core.attackers.icon
	elseif(winningTeam == "defenders")then
		center.Icon.Visible = true
		center.displayName.Visible = true
		center.startSubtext.Text = `{upperCaseFirstLetter(config.core.defenders.name)} won`
		center.Icon.Image = config.core.defenders.icon
	end
	
	center.startTitle.Text = workspace:GetAttribute("GameName")
	
	if(game.Lighting:FindFirstChild("TermGUIBlur") == nil)then
		script.TermGUIBlur:Clone().Parent = game.Lighting
	end
	
	script.Parent.Frame.Position = UDim2.fromScale(0,-2)
	script.Parent.Enabled = true
	openTween:Play()
	task.wait(0.2)
	task.wait(7)
	module.hide()
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
