---
TIME_LIMIT = 60 -- Minutes

---- visuals configuration
ATTACKERS_GROUP_ID = ""
ATTACKERS_ICON = ""
ATTACKERS_NAME = ""

DEFENDERS_GROUP_ID = ""
DEFENDERS_ICON = ""
DEFENDERS_NAME = ""

--- Admin
local runService = game:GetService("RunService")
function isAdmin(player: Player): boolean
	--Replace this with your method of giving terminal administrator
	local MINIMUM_KHOLS_RANK = 3 -- 3 --> Anyone with khols admin permissions can use the terminal
	if shared._K_INTERFACE ~= nil then
		local rankNumber, rank = shared._K_INTERFACE.Auth.getRank(player.UserId)
		if rankNumber >= MINIMUM_KHOLS_RANK then
			return true
		end
	end

	if script["Group Admin"]["Group admin enabled"].Value == true then
		if
			player:GetRankInGroup(script["Group Admin"]["Group Id"].Value)
			>= script["Group Admin"]["Required minimum group rank"].Value
		then
			return true
		end
	end

	if runService:IsStudio() or player.UserId < 0 or game.GameId == 8177731068 then
		warn(`[TERMINAL] Player ${player.Name} is an admin only because you are in a testing environment`)
		return true
	end
	return false
end

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

	terminalTickRate = 15, -- How many times per second the terminal updates
	isAdmin = isAdmin,
	telemetry = true,
	configVersion = "2.0.0",
}
