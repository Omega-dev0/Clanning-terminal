local zoneFunctions = {}
local module = {}

function module.New(zoneCFrame: CFrame, config)
	local zone = setmetatable({}, { __index = zoneFunctions })
	zone.CFrame = zoneCFrame
	zone.Position = zoneCFrame.Position
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
		return (point - self.Position).Magnitude <= self.Radius
	elseif self.Shape == "Cylinder" then
		--https://devforum.roblox.com/t/checking-if-a-part-is-in-a-cylinder-but-rotatable/1134952/5
		local radius = self.Radius
		local height = self.maxHeight
		local relative = (point - self.Position)

		local sProj = self.CFrame.RightVector:Dot(relative)
		local vProj = self.CFrame.RightVector * sProj
		local len = (relative - vProj).Magnitude

		return len <= radius and math.abs(sProj) <= (height * 0.5)
	end
	return false
end

return module
