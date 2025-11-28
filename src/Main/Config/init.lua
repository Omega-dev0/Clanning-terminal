--━━━━━━━━━━━━━━━━━━━ CONFIGURATION ━━━━━━━━━━━━━━━━━━━--
TIME_LIMIT = 60 -- Minutes

--━━━━━━━━━━━━━━━━━━━ VISUALS ━━━━━━━━━━━━━━━━━━━--
ATTACKERS_GROUP_ID = ""
ATTACKERS_ICON = "http://www.roblox.com/asset/?id=129380584721400"
ATTACKERS_NAME = "Raiders"

DEFENDERS_GROUP_ID = ""
DEFENDERS_ICON = "http://www.roblox.com/asset/?id=100248212164824"
DEFENDERS_NAME = "Defenders"
--━━━━━━━━━━━━━━━━━━━ TECHNICAL ━━━━━━━━━━━━━━━━━━━--

-- How many times per second the terminal updates
-- Higher --> More precision but greater network usage
-- Lower --> Less precision but lower network usage
TERMINAL_TICK_RATE = 20

--━━━━━━━━━━━━━━━━━━━ ADMINISTRATION ━━━━━━━━━━━━━━━━━━━--
local MINIMUM_KHOLS_RANK = 3 -- 3 --> Anyone with khols admin permissions can use the terminal

local runService = game:GetService("RunService")
--[[
Determines whether the given player should be considered an administrator for
the terminal system.

Edit this function to add custom admin checks as needed.

Parameters:
- player (Player): The Player instance to evaluate.

Returns:
- boolean: true if the player is considered an admin by any of the checks;
  false otherwise.
]]
function isAdmin(player: Player): boolean
	-- Khol's admin integration
	if shared._K_INTERFACE ~= nil then
		local rankNumber, rank = shared._K_INTERFACE.Auth.getRank(player.UserId)
		if rankNumber >= MINIMUM_KHOLS_RANK then
			return true
		end
	end

	-- Group admin
	if script["Group Admin"]["Group admin enabled"].Value == true then
		if
			player:GetRankInGroup(script["Group Admin"]["Group Id"].Value)
			>= script["Group Admin"]["Required minimum group rank"].Value
		then
			return true
		end
	end

	-- Testing environment admin
	if runService:IsStudio() or player.UserId < 0 or game.GameId == 8177731068 then
		warn(`[TERMINAL] Player ${player.Name} is an admin only because you are in a testing environment`)
		return true
	end
	return false
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━--
return {

	timeLimit = TIME_LIMIT,

	attackers = {
		groupId = ATTACKERS_GROUP_ID,
		icon = ATTACKERS_ICON,
		name = ATTACKERS_NAME,
		team = script["Attackers Team"].Value,
	},

	defenders = {
		groupId = DEFENDERS_GROUP_ID,
		icon = DEFENDERS_ICON,
		name = DEFENDERS_NAME,
		team = script["Defenders Team"].Value,
	},

	terminalTickRate = TERMINAL_TICK_RATE, -- How many times per second the terminal updates
	isAdmin = isAdmin,
	telemetry = true,
	configVersion = "2.0.0",
}
