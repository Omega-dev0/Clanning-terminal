local components = {}

type terminalState = "locked" | "neutral" | "attackers" | "defenders"
type terminal = any

--[[
	Updates the attacker and defender points for a terminal based on the state of its subterminals.

	@param terminal table: The terminal object containing current points, configuration, and subterminals.
	@param tickRate number: The rate at which points are updated (ticks per second).
	@return table: A table containing the updated attackerPoints and defenderPoints.

	The function iterates through all subterminals of the given terminal. For each subterminal:
	  - If its state is "attackers", attacker points are increased and defender points may be rolled back.
	  - If its state is "defenders", defender points are increased and attacker points may be rolled back.
	Points are clamped between 0 and the configured maximum.
]]
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

--[[
	Calculates and returns the number of attackers and defenders currently present in a specified zone.

	@param terminal terminal: The terminal object containing configuration and team information.
	@param subterminal any: The subterminal object, used to identify the specific zone.
	@param tickRate number: The tick rate used to increment the "TimeOnObjective" attribute for each player.

	@return { attackesCount: number, defendersCount: number }
		A table containing the count of attackers and defenders in the zone:
			- attackersCount: Number of players on the attackers team in the zone.
			- defendersCount: Number of players on the defenders team in the zone.

	Notes:
	- Only players with a valid character, humanoid, and positive health are counted.
	- Team membership is determined by comparing the player's Team property to the configured attackers and defenders teams.
]]
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

--- Computes and returns the current state of a subterminal within a domination terminal.
-- The state can be "locked", "attackers", "defenders", or "neutral" based on the subterminal's
-- capture progress and configuration.
-- @param terminal table The terminal object containing configuration data.
-- @param subterminal table The subterminal object with state and capture progress information.
-- @return string The computed state: "locked", "attackers", "defenders", or "neutral".
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

--- Updates the capture progress of a subterminal based on the number of attackers and defenders.
--
-- The function increments or decrements the capture progress depending on the presence of attackers or defenders.
-- If both are absent and `uncaptureIfEmpty` is enabled in the terminal's config, the progress will decay towards zero.
-- The progress is clamped between `-captureTime` and `captureTime` as defined in the terminal's config.
--
-- @param terminal table The terminal object containing configuration settings.
-- @param subterminal table The subterminal object with current capture progress and player counts.
-- @param tickRate number The rate at which the capture progress should be updated (ticks per second).
-- @return number The updated capture progress value.
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

--- Determines the winner of the domination terminal game based on current points and time left.
-- @param terminal table The terminal object containing attackerPoints, defenderPoints, config.maxPoints, and timeLeft.
-- @return "attackers"|"defenders"|"draw"|nil Returns "attackers" if attackers reach max points, "defenders" if defenders reach max points,
-- or if time runs out and one side has more points. Returns "draw" if time runs out and points are equal. Returns nil if there is no winner yet.
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
