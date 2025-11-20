local debugUtils = {}

function debugUtils.createDisplay(position)
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(20, 0, 10, 0)

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(0, 0, 0)
	textLabel.TextScaled = true
	textLabel.RichText = true
	textLabel.Text = ""
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.Parent = billboardGui

	local supportPart = Instance.new("Part")
	supportPart.Size = Vector3.new(0.1, 0.1, 0.1)
	supportPart.Transparency = 1
	supportPart.Anchored = true
	supportPart.Position = position

	billboardGui.Adornee = supportPart
	billboardGui.Parent = supportPart

	supportPart.Parent = workspace

	return {
		part = supportPart,
		gui = billboardGui,
		label = textLabel,
	}
end

function debugUtils.getColorCodedText(text, color)
	local colorHex =
		string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
	return string.format('<font color="%s">%s</font>', colorHex, text)
end

function debugUtils.formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = math.floor(seconds % 60)
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

return debugUtils
