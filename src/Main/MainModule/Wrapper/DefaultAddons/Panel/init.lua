local panelAddon = {}
local packets = require(game.ReplicatedStorage:WaitForChild("Libraries"):FindFirstChild("OmegasTerminalPackets"))
panelAddon.Libraries = script.Libraries:GetChildren()
panelAddon.metadata = {
	name = "Terminal Panel",
	description = "The default terminal progress panel addon",
	version = "v1.2",
	author = "Omega77073",
	compatibility = ">=2.0.1",
}
panelAddon.id = "default-terminalPanel"

local groupService = game:GetService("GroupService")

panelAddon.init = function(wrapper)
	local config = wrapper.config
	local detectGroup = require(script.groupDetect)

	-- Group lock
	local groupLocks = {
		server = false,
		attackers = false,
		defenders = false,
	}
	wrapper.properties.groupLocks = groupLocks
	wrapper.updatePersistantConfig()

	game.Players.PlayerAdded:Connect(function(player)
		if groupLocks.server == false then
			return
		end

		local attackersId, defendersId = config.attackers.groupId, config.defenders.groupId

		local attackersRank = player:GetRankInGroup(attackersId)

		if attackersRank > 0 then
			return
		end

		local defendersRank = player:GetRankInGroup(defendersId)
		if defendersRank > 0 then
			return
		end

		local attackersInfo, defendersInfo
		if attackersId ~= nil and attackersId ~= 0 and attackersId ~= "" then
			attackersInfo = groupService:GetGroupInfoAsync(attackersId)
		end
		if defendersId ~= nil and defendersId ~= 0 and defendersId ~= "" then
			defendersInfo = groupService:GetGroupInfoAsync(defendersId)
		end

		local message
		if attackersInfo ~= nil and defendersInfo ~= nil then
			message =
				`[SERVER LOCK] - You must be in either the {attackersInfo.Name} or {defendersInfo.Name} group to join this server.`
		elseif attackersInfo ~= nil and defendersInfo == nil then
			message = `[SERVER LOCK] - You must be in the {attackersInfo.Name} group to join this server.`
		elseif attackersInfo == nil and defendersInfo ~= nil then
			message = `[SERVER LOCK] - You must be in the {defendersInfo.Name} group to join this server.`
		else
			message = `[SERVER LOCK] - Server locked for everyone`
		end

		player:Kick(message)
	end)

	local playerTeams = {}
	local attackersTeam: Team, defendersTeam: Team = config.attackers.team, config.defenders.team
	for _, team in pairs(game.Teams:GetTeams()) do
		team.PlayerAdded:Connect(function(player: Player)
			if team == attackersTeam then
				if groupLocks.attackers == false then
					return
				end

				local attackersId = config.attackers.groupId
				if attackersId == nil or attackersId == 0 or attackersId == "" then
					return
				end
				local rank = player:GetRankInGroup(attackersId)
				if rank > 0 then
					return
				end

				local lastTeam = playerTeams[player.UserId]
				if lastTeam ~= nil then
					player.Team = lastTeam
					player:LoadCharacterAsync()
				else
					player.Neutral = true
					player:LoadCharacterAsync()
				end
				return
			end

			if team == defendersTeam then
				if groupLocks.defenders == false then
					return
				end

				local defendersId = config.defenders.groupId
				if defendersId == nil or defendersId == 0 or defendersId == "" then
					return
				end
				local rank = player:GetRankInGroup(defendersId)
				if rank > 0 then
					return
				end

				local lastTeam = playerTeams[player.UserId]
				if lastTeam ~= nil then
					player.Team = lastTeam
					player:LoadCharacterAsync()
				else
					player.Neutral = true
					player:LoadCharacterAsync()
				end
				return
			end

			playerTeams[player.UserId] = team
		end)
	end

	packets.action.listen(function(data, player)
		local actionKeys = string.split(data.action, "_")
		if not config.isAdmin(player) then
			return
		end
		if actionKeys[1] == "modifyConfig" then
			if data.data.panel ~= nil then
				groupLocks.server = data.data.panel.groupLocks.server
				groupLocks.attackers = data.data.panel.groupLocks.attackers and wrapper.config.attackers.groupId ~= nil
				groupLocks.defenders = data.data.panel.groupLocks.defenders and wrapper.config.defenders.groupId ~= nil
				wrapper.properties.groupLocks = groupLocks
				wrapper.updatePersistantConfig()
			end

			data.data.panel = nil
			local mergedConfig = data.data.core
			for key, value in pairs(data.data.terminal) do
				mergedConfig[key] = value
			end
			wrapper.controls:modifyConfig(mergedConfig, player)
			wrapper.updatePersistantConfig()
		elseif actionKeys[1] == "detectGroup" then
			local team = data.data
			local teamObject, bannedGroups
			if team == "attackers" then
				teamObject = wrapper.config.attackers.team
				bannedGroups = wrapper.config.defenders.groupId and { wrapper.config.defenders.groupId } or {}
			elseif team == "defenders" then
				teamObject = wrapper.config.defenders.team
				bannedGroups = wrapper.config.attackers.groupId and { wrapper.config.attackers.groupId } or {}
			end

			local detectedGroupId = detectGroup(teamObject, bannedGroups)
			if detectedGroupId == nil then
				return
			end
			local groupInfo = groupService:GetGroupInfoAsync(detectedGroupId)
			if detectedGroupId ~= nil then
				if team == "attackers" then
					wrapper.config.attackers.groupId = detectedGroupId
					wrapper.config.attackers.name = groupInfo.Name
					wrapper.config.attackers.icon = groupInfo.EmblemUrl
				elseif team == "defenders" then
					wrapper.config.defenders.groupId = detectedGroupId
					wrapper.config.defenders.name = groupInfo.Name
					wrapper.config.defenders.icon = groupInfo.EmblemUrl
				end
			end

			wrapper.updatePersistantConfig()
		elseif actionKeys[1] == "control" then
			local controlType = actionKeys[2]
			local controls = {
				freezeTime = function()
					wrapper.controls:FreezeTime(player)
				end,
				unfreezeTime = function()
					wrapper.controls:UnfreezeTime(player)
				end,
				addTime = function(amount)
					wrapper.controls:AddTime(amount, player)
				end,
				removeTime = function(amount)
					wrapper.controls:AddTime(-amount, player)
				end,

				addProgress = function(team, progress)
					wrapper.controls:AddProgress(team, progress, player)
				end,
				removeProgress = function(team, progress)
					wrapper.controls:AddProgress(team, -progress, player)
				end,

				lockTerminal = function()
					wrapper.controls:Lock(player)
				end,
				unlockTerminal = function()
					wrapper.controls:Unlock(player)
				end,

				reset = function()
					wrapper.controls:Reset(player)
				end,

				stop = function()
					wrapper.controls:Stop(player)
				end,

				start = function()
					wrapper.controls:Start(player, 5)
				end,
			}

			if controls[controlType] then
				if data.data ~= nil then
					controls[controlType](table.unpack(data.data))
				else
					controls[controlType]()
				end
			else
				error("Invalid control type: " .. tostring(controlType))
			end
		end
	end)

	local terminalId = wrapper.terminal.terminalId
	local client = script.Client:FindFirstChild(terminalId)
	if client == nil then
		error(`Could not find a panel client for terminal id: {terminalId}`)
	end
	client.Name = "Terminal Panel Client"
	client:SetAttribute("terminalId", terminalId)
	client.Parent = game.StarterPlayer.StarterPlayerScripts
end

return panelAddon
