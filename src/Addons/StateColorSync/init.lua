local Addon = {}

Addon.Libraries = {}
Addon.metadata = {
	name = "State color sync",
	description = "Synchronizes instances color to the terminal's current state",
	version = "v1.1",
	author = "Omega77073",
	compatibility = ">=1.2.0",
}
Addon.id = "stateColorSync"
Addon.init = function(wrapper)
	local colors = {
		neutral = script.Configuration:GetAttribute("neutral_color"),
		attackers = script.Configuration:GetAttribute("attackers_color"),
		defenders = script.Configuration:GetAttribute("defenders_color"),
		locked = script.Configuration:GetAttribute("locked_color"),
	}

	local parents = {}
	for _, instance: Instance in pairs(script.Configuration:GetChildren()) do
		if instance:IsA("ObjectValue") then
			table.insert(parents, instance.Value)
		end
	end

	wrapper.terminal.events.stateChanged.Event:Connect(function(newState)
		local color = colors[newState]
		if color then
			for _, parent in pairs(parents) do
				for _, descendant in pairs(parent:GetDescendants()) do
					if descendant:IsA("BasePart") or descendant:IsA("MeshPart") then
						descendant.Color = color
					elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
						descendant.Color3 = color
					elseif descendant:IsA("ParticleEmitter") then
						descendant.Color = ColorSequence.new(color)
					elseif
						descendant:IsA("PointLight")
						or descendant:IsA("SpotLight")
						or descendant:IsA("Light")
						or descendant:IsA("SurfaceLight")
					then
						descendant.Color = color
					elseif descendant:IsA("Beam") then
						descendant.Color = ColorSequence.new(color)
					end
				end

				if parent:IsA("BasePart") or parent:IsA("MeshPart") then
					parent.Color = color
				elseif parent:IsA("Decal") or parent:IsA("Texture") then
					parent.Color3 = color
				elseif parent:IsA("ParticleEmitter") then
					parent.Color = ColorSequence.new(color)
				elseif
					parent:IsA("PointLight")
					or parent:IsA("SpotLight")
					or parent:IsA("Light")
					or parent:IsA("SurfaceLight")
				then
					parent.Color = color
				elseif parent:IsA("Beam") then
					parent.Color = ColorSequence.new(color)
				end
			end
		end
	end)
end

return Addon
