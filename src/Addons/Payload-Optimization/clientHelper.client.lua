local packets = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("payloadOptimizationPackets"))
local catRom = require(game.ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("CatRom"))
local runService = game:GetService("RunService")

local data = {}

packets.getConfig.listen(function(d)
	data.model = d.model
	data.waypoints = d.waypoints
	data.splineTension = d.splineTension
	data.splineAlpha = d.splineAlpha

	local spline = catRom.new(data.waypoints, data.splineAlpha, data.splineTension)
	spline:PrecomputeUnitSpeedData()
	data.spline = spline
end)

local lastKnownCFrame = nil
local lastKnownProgress = 0
local lastProgressChangeDelta = 0
local lastUpdateTime = tick()
packets.move.listen(function(progress)
	if data.model then
		progress = progress / 100
		local newCFrame = data.spline:SolveCFrameLookAlong(progress / 100)
		lastKnownCFrame = newCFrame
		lastProgressChangeDelta = progress - lastKnownProgress
		lastKnownProgress = progress
		lastUpdateTime = tick()
		--data.model:SetPrimaryPartCFrame(newCFrame)
	end
end)

runService.Heartbeat:Connect(function()
	if data.model and lastKnownCFrame then
		local primary = data.model.PrimaryPart
		if primary then
			local now = tick()
			local elapsed = now - lastUpdateTime
			local baseSpeed = 10
			if lastProgressChangeDelta and lastProgressChangeDelta > 0 then
				baseSpeed = math.max(baseSpeed, lastProgressChangeDelta * 100)
			end

			local alpha = math.clamp(elapsed * baseSpeed, 0, 1)
			local blended = primary.CFrame:Lerp(lastKnownCFrame, alpha)
			data.model:SetPrimaryPartCFrame(blended)
		end
	end
end)

while true do
	if data.model == nil then
		packets.requestConfig.send()
	end
	task.wait(1)
	-- Waiting for stuff like streaming enabled
end
