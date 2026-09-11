local ClientCommands = {}

function ClientCommands.setChimeState(_, args)
    local vehicle = getVehicleById(args.vehicleId)
    local part = vehicle:getPartById("Engine") -- We fetch an unremoveable part to store the vehicle name in, since vehicles do not have moddata to store the name

    part:getModData().Seatbelt_sbChimeStatus = args.state
    vehicle:transmitPartModData(part)
end

local function OnClientCommand(module, command, player, args)
    if module == 'WorkingSeatbelt' then
        ClientCommands[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)
