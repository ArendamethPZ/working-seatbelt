local SharedUtils = {}

---@param character IsoPlayer
function SharedUtils.isWearingSeatbelt(character)
    if character:getModData().Seatbelt_sbStatus then
        return true
    else
        return false
    end
end

---@param character IsoPlayer
function SharedUtils.fastenSeatbelt(character)
    character:getModData().Seatbelt_sbStatus = true
    character:transmitModData()
end

---@param character IsoPlayer
function SharedUtils.unfastenSeatbelt(character)
    character:getModData().Seatbelt_sbStatus = false
    character:transmitModData()
end

---@param vehicle BaseVehicle
function SharedUtils.getSeatbeltChimeState(vehicle)
    local enginePart = vehicle:getPartById("Engine")

    if not enginePart then return end

    local seatbeltChimeState = enginePart:getModData().Seatbelt_sbChimeStatus
    local vehicleId = vehicle:getId()

    if seatbeltChimeState == nil then
        sendClientCommand('WorkingSeatbelt', 'setChimeState', { vehicleId = vehicleId, state = true })
        return true
    else
        return seatbeltChimeState
    end
end

---@param character IsoPlayer
function SharedUtils.playAirbagDeployFeedback(character)
    local vars = SandboxVars.workingSeatbelt

    character:getEmitter():playSound("Airbag")
    if vars.airbagDeploymentAlert then
        character:Say(getText("IGUI_PlayerSayDeployAirbag"))
    end
end

---@param character IsoPlayer
---@param vehicle   BaseVehicle
function SharedUtils.deployAirbag(character, vehicle)
    if not isClient() and not isServer() then
        SharedUtils.playAirbagDeployFeedback(character)
    else
        sendServerCommand(character, 'WorkingSeatbelt', 'deployAirbag', {})
    end

    local part1 = vehicle:getPartById("AirbagFrontLeft")
    local part2 = vehicle:getPartById("AirbagFrontRight")

    if part1 then
        part1:setInventoryItem(nil)
        vehicle:transmitPartItem(part1)
    end

    if part2 then
        part2:setInventoryItem(nil)
        vehicle:transmitPartItem(part2)
    end
end

return SharedUtils
