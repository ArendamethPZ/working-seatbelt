local SharedUtils = require("WorkingSeatbelt_SharedUtils")
local EjectUtils = require("WorkingSeatbelt_EjectUtils")
local ServerCommands = {}

function ServerCommands.deployAirbag(args)
	SharedUtils.playAirbagDeployFeedback(getPlayer())
end

function ServerCommands.ejectPlayer(args)
	EjectUtils.applyEject(getPlayer())
end

local function OnServerCommand(module, command, args)
	if module == 'WorkingSeatbelt' then
		ServerCommands[command](args)
	end
end

Events.OnServerCommand.Add(OnServerCommand)
