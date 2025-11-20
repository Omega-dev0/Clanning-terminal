local VERSION = "2.0.0"

script.Wrapper:SetAttribute("version", VERSION)
local wrapper = require(script.Wrapper)
wrapper.VERSION = VERSION
return {
	wrapper = wrapper,
	version = VERSION,
	checkCompatibility = function(configVersion: string): boolean
		local configVersionSplit = string.split(configVersion, ".")
		local configVersionCode = tonumber(configVersionSplit[1]) * 10000
			+ tonumber(configVersionSplit[2]) * 100
			+ tonumber(configVersionSplit[3])

		local versionSplit = string.split(VERSION, ".")
		local versionCode = tonumber(versionSplit[1]) * 10000
			+ tonumber(versionSplit[2]) * 100
			+ tonumber(versionSplit[3])

		if versionCode >= configVersionCode then
			return true
		else
			error(`Incompatible config version: {configVersion}. Expected >= {VERSION}`)
		end
	end,
}
