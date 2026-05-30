-- Basic Zones Library
-- Supports Block, Ball, and Cylinder zones
-- v2.0.2 | Omega77073

local zoneFunctions = {}
local module = {}

function module.New(zoneCFrame: CFrame, config)
	local zone = setmetatable({}, { __index = zoneFunctions })
	zone.CFrame = zoneCFrame
	zone.config = config

	-- Rectangle, Sphere, Cylinder
	if config.zoneShape == "Block" then
		zone.Shape = "Block"
		assert(config.corners, "Zone corners not set")
		zone.localSpaceCorners = {}
		for _, corner in pairs(config.corners) do
			table.insert(zone.localSpaceCorners, zone.CFrame:ToObjectSpace(CFrame.new(corner)).Position)
		end
	elseif config.zoneShape == "Ball" then
		zone.Shape = "Ball"
		zone.Radius = config.Radius or 0
		assert(config.Radius, "Zone radius not set")
	elseif config.zoneShape == "Cylinder" then
		zone.Shape = "Cylinder"
		zone.Radius = config.Radius or 0
		zone.maxHeight = config.maxHeight or 0
		assert(config.maxHeight, "Zone height not set")
		assert(config.Radius, "Zone height not set")
	else
		error("Invalid zone shape: " .. tostring(config.zoneShape))
	end

	return zone
end

function module.fromPart(part: BasePart)
	local shape = part.Shape
	if shape == Enum.PartType.Block then
		shape = "Block"
		return module.New(part.CFrame, {
			corners = {
				part.CFrame:ToWorldSpace(CFrame.new(Vector3.new(-part.Size.X / 2, -part.Size.Y / 2, -part.Size.Z / 2))).Position,
				part.CFrame:ToWorldSpace(CFrame.new(Vector3.new(part.Size.X / 2, -part.Size.Y / 2, -part.Size.Z / 2))).Position,
				part.CFrame:ToWorldSpace(CFrame.new(Vector3.new(-part.Size.X / 2, part.Size.Y / 2, -part.Size.Z / 2))).Position,
				part.CFrame:ToWorldSpace(CFrame.new(Vector3.new(part.Size.X / 2, part.Size.Y / 2, -part.Size.Z / 2))).Position,
				part.CFrame:ToWorldSpace(CFrame.new(Vector3.new(-part.Size.X / 2, -part.Size.Y / 2, part.Size.Z / 2))).Position,
				part.CFrame:ToWorldSpace(CFrame.new(Vector3.new(part.Size.X / 2, -part.Size.Y / 2, part.Size.Z / 2))).Position,
				part.CFrame:ToWorldSpace(CFrame.new(Vector3.new(-part.Size.X / 2, part.Size.Y / 2, part.Size.Z / 2))).Position,
				part.CFrame:ToWorldSpace(CFrame.new(Vector3.new(part.Size.X / 2, part.Size.Y / 2, part.Size.Z / 2))).Position,
			},
			zoneShape = shape,
		})
	elseif shape == Enum.PartType.Ball then
		shape = "Ball"
		return module.New(part.CFrame, {
			Radius = math.min(part.Size.X, part.Size.Y, part.Size.Z) / 2,
			zoneShape = shape,
		})
	elseif shape == Enum.PartType.Cylinder then
		shape = "Cylinder"
		local offset = part.CFrame:ToWorldSpace(CFrame.new(Vector3.new(-part.Size.X / 2, 0, 0)))
		local newPosition = part.CFrame.Position + offset.Position
		local newCFrame = CFrame.new(newPosition, part.CFrame.Position + part.CFrame.LookVector)
		return module.New(part.CFrame, {
			Radius = math.min(part.Size.Y, part.Size.Z) / 2,
			maxHeight = part.Size.X,
			zoneShape = shape,
		})
	else
		error("Invalid zone shape: " .. tostring(shape))
	end
end

function zoneFunctions:GetPlayersInZone(): { Player }
	local playersInZone = {}
	for _, player in pairs(game.Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
				if self:IsPointInZone(player.Character.HumanoidRootPart.Position) then
					table.insert(playersInZone, player)
				end
			end
		end
	end
	return playersInZone
end

function zoneFunctions:IsPointInZone(point: Vector3): boolean
	if self.Shape == "Block" then
		local localPosition = self.CFrame:ToObjectSpace(CFrame.new(point)).Position
		local localCorners = self.localSpaceCorners
		local isInX = localPosition.X >= localCorners[1].X and localPosition.X <= localCorners[2].X
		local isInY = localPosition.Y >= localCorners[1].Y and localPosition.Y <= localCorners[3].Y
		local isInZ = localPosition.Z >= localCorners[1].Z and localPosition.Z <= localCorners[5].Z
		return isInX and isInY and isInZ
	elseif self.Shape == "Ball" then
		return (point - self.CFrame.Position).Magnitude <= self.Radius
	elseif self.Shape == "Cylinder" then
		--https://devforum.roblox.com/t/checking-if-a-part-is-in-a-cylinder-but-rotatable/1134952/5
		local radius = self.Radius
		local height = self.maxHeight
		local relative = (point - self.CFrame.Position)

		local sProj = self.CFrame.RightVector:Dot(relative)
		local vProj = self.CFrame.RightVector * sProj
		local len = (relative - vProj).Magnitude

		return len <= radius and math.abs(sProj) <= (height * 0.5)
	end
	return false
end

function zoneFunctions:UpdateCFrame(newCFrame: CFrame)
	self.CFrame = newCFrame
	if self.Shape == "Block" then
		-- Recalculate local space corners
		local newLocalCorners = {}
		for _, corner in pairs(self.config.corners) do
			table.insert(newLocalCorners, self.CFrame:ToObjectSpace(CFrame.new(corner)).Position)
		end
		self.localSpaceCorners = newLocalCorners
	end

	if self.debugPart then
		self.debugPart.CFrame = newCFrame
	end
end

function zoneFunctions:_visualize(enabled: boolean)
	if self.debugPart then
		self.debugPart:Destroy()
		self.debugPart = nil
	end

	if not enabled then
		return
	end

	local part = Instance.new("Part")
	part.Name = "Zone Debug Visualizer"
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0.8
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(0, 255, 0)
	part.CFrame = self.CFrame
	if self.Shape == "Block" then
		local localCorners = self.localSpaceCorners
		local sizeX = math.abs(localCorners[2].X - localCorners[1].X)
		local sizeY = math.abs(localCorners[3].Y - localCorners[1].Y)
		local sizeZ = math.abs(localCorners[5].Z - localCorners[1].Z)
		part.Size = Vector3.new(sizeX, sizeY, sizeZ)
	elseif self.Shape == "Ball" then
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(self.Radius * 2, self.Radius * 2, self.Radius * 2)
	elseif self.Shape == "Cylinder" then
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(self.maxHeight, self.Radius * 2, self.Radius * 2)
	end

	self.debugPart = part
	part.Parent = workspace
	return part
end

return module
