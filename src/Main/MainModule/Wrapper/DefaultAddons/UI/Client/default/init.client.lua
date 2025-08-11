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
	captureProgress = 0, -- -100 to 100
	attackerPoints = 0,
	defenderPoints = 0,
	attackersCount = 0,
	defendersCount = 0,
	state = "locked", -- "neutral", "locked", "attackers", "defenders"
}
function updateState()
	local isContested = (state.attackersCount > 0 and state.defendersCount > 0)
	controller:updateState(
		state.attackersCount,
		state.defendersCount,
		state.attackerPoints / cfg.terminal.maxPoints,
		state.defenderPoints / cfg.terminal.maxPoints,
		state.attackerPoints,
		state.defenderPoints,
		isContested,
		state.state,
		cfg.terminal.maxPoints,
		state.captureProgress / cfg.terminal.captureTime
	)
	controller:toggleLock(state.state == "locked")
end
packets.statusUpdate.listen(function(data)
	state = data
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
	if s >= 1 / 30 then
		s = 0
		if cfg.core.started == true then
			controller:updateTime(cfg.core.endTime - workspace:GetServerTimeNow(), cfg.core.timeFrozen)
		end
	end
end)
