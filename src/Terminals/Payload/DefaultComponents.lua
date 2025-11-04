local components = {}

type terminalState = "locked" | "neutral" | "attackers" | "defenders"
type terminal = any

--- Updates the attacker and defender points based on the terminal's state and configuration.
-- @param terminal The terminal object.
-- @param tickRate The rate at which the terminal is updated.
-- @return A table containing:

function components.updateProgress(terminal: terminal, tickRate: number): { newProgress: number }
	local newProgress = terminal.progress

	if terminal.state == "attackers" then
		newProgress += terminal.config.attackersSpeed / tickRate
	elseif terminal.state == "defenders" then
		if (os.clock() - terminal.lastMoved) >= terminal.config.rollbackCooldown then
			newProgress -= terminal.config.defendersSpeed / tickRate
		end
	end

	if newProgress < 0 then
		newProgress = 0
	end

	if newProgress > 100 then
		newProgress = 100
	end

	return {
		progress = newProgress,
	}
end

function components.movePayloadModel(terminal: terminal)
	-- Move payload
end

--- Calculates the number of attackers and defenders currently present in the terminal's zone.
-- @param terminal The terminal object.
-- @return A table containing:
--   - AttackersCount (number): The count of players on the attacker team.
--   - DefendersCount (number): The count of players on the defender team.
function components.getPlayerCount(
	terminal: terminal,
	tickRate: number
): { AttackersCount: number, DefendersCount: number }
	local playersInZone = terminal.config.zone:GetPlayersInZone()
	local attackersCount = 0
	local defendersCount = 0
	for _, player in pairs(playersInZone) do
		if player.Character == nil or player.Character.Humanoid == nil or player.Character.Humanoid.Health <= 0 then
			continue
		end

		if player:FindFirstChild("OmegaStats") then
			player.OmegaStats:SetAttribute(
				"TimeOnObjective",
				player.OmegaStats:GetAttribute("TimeOnObjective") + 1 / tickRate
			)
		end

		if player.Team == terminal.config.attackersTeam then
			attackersCount = attackersCount + 1
		elseif player.Team == terminal.config.defendersTeam then
			defendersCount = defendersCount + 1
		end
	end
	return {
		attackersCount = attackersCount,
		defendersCount = defendersCount,
	}
end

--- Computes and returns the current state of the terminal based on its properties.
-- @param terminal The terminal object.
-- @return terminalState The computed state of the terminal ("locked", "attackers", "defenders", or "neutral").
function components.computeState(terminal: terminal): terminalState
	if terminal.state == "locked" then
		return "locked"
	end

	if terminal.attackersCount > 0 and terminal.defendersCount == 0 then
		return "attackers"
	elseif terminal.defendersCount > 0 and terminal.attackersCount == 0 then
		return "defenders"
	else
		return "neutral"
	end
end

--- Determines the winner.
-- @param terminal object.
-- @return "attackers" if attackers have won,
--         "defenders" if defenders have won,
--         "draw" if it's a draw,
--         nil if no side has won yet.
function components.getWinner(terminal): "attackers" | "defenders" | "draw" | nil
	if terminal.progress >= 100 then
		return "attackers"
	end

	if terminal.timeLeft <= 0 then
		return "defenders"
	end

	return nil
end

return components
