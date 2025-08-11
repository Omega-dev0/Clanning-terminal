--━━━━━━━━━━━━━━━━ INITIALIZATION ━━━━━━━━━━━━━━━━--

local config = require(script.Parent.Config)

local mainModule
if config.autoUpdateEnabled then
	mainModule = require(config.moduleId)
else
	mainModule = require(script.Parent.MainModule)
end

mainModule.checkCompatibility(config.configVersion)
local wrapper = mainModule.wrapper
print(`USING OMEGA'S TERMINAL v{mainModule.version}`)

--━━━━━━━━━━━━━━━━ TESTING ━━━━━━━━━━━━━━━━--
local testing = true

--━━━━━━━━━━━━━━━━━━━ SERVER ━━━━━━━━━━━━━━━━━━━--

wrapper.Init()
if testing then
	print(wrapper)
	wrapper.config.attackers.team = game.Teams.Attackers
	wrapper.config.defenders.team = game.Teams.Defenders
	script.Parent.Parent.Terminals.Default.Configuration["Terminal volume"].Value = workspace.PointA
end

wrapper:LoadTerminal(script.Parent.Parent.Terminals.Default)

wrapper:AddAddon(wrapper.defaultAddons.Panel)
wrapper:AddAddon(wrapper.defaultAddons.UI)
wrapper:AddAddon(wrapper.defaultAddons.StartSequence)
wrapper:AddAddon(wrapper.defaultAddons.EndSequence)

if testing then
	print(wrapper)
end
