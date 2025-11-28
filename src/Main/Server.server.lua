--━━━━━━━━━━━━━━━━ INITIALIZATION ━━━━━━━━━━━━━━━━--

local configInstance = script.Parent.Config
configInstance.Name = "OmegasTerminalConfig"
configInstance.Parent = game.ReplicatedStorage

local config = require(configInstance)

mainModule = require(script.Parent.MainModule)

mainModule.checkCompatibility(config.configVersion)
local wrapper = mainModule.wrapper
print(`USING OMEGA'S TERMINAL v{mainModule.version}`)

--━━━━━━━━━━━━━━━━━━━ SERVER ━━━━━━━━━━━━━━━━━━━--
wrapper.Init()
--━━━━━━━━━━━━━━━━━━━ LOAD TERMINAL ━━━━━━━━━━━━━━━━━━━--
wrapper:LoadTerminal(script.Parent.Parent.Terminals["Terminal-Payload"])
--━━━━━━━━━━━━━━━━━━━ LOAD ADDONS ━━━━━━━━━━━━━━━━━━━--
wrapper:AddAddon(wrapper.defaultAddons.UI)
wrapper:AddAddon(wrapper.defaultAddons.Panel)
wrapper:AddAddon(wrapper.defaultAddons.StartSequence)
wrapper:AddAddon(wrapper.defaultAddons.EndSequence)
wrapper:AddAddon(script.Parent.Parent.Addons["Payload-Optimization"])
-- wrapper:AddAddon(script.Parent.Addons.CloudLogging)

--━━━━━━━━━━━━━━━━━━━ INTERACT WITH THE TERMINAL ━━━━━━━━━━━━━━━━━━━--
--wrapper:ToggleDebug(true)
