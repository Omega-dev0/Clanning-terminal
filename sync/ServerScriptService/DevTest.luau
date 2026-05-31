return function()
	print("Setting dev test config")
	local mainConfig = game.ServerScriptService["Clanning terminal"].Main.Config
	local terminalConfigs = {
		default = game.ServerScriptService["Clanning terminal"].Terminals["Terminal - Default"].Configuration,
		--	ctf = game.ServerScriptService["Clanning terminal"].Terminals["Terminal-CTF"].Configuration,
		domination = game.ServerScriptService["Clanning terminal"].Terminals["Terminal - Domination"].Configuration,
		payload = game.ServerScriptService["Clanning terminal"].Terminals["Terminal - Payload"].Configuration,
		runner = game.ServerScriptService["Clanning terminal"].Terminals["Terminal - Runner"].Configuration,
	}

	mainConfig["Attackers Team"].Value = game.Teams.Attackers
	mainConfig["Defenders Team"].Value = game.Teams.Defenders

	terminalConfigs.default["Terminal volume"].Value = workspace.PointA

	terminalConfigs.payload["Payload model"].Value = workspace.Payload
	terminalConfigs.payload["Waypoints folder"].Value = workspace["Test waypoints"]

	terminalConfigs.domination.Terminals.A.Value = workspace.PointA
	terminalConfigs.domination.Terminals.B.Value = workspace.PointB

	terminalConfigs.runner.Safezones.Attackers.Volume.Value = workspace.Runner.AttackersGoal
	terminalConfigs.runner.Safezones.Defenders.Volume.Value = workspace.Runner.DefendersGoal

	terminalConfigs.runner.Starts.Attackers.Point.Value = workspace.Runner.AttackersCrownSpawn1
	terminalConfigs.runner.Starts.Defenders.Point.Value = workspace.Runner.DefendersCrownSpawn1
end
