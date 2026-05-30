local terminalId = script:GetAttribute("terminalId")
local httpService = game:GetService("HttpService")
local config = game.ReplicatedStorage:WaitForChild("OmegasTerminalConfig_Persistant") :: Configuration
local packets = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("OmegasTerminalPackets"))
local runService = game:GetService("RunService")

local gui = script:FindFirstChildOfClass("ScreenGui")
gui.Enabled = false
gui.Parent = game.Players.LocalPlayer.PlayerGui
local controller = require(gui.Controller)

local cfg
local function updateSettings()
	cfg = {
		core = httpService:JSONDecode(config:GetAttribute("core_config")),
		terminal = httpService:JSONDecode(config:GetAttribute("terminal_config")),
	}
	gui.Enabled = cfg.core.started
end

local state = {
	attackerPoints = 0,
	defenderPoints = 0,
	state = "locked", -- "neutral", "locked", "attackers", "defenders"
}
function updateState()
	local attackersLeader, defendersLeader = nil, nil

	if cfg.terminal.attackersLeaderUserId then
		attackersLeader = game.Players:GetPlayerByUserId(cfg.terminal.attackersLeaderUserId)
	end
	if cfg.terminal.defendersLeaderUserId then
		defendersLeader = game.Players:GetPlayerByUserId(cfg.terminal.defendersLeaderUserId)
	end

	local rootPosition = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character.PrimaryPart.Position
		or Vector3.new(0, 0, 0)

	local attackersLeaderPosition = attackersLeader
			and attackersLeader.Character
			and attackersLeader.Character.PrimaryPart
			and attackersLeader.Character.PrimaryPart.Position
		or nil
	local defendersLeaderPosition = defendersLeader
			and defendersLeader.Character
			and defendersLeader.Character.PrimaryPart
			and defendersLeader.Character.PrimaryPart.Position
		or nil

	local clostestAttackersObjectiveToLeaderDistance = math.huge
	local closestDefendersObjectiveToLeaderDistance = math.huge

	for _, objective in pairs(cfg.terminal.attackersGoals) do
		local objectivePosition = Vector3.new(
			tonumber(objective:split("/")[1]),
			tonumber(objective:split("/")[2]),
			tonumber(objective:split("/")[3])
		)
		if attackersLeaderPosition then
			local distance = (objectivePosition - attackersLeaderPosition).Magnitude
			if distance < clostestAttackersObjectiveToLeaderDistance then
				clostestAttackersObjectiveToLeaderDistance = distance
			end
		end
	end

	for _, objective in pairs(cfg.terminal.defendersGoals) do
		local objectivePosition = Vector3.new(
			tonumber(objective:split("/")[1]),
			tonumber(objective:split("/")[2]),
			tonumber(objective:split("/")[3])
		)
		if defendersLeaderPosition then
			local distance = (objectivePosition - defendersLeaderPosition).Magnitude
			if distance < closestDefendersObjectiveToLeaderDistance then
				closestDefendersObjectiveToLeaderDistance = distance
			end
		end
	end
	controller:updateState(
		state.attackerPoints / cfg.terminal.maxPoints,
		state.defenderPoints / cfg.terminal.maxPoints,
		state.attackerPoints,
		state.defenderPoints,
		attackersLeader and attackersLeader.DisplayName or "",
		defendersLeader and defendersLeader.DisplayName or "",
		{
			distanceToAttackersLeader = attackersLeaderPosition and (attackersLeaderPosition - rootPosition).Magnitude
				or nil,
			attackersLeaderDistanceToObjective = clostestAttackersObjectiveToLeaderDistance,
			distanceToDefendersLeader = defendersLeaderPosition and (defendersLeaderPosition - rootPosition).Magnitude
				or nil,
			defendersLeaderDistanceToObjective = closestDefendersObjectiveToLeaderDistance,
		}
	)
	controller:updateTime(cfg.core.endTime - workspace:GetServerTimeNow(), cfg.core.timeFrozen)
	controller:toggleLock(state.state == "locked")
end
packets.statusUpdate.listen(function(data)
	for key, value in pairs(data) do
		state[key] = value
	end
	updateState()
end)
packets.partialStatusUpdate.listen(function(data)
	for _, value in data do
		state[value.stateKey] = value.stateValue
	end
	updateState()
end)
game.ReplicatedStorage:WaitForChild("OmegasTerminalConfig_Persistant").AttributeChanged:Connect(function()
	updateSettings()
	updateState()
end)
updateSettings()
updateState()

local s = 0
runService.RenderStepped:Connect(function(dt)
	s += dt
	if s >= 1 / 10 then
		s = 0
		if cfg.core.started == true then
			updateState()
		end
	end
end)
