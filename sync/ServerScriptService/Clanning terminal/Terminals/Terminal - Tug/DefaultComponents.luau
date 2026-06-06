local components = {}

type terminalState = "locked" | "neutral" | "attackers" | "defenders"
type terminal = any

function components.reachFinish(terminal, subterminal, team: "attackers" | "defenders")
	print("Reach finish", team)
	if team == "attackers" then
		terminal.attackerPoints = terminal.attackerPoints + 1
	elseif team == "defenders" then
		terminal.defenderPoints = terminal.defenderPoints + 1
	end
	terminal:Reset(false)
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
		attackersCount = attackersCount,
		defendersCount = defendersCount,
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
		local bonusProgress = math.clamp(subterminal.attackersCount - 1, 0, terminal.config.maxAdditionalPlayers)
			* terminal.config.additionalPlayerSpeed
		local additionnalProgress = (bonusProgress + terminal.config.progressSpeed) * (1 / tickRate)
		newProgress = math.clamp(newProgress + additionnalProgress, -1, 1)
	elseif subterminal.state == "defenders" then
		local bonusProgress = math.clamp(subterminal.defendersCount - 1, 0, terminal.config.maxAdditionalPlayers)
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

function components.getNewZoneCFrame(terminal, subterminalName): CFrame
	local subterminal = terminal.terminals[subterminalName]
	local attackersCFrame = terminal.config[subterminalName].attackersCFrame
	local defendersCFrame = terminal.config[subterminalName].defendersCFrame
	local progress = (subterminal.progress + 1) / 2 --- [0, 1]

	local newCFrame = defendersCFrame:Lerp(attackersCFrame, progress)
	return newCFrame
end
return components
