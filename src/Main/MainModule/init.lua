local VERSION = "1.2.0"

script.Wrapper:SetAttribute("version", VERSION)
return {
	wrapper = require(script.Wrapper),
	version = VERSION,
	checkCompatibility = function(configVersion: string): boolean
		local majorVersion, mediumVersion, smallVersion = table.unpack(string.split(configVersion, "."))
		majorVersion, mediumVersion, smallVersion =
			tonumber(majorVersion), tonumber(mediumVersion), tonumber(smallVersion)
		if majorVersion == 1 and mediumVersion == 2 and smallVersion >= 0 then
			return true
		else
			error(`Incompatible config version: {configVersion}. Expected >= {VERSION}`)
		end
	end,
}
