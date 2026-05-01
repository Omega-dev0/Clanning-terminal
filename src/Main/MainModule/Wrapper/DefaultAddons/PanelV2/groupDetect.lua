local defaultBannedGrounps = {
	2879885,
	4705120,
	2782840,
	3333298,
	2919215,
	3959677,
	13751258,
	16403616,
	4052729,
	11221055,
	4430841,
	15740178,
	7165738,
	4217910,
	2969540,
	32421331,
	5357344,
	9137704,
	4851134,
	9825692,
	7064117,
	6206549,
	3751488,
	3996161,
	8296978,
	6039961,
	5916008,
	2703304,
	34287998,
	35728656,
	35987925,
	3250407,
	35864728,
	33895697,
	7224788,
	32572102,
	3642592,
	5054561,
	15422038,
	5606884,
	15333610,
	9821921,
	15491373,
	4345585,
	5435520,
	35669818,
	295182,
	32617906,
	3084988,
	5019929,
	14728016,
	5243967,
	34310410,
	32398494,
	4256796,
	8014500,
	35533537,
	14301117,
	10200322,
	1103278,
	17006949,
	32060932,
	5502618,
	15038333,
	2861387,
	8938953,
	4413376,
	3797636,
	15746664,
	16976426,
	11486256,
	3461453,
	17329583,
	2757866,
	33742248,
	3127877,
	4372156,
	10692800,
	7064117,
	4527672,
	4413248,
	42,
	7171078,
	3333239,
	33328015,
	3127877,
	9137704,
	4372156,
	10692800,
	7064117,
	2846853,
	7171078,
	3333239,
	7230215,
	2919215,
	3336691,
	34671275,
	1127093,
	14765325,
	2910593,
	3127877,
	4372156,
	9137704,
	4527672,
	4972845,
	16869981,
	6602131,
	3336691,
	7087315,
	2747190,
	7286093,
	5615790,
	4384658,
	9332075,
	32495473,
	3132013,
	6455602,
	5728104,
	7080250,
	9895392,
	3190544,
	9842323,
	8667673,
	13104578,
	15565234,
	17131238,
	6235152,
	5863339,
	15933961,
	33796637,
	3991521,
	1123655,
	35673499,
	35868640,
	36042291,
	982331068,
	4491593,
	35812225,
	6770993,
	10026748,
	14576965,
	2908951,
	12463875,
	9828157,
	2748390,
	35325835,
	14616309,
	3883261,
	7674505,
	4368670,
	9166214,
	3116598,
	12992705,
	35814365,
	15980663,
	12641764,
	14670168,
	5930624,
	5549669,
	34472290,
	33994843,
	33936621,
	2816074,
	34702127,
	16194159,
	15799480,
	17339092,
	10250462,
	4981455,
	10004870,
	5247037,
	8894936,
	3529061,
	8282028,
	33271191,
	35404073,
	7081575,
	5170894,
	16201023,
	15102943,
	4824074,
	10378649,
	3955051,
	35878863,
	3755133,
	17028435,
	11867394,
	8159009,
	16984635,
	7343218,
	33824728,
	16095415,
	11886490,
	36075983,
	4914494,
	32595931,
	13780860,
	4000776,
	16460559,
	34827124,
	14683539,
	8200754,
	5693735,
	2956297,
	5522949,
	3389812,
	7931439,
	2752198,
	4789890,
	7270687,
	5112430,
	2814928,
	8528180,
	6129662,
	7594081,
	3811860,
	7549191,
	9568292,
	5446074,
	4721032,
	9613219,
	33259677,
	12656141,
	5013735,
	33170678,
	3510718,
	33648009,
	15952277,
	9645632,
	10703387,
}
local groupService = game:GetService("GroupService")
local function detectGroup(team: Team, bannedGroups: { number })
	local bannedGroupsSet = {}
	for _, groupId in ipairs(bannedGroups) do
		bannedGroupsSet[groupId] = true
	end
	for _, groupId in ipairs(defaultBannedGrounps) do
		bannedGroupsSet[groupId] = true
	end

	local totalGroups = {}
	local tasks = {}
	if #team:GetPlayers() == 0 then
		return nil
	end
	for _, player in ipairs(team:GetPlayers()) do
		local c = coroutine.create(function()
			local groups = groupService:GetGroupsAsync(player.UserId)
			for _, groupData in ipairs(groups) do
				if bannedGroupsSet[groupData.Id] ~= true then
					if totalGroups[groupData.Id] == nil then
						totalGroups[groupData.Id] = 0
					end
					totalGroups[groupData.Id] = totalGroups[groupData.Id] + 1
				end
			end
		end)
		table.insert(tasks, c)
	end

	for _, c in ipairs(tasks) do
		coroutine.resume(c)
	end

	local timeout = os.time() + 15
	while task.wait(0.1) do
		local allDone = true
		for _, c in ipairs(tasks) do
			if coroutine.status(c) ~= "dead" then
				allDone = false
				break
			end
		end
		if allDone then
			break
		end

		if os.time() > timeout then
			break
		end
	end
	if next(totalGroups) == nil then
		return nil
	end
	local topGroupId = nil
	for groupId, count in pairs(totalGroups) do
		if topGroupId == nil or count > totalGroups[topGroupId] then
			topGroupId = groupId
		end
	end

	return topGroupId
end

return detectGroup
