local httpService = game:GetService("HttpService")

local REPORTING_URL = "https://terminalv2.omegadev.xyz/api/telemetry"

return function(version, wrapper)
	pcall(function()
		task.wait(10)
		if game:GetService("RunService"):IsStudio() then
			return
		end
		local availableAddons = {}
		for id, addon in pairs(wrapper.addons) do
			table.insert(availableAddons, {
				id = id,
				metadata = addon.metadata or {},
			})
		end

		local telemetryCode = httpService:GenerateGUID(false)
		wrapper.properties.telemetryCode = telemetryCode

		local telemetryData = {
			version = version,
			telemetryVersion = 1,

			gameName = wrapper.gameName,

			gameId = game.GameId,
			placeId = game.PlaceId,
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
