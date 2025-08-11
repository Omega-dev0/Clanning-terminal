local httpService = game:GetService("HttpService")

local REPORTING_URL = "https://terminal.omegadev.xyz/api/telemetry"

return function(version, wrapper)
	pcall(function()
		task.wait(10)
		if game:GetService("RunService"):IsStudio() then
			return -- Do not send telemetry in Studio
		end
		local availableAddons = {}
		for id, addon in pairs(wrapper.Addons) do
			table.insert(availableAddons, {
				id = id,
				metadata = addon.metadata or {},
			})
		end

		local telemetryData = {
			version = version,

			gameId = game.PlaceId,
			ownerId = game.CreatorId,
			ownerType = game.CreatorType,

			isPrivateServer = game.PrivateServerId ~= nil,

			addons = availableAddons,
		}

		httpService:PostAsync(
			REPORTING_URL,
			httpService:JSONEncode(telemetryData),
			Enum.HttpContentType.ApplicationJson
		)
	end)
end
