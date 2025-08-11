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

--━━━━━━━━━━━━━━━━━━━ SERVER ━━━━━━━━━━━━━━━━━━━--

wrapper.Init()

wrapper:LoadTerminal(script.Parent.Parent.Terminals.Default)

wrapper:AddAddon(wrapper.defaultAddons.Panel)
wrapper:AddAddon(wrapper.defaultAddons.UI)
wrapper:AddAddon(wrapper.defaultAddons.StartSequence)
wrapper:AddAddon(wrapper.defaultAddons.EndSequence)
