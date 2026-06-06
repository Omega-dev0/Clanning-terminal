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

		progressSpeed = {
			label = `Progress Speed <font color="rgb(99,99,99)">(%/s)</font>`,
			type = "text",
			value = cfg.terminal.progressSpeed,
			validation = function(value)
				return tonumber(value) ~= nil
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 3,
		},

		additionalPlayerSpeed = {
			label = `Additional Player Speed <font color="rgb(99,99,99)">(%/s/player)</font>`,
			type = "text",
			value = cfg.terminal.additionalPlayerSpeed,
			validation = function(value)
				return tonumber(value) ~= nil
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 4,
		},

		maxAdditionalPlayers = {
			label = `Max Additional Players <font color="rgb(99,99,99)">(#)</font>`,
			type = "text",
			value = cfg.terminal.maxAdditionalPlayers,
			validation = function(value)
				return tonumber(value) ~= nil
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 5,
		},

		defendersAdvantage = {
			label = `Defenders Advantage on contest`,
			type = "bool",
			value = cfg.terminal.defendersAdvantage,
			order = 6,
		},

		lockAfterScoring = {
			label = `Lock After Scoring`,
			type = "bool",
			value = cfg.terminal.lockAfterScoring,
			order = 7,
		},
	}
end
