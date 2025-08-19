local components = {}

type terminalState = "locked" | "neutral" | "attackers" | "defenders"
type terminal = any

function components.reachFinish(terminal, subterminal, team: "attackers" | "defenders")
	if team == "attackers" then
		terminal.attackerPoints = terminal.attackerPoints + 1
	elseif team == "defenders" then
		terminal.defenderPoints = terminal.defenderPoints + 1
	end

	subterminal.progress = 0
	subterminal.lastCaptureProgress = 0
	subterminal.attackersCount = 0
	subterminal.defendersCount = 0
	subterminal.state = "neutral"
end

function components.getPlayerCount(terminal: terminal, subterminal: any, tickRate: number)
	local zone = subterminal.zone
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
		AttackersCount = attackersCount,
		DefendersCount = defendersCount,
	}
end

function components.computeState(terminal: terminal, subterminal): terminalState
	if subterminal.state == "locked" then
		return "locked"
	end

	if subterminal.attackersCount <= 0 and subterminal.defendersCount <= 0 then
		return "neutral"
	end

	if subterminal.attackersCount > subterminal.defendersCount then
		return "attackers"
	elseif subterminal.defendersCount > subterminal.attackersCount then
		return "defenders"
	elseif terminal.config.defendersAdvantage == true and subterminal.defendersCount >= subterminal.attackersCount then
		return "defenders"
	end

	return "neutral"
end

function components.updateProgress(terminal: terminal, subterminal: any, tickRate: number): number
	local newProgress = subterminal.progress
	if subterminal.state == "locked" then
		return newProgress
	end

	if subterminal.state == "attackers" then
		local bonusProgress = math.clamp(subterminal.attackersCount, 0, terminal.config.maxAdditionalPlayers)
			* terminal.config.additionalPlayerSpeed
		local additionnalProgress = (bonusProgress + terminal.config.progressSpeed) * (1 / tickRate)
		newProgress = math.clamp(newProgress + additionnalProgress, -1, 1)
	elseif subterminal.state == "defenders" then
		local bonusProgress = math.clamp(subterminal.defendersCount, 0, terminal.config.maxAdditionalPlayers)
			* terminal.config.additionalPlayerSpeed
		local additionnalProgress = (bonusProgress + terminal.config.progressSpeed) * (1 / tickRate)
		newProgress = math.clamp(newProgress - additionnalProgress, -1, 1)
	end

	return newProgress
end

function components.getWinner(terminal): "attackers" | "defenders" | "draw" | nil
	if terminal.attackerPoints >= terminal.config.maxPoints then
		return "attackers"
	elseif terminal.defenderPoints >= terminal.config.maxPoints then
		return "defenders"
	end
	return nil
end

function components.getRequiredProgress(terminal): number
	local DECREASE_PER_OVERTIME_SECOND = 0.005 -- end is closer by 0.5% / second overtime

	if terminal.timeLeft >= 0 then
		return 1
	end

	return math.max(1 - math.abs(terminal.timeLeft) * DECREASE_PER_OVERTIME_SECOND, 0)
end

return components
