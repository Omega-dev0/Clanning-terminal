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
			label = "Max Points",
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

		pointsPerSecond = {
			label = `Points Per Second <font color="rgb(99,99,99)">(pts/sec)</font>`,
			type = "text",
			value = cfg.terminal.pointsPerSecond,
			validation = function(value)
				return tonumber(value) ~= nil
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 3,
		},

		captureTime = {
			label = `Capture Time <font color="rgb(99,99,99)">(sec)</font>`,
			type = "text",
			value = cfg.terminal.captureTime,
			validation = function(value)
				return tonumber(value) ~= nil and tonumber(value) >= 0
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 4,
		},

		rollbackRate = {
			label = `Rollback Rate <font color="rgb(99,99,99)">(pts/sec)</font>`,
			type = "text",
			value = cfg.terminal.rollbackRate,
			validation = function(value)
				return tonumber(value) ~= nil
			end,
			transform = function(value)
				return tonumber(value)
			end,
			order = 5,
		},

		uncaptureIfEmpty = {
			label = "Uncapture If Empty",
			type = "bool",
			value = cfg.terminal.uncaptureIfEmpty,
			order = 6,
		},
	}
end
