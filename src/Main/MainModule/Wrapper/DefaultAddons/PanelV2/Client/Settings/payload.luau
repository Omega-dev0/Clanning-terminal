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

		attackersSpeed = {
			label = `Forward speed <font color="rgb(99,99,99)">(studs/sec)</font>`,
			type = "text",
			value = cfg.terminal.attackersSpeed,
			validation = function(value)
				return tonumber(value) ~= nil
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 2,
		},

		defendersSpeed = {
			label = `Rollback speed <font color="rgb(99,99,99)">(pts/sec)</font>`,
			type = "text",
			value = cfg.terminal.defendersSpeed,
			validation = function(value)
				return tonumber(value) ~= nil
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 3,
		},

		rollbackCooldown = {
			label = `Rollback Timeout <font color="rgb(99,99,99)">(sec)</font>`,
			type = "text",
			value = cfg.terminal.rollbackCooldown,
			validation = function(value)
				return tonumber(value) ~= nil and tonumber(value) >= 0
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 4,
		},
	}
end
