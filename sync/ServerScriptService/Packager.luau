local version = "v2.1.1"
local folder = game.ServerScriptService["Clanning terminal"]

local exportFolder = Instance.new("Folder")
exportFolder.Name = `Export {version}`
exportFolder.Parent = game.ServerStorage

fullCopy = folder:Clone()
fullCopy.Name = `Full {version}`
fullCopy.Parent = exportFolder

Core = folder.Main:Clone()
Core.Name = `Omega's Terminal Core {version}`
Core.Parent = exportFolder

for _, addon in pairs(folder.Addons:GetChildren()) do
	local addonCopy = addon:Clone()
	addonCopy.Parent = exportFolder
	addonCopy.Name = `{addon.Name} {version}`
end

for _, terminal in pairs(folder.Terminals:GetChildren()) do
	local terminalCopy = terminal:Clone()
	terminalCopy.Parent = exportFolder
	terminalCopy.Name = `{terminal.Name} {version}`
end

print(`Exported Omega's Terminal version {version} successfully !`)

return true
