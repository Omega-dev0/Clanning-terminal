local components = {}

type terminalState = "locked" | "neutral" | "attackers" | "defenders"
type terminal = any

--- Determines the winner.
-- @param terminal object.
-- @return "attackers" if attackers have won,
--         "defenders" if defenders have won,
--         "draw" if it's a draw,
--         nil if no side has won yet.
function components.getWinner(terminal): "attackers" | "defenders" | "draw" | nil
	if terminal.attackerPoints >= tonumber(terminal.config.maxPoints) then
		return "attackers"
	elseif terminal.defenderPoints >= tonumber(terminal.config.maxPoints) then
		return "defenders"
	end

	if terminal.timeLeft <= 0 then
		if terminal.attackerPoints > terminal.defenderPoints then
			return "attackers"
		elseif terminal.defenderPoints > terminal.attackerPoints then
			return "defenders"
		else
			return "draw"
		end
	end

	return nil
end

function components.applyDebufs(terminal, leader: Player)
	local speedDebuff = tonumber(terminal.config.leaderSpeedDebuff)
	if speedDebuff then
		local character = leader.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:SetAttribute("OmegasTerminal_OriginalWalkSpeed", humanoid.WalkSpeed)
				humanoid.WalkSpeed = humanoid.WalkSpeed * (1 - speedDebuff / 100)
			end
		end
	end
end

function components.applyMarker(terminal, leader: Player)
	local highlight = Instance.new("Highlight")
	highlight.Name = "OmegasTerminalMarker"
	highlight.Adornee = leader.Character
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0.5
	highlight.OutlineColor = Color3.new(0, 0, 0)
	highlight.Parent = leader.Character

	if terminal.config.hudAlwaysOnTop then
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	else
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	end
end

function components.selectStart(terminal, starts)
	local index = math.random(1, #starts)
	return starts[index]
end

function components.safeZoneReached(terminal, team: "attackers" | "defenders")
	for _, player: Player in pairs(game.Players:GetPlayers()) do
		if player.Team == (team == "attackers" and terminal.config.attackersTeam or terminal.config.defendersTeam) then
			local character = player.Character
			if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
				task.spawn(function()
					player:LoadCharacterAsync()
				end)
			end
		end
	end
end

return components
