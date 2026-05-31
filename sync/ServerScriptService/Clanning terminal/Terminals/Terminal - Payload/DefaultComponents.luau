local components = {}

type terminalState = "locked" | "neutral" | "attackers" | "defenders"
type terminal = any

--- Updates the attacker and defender points based on the terminal's state and configuration.
-- @param terminal The terminal object.
-- @param tickRate The rate at which the terminal is updated.
-- @return A table containing:

function components.updateProgress(terminal: terminal, tickRate: number): { newProgress: number }
	local newProgress = terminal.progress

	if terminal.locks.targetProgress ~= nil and math.abs(terminal.locks.targetProgress - newProgress) < 0.01 then
		terminal.locks.targetProgress = nil
	end

	if terminal.locks.targetProgress ~= nil then
		if newProgress < tonumber(terminal.locks.targetProgress) then
			newProgress += math.min(
				((tonumber(terminal.config.attackersSpeed) / tonumber(terminal.config.pathLength)) / tickRate) * 100,
				tonumber(terminal.locks.targetProgress) - newProgress
			)

			if newProgress > tonumber(terminal.locks.targetProgress) then
				terminal.locks.targetProgress = nil
			end
		elseif newProgress > tonumber(terminal.locks.targetProgress) then
			newProgress -= math.min(
				((tonumber(terminal.config.defendersSpeed) / tonumber(terminal.config.pathLength)) / tickRate) * 100,
				newProgress - tonumber(terminal.locks.targetProgress)
			)

			if newProgress < tonumber(terminal.locks.targetProgress) then
				terminal.locks.targetProgress = nil
			end
		end
	else
		if terminal.state == "attackers" then
			newProgress += ((tonumber(terminal.config.attackersSpeed) / tonumber(terminal.config.pathLength)) / tickRate) * 100
		else
			if (os.clock() - terminal.lastMoved) >= tonumber(terminal.config.rollbackCooldown) then
				newProgress -= ((tonumber(terminal.config.defendersSpeed) / tonumber(terminal.config.pathLength)) / tickRate) * 100
			end
		end
	end

	if newProgress < tonumber(terminal.locks.minimumProgress) then
		newProgress = tonumber(terminal.locks.minimumProgress)
	end

	if newProgress > tonumber(terminal.locks.maximumProgress) then
		newProgress = tonumber(terminal.locks.maximumProgress)
	end

	return {
		progress = newProgress,
	}
end

function components.movePayloadModel(terminal: terminal, newCFrame: CFrame, newProgress: number?)
	terminal.config.payloadModel:SetPrimaryPartCFrame(newCFrame)
	-- You might want to change that to optimize for performance
	-- You can use the Payload-Optimization addon for that
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

function components.activateWaypoint(terminal: terminal, waypointIndex: number)
	local waypoint = terminal.config.waypointsInstances[waypointIndex]
	-- Could do something there aswell
end

return components
