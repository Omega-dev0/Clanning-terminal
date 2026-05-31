local Addon = {}

-- To add more zones, simply add an Object value as children pointing to the desired zone
local zoneParts = {}
for _, obj in ipairs(script.Configuration:GetChildren()) do
	if obj:IsA("ObjectValue") then
		table.insert(zoneParts, obj.Value)
	end
end

Addon.Libraries = { script.basicZones }
Addon.metadata = {
	name = "Hardpoint",
	description = "Turns the default terminal into a hardpoint terminal by switching the terminal's zone",
	version = "v1.1",
	author = "Omega77073",
	compatibility = ">=2.0.0",
}
--e
Addon.id = "default-hardpoint"
Addon.init = function(wrapper)
	local configInstance = script.Configuration
	local isRandom, switchTime = configInstance:GetAttribute("is_random"), configInstance:GetAttribute("switch_time")
	local objectiveMarker = script.ObjectiveMarker

	local zones = {}
	for _, part in ipairs(zoneParts) do
		local zone = require(script.basicZones).fromPart(part)
		table.insert(zones, zone)
	end

	local function switchZone(index)
		if wrapper.terminal.state == "locked" then
			return
		end
		print(`[HARDPOINT ADDON] - Switching to zone {index}...`)
		local selectedZone = zones[index]
		wrapper.terminal.config.zone = selectedZone
		objectiveMarker.CFrame = selectedZone.CFrame
		objectiveMarker.Parent = workspace

		wrapper.terminal.captureProgress = 0

		for _, zone in pairs(zones) do
			if zone ~= selectedZone then
				zone:_visualize(false)
			else
				zone:_visualize(wrapper.terminal.debugEnabled)
			end
		end
	end

	local currentZoneIndex = 1
	wrapper.terminal.events.startEvent.Event:Connect(function()
		switchZone(currentZoneIndex)

		local connection = game:GetService("RunService").Heartbeat:Connect(function()
			local currentTime = workspace:GetServerTimeNow()
			local endTime = wrapper.endTime

			local remainingTime = endTime - currentTime
			local currentIndex = math.floor(remainingTime / switchTime) % #zones + 1
			if currentIndex ~= currentZoneIndex then
				if isRandom then
					local newIndex = currentZoneIndex
					while newIndex == currentZoneIndex do
						newIndex = math.random(1, #zones)
					end
					currentZoneIndex = currentIndex
					switchZone(newIndex)
				else
					currentZoneIndex = ((currentIndex - 1) % #zones) + 1
					switchZone(currentZoneIndex)
				end
			end
		end)

		s = wrapper.terminal.events.endEvent.Event:Connect(function()
			connection:Disconnect()
			s:Disconnect()
		end)
	end)
end

return Addon
