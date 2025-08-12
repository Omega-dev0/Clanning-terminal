local components = {}

type terminalState = "locked" | "neutral" | "attackers" | "defenders"
type terminal = any

--- Updates the attacker and defender points for a terminal based on its current state and configuration.
-- @param terminal table: The terminal object.
-- @param tickRate number: The rate at which points are updated (ticks per second).
-- @return table: A table containing the updated attackerPoints and defenderPoints.
function components.updatePoints(
	terminal: terminal,
	tickRate: number
): { attackerPoints: number, defenderPoints: number }
	local newattackerPoints = terminal.attackerPoints
	local newdefenderPoints = terminal.defenderPoints

	for terminalName, subterminal in pairs(terminal.terminals) do
		if subterminal.state == "attackers" then
			newattackerPoints += terminal.config.pointsPerSecond / tickRate
			if newdefenderPoints > 0 then
				newdefenderPoints -= terminal.config.rollbackRate / tickRate
			end
		elseif subterminal.state == "defenders" then
			newdefenderPoints += terminal.config.pointsPerSecond / tickRate
			if newattackerPoints > 0 then
				newattackerPoints -= terminal.config.rollbackRate / tickRate
			end
		end
	end

	if newattackerPoints < 0 then
		newattackerPoints = 0
	end
	if newdefenderPoints < 0 then
		newdefenderPoints = 0
	end
	if newattackerPoints > terminal.config.maxPoints then
		newattackerPoints = terminal.config.maxPoints
	end
	if newdefenderPoints > terminal.config.maxPoints then
		newdefenderPoints = terminal.config.maxPoints
	end

	return {
		attackerPoints = newattackerPoints,
		defenderPoints = newdefenderPoints,
	}
end

--- Calculates the number of attackers and defenders currently present in the terminal's zone.
-- @param terminal The terminal object.
-- @return A table containing:
--   - AttackersCount (number): The count of players on the attacker team.
--   - DefendersCount (number): The count of players on the defender team.
function components.getPlayerCount(
	terminal: terminal,
	subterminal: any,
	tickRate: number
): { AttackersCount: number, DefendersCount: number }
	local zone = terminal.config.terminals[subterminal.name]
	local playersInZone = zone:GetPlayersInZone()
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
function components.computeState(terminal: terminal, subterminal): terminalState
	if subterminal.state == "locked" then
		return "locked"
	end

	if subterminal.captureProgress >= terminal.config.captureTime then
		return "attackers"
	elseif subterminal.captureProgress <= -terminal.config.captureTime then
		return "defenders"
	else
		if subterminal.captureProgress > 0 and subterminal.lastCaptureProgress - subterminal.captureProgress > 0 then
			return "attackers"
		elseif
			subterminal.captureProgress < 0 and subterminal.lastCaptureProgress - subterminal.captureProgress < 0
		then
			return "defenders"
		else
			return "neutral"
		end
	end
end

--- Updates the capture progress of a terminal.
-- @param terminal table Terminal object.
-- @param tickRate number The rate at which progress is updated per tick.
-- @return number The updated capture progress.
function components.updateCaptureProgress(terminal: terminal, subterminal: any, tickRate: number): number
	local newCaptureProgress = subterminal.captureProgress
	local attackersCount, defendersCount = subterminal.attackersCount, subterminal.defendersCount

	if attackersCount > 0 and defendersCount == 0 then
		newCaptureProgress += 1 / tickRate
	elseif defendersCount > 0 and attackersCount == 0 then
		newCaptureProgress -= 1 / tickRate
	elseif attackersCount == 0 and defendersCount == 0 then
		if terminal.config.uncaptureIfEmpty == true then
			if math.abs(newCaptureProgress) < 0.1 then
				newCaptureProgress = 0
			end

			if newCaptureProgress > 0 then
				newCaptureProgress -= (1 / tickRate)
			elseif newCaptureProgress < 0 then
				newCaptureProgress += (1 / tickRate)
			end
		end
	end
	if newCaptureProgress > terminal.config.captureTime then
		newCaptureProgress = terminal.config.captureTime
	elseif newCaptureProgress < -terminal.config.captureTime then
		newCaptureProgress = -terminal.config.captureTime
	end

	return newCaptureProgress
end

--- Determines the winner.
-- @param terminal object.
-- @return "attackers" if attackers have won,
--         "defenders" if defenders have won,
--         "draw" if it's a draw,
--         nil if no side has won yet.
function components.getWinner(terminal): "attackers" | "defenders" | "draw" | nil
	if terminal.attackerPoints >= terminal.config.maxPoints then
		return "attackers"
	elseif terminal.defenderPoints >= terminal.config.maxPoints then
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

return components
