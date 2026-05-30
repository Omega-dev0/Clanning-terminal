local components = {}

type terminalState = "locked" | "neutral" | "attackers" | "defenders"
type terminal = any

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
