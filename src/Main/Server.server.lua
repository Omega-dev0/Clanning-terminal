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

wrapper:LoadTerminal(script.Parent.Parent.Terminals.Tug)
wrapper:AddAddon(script.Parent.Parent.Addons["Tug-UI"])
wrapper:AddAddon(script.Parent.Parent.Addons["Tug-Panel"])
wrapper:AddAddon(script.Parent.Parent.Addons["Tug-Visuals"])
wrapper:AddAddon(wrapper.defaultAddons.StartSequence)
wrapper:AddAddon(wrapper.defaultAddons.EndSequence)

--wrapper:AddAddon(script.Parent.Parent.Addons.CloudLogging)
