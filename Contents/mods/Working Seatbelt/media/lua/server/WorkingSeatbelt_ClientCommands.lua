local Commands = {}

function Commands.deployAirbag(args)
    local part = nil
    local vehicle = getVehicleById(args.charVehicleId)

    if args.charSeat == 0 then
        part = vehicle:getPartById("AirbagFrontLeft")
    elseif args.charSeat == 1 then
        part = vehicle:getPartById("AirbagFrontRight")
    end

    if part then
        part:setInventoryItem(nil)
    end
    vehicle:transmitPartItem(part)
end

function Commands.setChimeState(args)
    local vehicle = getVehicleById(args.vehicleId)
    local part = vehicle:getPartById("Engine") --We fetch an unremoveable part to store the vehicle name in, since vehicles do not have moddata to store the name

    part:getModData().Seatbelt_sbChimeStatus = args.state
    vehicle:transmitPartModData(part)
end

local function OnClientCommand(module, command, player, args)
    if module == 'WorkingSeatbelt' then
        Commands[command](args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)
