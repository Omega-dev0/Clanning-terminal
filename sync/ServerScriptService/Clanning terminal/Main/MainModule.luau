--[DEV](REPLACE:{CORE_VERSION}:){
local VERSION = "v2.1.0"
--}

local REQUIRED_CONFIG_VERSION = "v2.0.1"

script.Wrapper:SetAttribute("version", VERSION)
local wrapper = require(script.Wrapper)
wrapper.VERSION = VERSION
return {
	wrapper = wrapper,
	version = VERSION,
	checkCompatibility = function(configVersion: string): boolean
		local configVersionSplit = string.split(string.gsub(configVersion, "v", ""), ".")
		local configVersionCode = tonumber(configVersionSplit[1]) * 10000
			+ tonumber(configVersionSplit[2]) * 100
			+ tonumber(configVersionSplit[3])

		local versionSplit = string.split(string.gsub(REQUIRED_CONFIG_VERSION, "v", ""), ".")
		local versionCode = tonumber(versionSplit[1]) * 10000
			+ tonumber(versionSplit[2]) * 100
			+ tonumber(versionSplit[3])

		if versionCode == configVersionCode then
			return true
		else
			error(`Incompatible config version: {configVersion}. Expected: {REQUIRED_CONFIG_VERSION}`)
		end
	end,
}
