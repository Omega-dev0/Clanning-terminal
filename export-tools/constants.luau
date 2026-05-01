local constants = {
	CORE_VERSION = `local VERSION = "v2.1.0"`,
	UI_VERSION = `local VERSION = "v1.1"`,
	END_SEQUENCE_VERSION = `local VERSION = "v1.1"`,
	PANEL_V2_VERSION = `local VERSION = "v2.0"`,
	START_SEQUENCE_VERSION = `local VERSION = "v1.1"`,

	TestString = "--Test",
}

return constants

--[[
--[DEV](REPLACE:--Test:){
if game.ServerScriptService:FindFirstChild("DevTest") ~= nil then
	require(game.ServerScriptService.DevTest)()
end
--}

--[DEV](DELETE){
if game.ServerScriptService:FindFirstChild("DevTest") ~= nil then
	require(game.ServerScriptService.DevTest)
end
--}

--[DEV](REPLACE:{TestString}:){
if game.ServerScriptService:FindFirstChild("DevTest") ~= nil then
	require(game.ServerScriptService.DevTest)()
end
--}

]]
