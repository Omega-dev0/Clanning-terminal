---- Core configuration
AUTO_UPDATE_CORE = false
MAIN_MODULE_ID = ""

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

	if script.GroupAdmin.GroupAdmin_Enabled.Value == true then
		if player:GetRankInGroup(script.GroupAdmin.GroupId.Value) >= script.GroupAdmin.MinimumGroupRank.Value then
			return true
		end
	end

	if runService:IsStudio() then
		return true
	end
	return false
end

return {
	autoUpdateEnabled = AUTO_UPDATE_CORE,
	moduleId = MAIN_MODULE_ID,

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

	terminalTickRate = 15,
	isAdmin = isAdmin,
	telemetry = true,
	configVersion = "1.2.0",
}
