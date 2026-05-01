local config = game.ReplicatedStorage:WaitForChild("OmegasTerminalConfig_Persistant") :: Configuration
local httpService = game:GetService("HttpService")

return function()
	local cfg = {
		core = httpService:JSONDecode(config:GetAttribute("core_config")),
		terminal = httpService:JSONDecode(config:GetAttribute("terminal_config")),
		properties = httpService:JSONDecode(config:GetAttribute("properties")),
	}

	return {
		timeLimit = {
			label = "Time Limit (minutes)",
			type = "text",
			value = cfg.core.timeLimit,
			validation = function(value)
				return tonumber(value) ~= nil and tonumber(value) > 0
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 1,
		},

		maxPoints = {
			label = `Max Points <font color="rgb(99,99,99)">(pts)</font>`,
			type = "text",
			value = cfg.terminal.maxPoints,
			validation = function(value)
				return tonumber(value) ~= nil and tonumber(value) > 0
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 2,
		},

		leaderKilledPoints = {
			label = `Points on leader kill <font color="rgb(99,99,99)">(pts)</font>`,
			type = "text",
			value = cfg.terminal.leaderKilledPoints,
			validation = function(value)
				return tonumber(value) ~= nil
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 3,
		},

		safezoneReachedPoints = {
			label = `Points on safe zone reached <font color="rgb(99,99,99)">(pts)</font>`,
			type = "text",
			value = cfg.terminal.safezoneReachedPoints,
			validation = function(value)
				return tonumber(value) ~= nil
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 4,
		},

		hudAlwaysOnTop = {
			label = `XRAY on leader`,
			type = "bool",
			value = cfg.terminal.hudAlwaysOnTop,
			order = 5,
		},

		leaderSpeedDebuff = {
			label = `Leader speed debuff <font color="rgb(99,99,99)">% of base speed</font>`,
			type = "text",
			value = cfg.terminal.leaderSpeedDebuff,
			validation = function(value)
				return tonumber(value) ~= nil
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 6,
		},
	}
end
