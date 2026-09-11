local SharedUtils = require("WorkingSeatbelt_SharedUtils")
local ServerUtils = {}

function ServerUtils.getBodyPartsHealth(character)
    local bodyParts = character:getBodyDamage():getBodyParts()
    local bodyPartsHealth = {} -- Create a new table to store body parts health

    for i = 1, bodyParts:size() do
        local bp = bodyParts:get(i - 1)
        local bodyPartType = bp:getType()
        local bodyPartHealth = bp:getHealth()

        -- Insert body part type as key and its health as value into the table
        bodyPartsHealth[bodyPartType] = bodyPartHealth
    end

    return bodyPartsHealth -- Return the table containing body parts health
end

function ServerUtils.getBodyPartsFractures(character)
    local bodyParts = character:getBodyDamage():getBodyParts()
    local bodyPartsFractures = {} -- Create a new table to store body parts fracture time

    for i = 1, bodyParts:size() do
        local bp = bodyParts:get(i - 1)
        local bodyPartType = bp:getType()
        local fractureTime = bp:getFractureTime()

        bodyPartsFractures[bodyPartType] = fractureTime
    end

    return bodyPartsFractures
end

-- Computes and applies health reduction to a character's damaged body parts.
-- snapshotHealth: table of body part health values taken BEFORE the crash damage was applied.
-- reductionType: "seatbelt" | "airbag" | "both"
function ServerUtils.applyHealthReduction(character, snapshotHealth, reductionType)
    local currentHealth = character:getBodyDamage():getHealth()

    -- If player is dead, do not do anything. (Otherwise, it'll REALLY bug him out)
    if currentHealth <= 0 then return end

    local damageReduction = 0

    if reductionType == "seatbelt" then
        damageReduction = SandboxVars.workingSeatbelt.seatbeltDamageReduction / 100
    elseif reductionType == "airbag" then
        if SandboxVars.workingSeatbelt.airbagsAffectedByCondition then
            local vehicle = character:getVehicle()
            if vehicle then
                local seat = vehicle:getSeat(character)
                local airbagPart = ServerUtils.getAirbagPart(seat, vehicle)
                local airbagCondition = airbagPart and airbagPart:getCondition() or 0
                damageReduction = (SandboxVars.workingSeatbelt.airbagDamageReduction / 100) * (airbagCondition / 100)
            end
        else
            damageReduction = SandboxVars.workingSeatbelt.airbagDamageReduction / 100
        end
    elseif reductionType == "both" then
        local airbagDamageReduction = 0
        if SandboxVars.workingSeatbelt.airbagsAffectedByCondition then
            local vehicle = character:getVehicle()
            if vehicle then
                local seat = vehicle:getSeat(character)
                local airbagPart = ServerUtils.getAirbagPart(seat, vehicle)
                local airbagCondition = airbagPart and airbagPart:getCondition() or 0
                airbagDamageReduction = (SandboxVars.workingSeatbelt.airbagDamageReduction / 100)
                    * (airbagCondition / 100)
            end
        else
            airbagDamageReduction = SandboxVars.workingSeatbelt.airbagDamageReduction / 100
        end

        local seatbeltDamageReduction = SandboxVars.workingSeatbelt.seatbeltDamageReduction / 100
        damageReduction = seatbeltDamageReduction + airbagDamageReduction
        if damageReduction > 1 then damageReduction = 1 end
    end

    -- Get the current health of player's body parts (AFTER crash damage was applied).
    local currentBodyPartsHealth = ServerUtils.getBodyPartsHealth(character)

    for key, valueBefore in pairs(snapshotHealth) do
        local valueAfter = currentBodyPartsHealth[key]

        if valueAfter and valueBefore ~= valueAfter then
            local damage = valueBefore - valueAfter
            local reducedDamage = damage * damageReduction
            local newPartHealth = valueAfter + reducedDamage

            local bodyPartType = BodyPartType[tostring(key)]
            character:getBodyDamage():getBodyPart(bodyPartType):SetHealth(newPartHealth)
        end
    end
end

-- Computes and applies fracture time reduction to a character's damaged body parts.
-- snapshotFractures: table of body part fracture times taken BEFORE the crash damage was applied.
-- reductionType: "seatbelt" | "airbag" | "both"
function ServerUtils.applyFractureReduction(character, snapshotFractures, reductionType)
    local currentHealth = character:getBodyDamage():getHealth()

    -- If player is dead, do not do anything. (Otherwise, it'll REALLY bug him out)
    if currentHealth <= 0 then return end

    local fracturesReduction = 0

    if reductionType == "seatbelt" then
        fracturesReduction = SandboxVars.workingSeatbelt.seatbeltFractureReduction / 100
    elseif reductionType == "airbag" then
        if SandboxVars.workingSeatbelt.airbagsAffectedByCondition then
            local vehicle = character:getVehicle()
            if vehicle then
                local seat = vehicle:getSeat(character)
                local airbagPart = ServerUtils.getAirbagPart(seat, vehicle)
                local airbagCondition = airbagPart and airbagPart:getCondition() or 0
                fracturesReduction = (SandboxVars.workingSeatbelt.airbagFractureReduction / 100)
                    * (airbagCondition / 100)
            end
        else
            fracturesReduction = SandboxVars.workingSeatbelt.airbagFractureReduction / 100
        end
    elseif reductionType == "both" then
        local airbagFractureReduction = 0
        if SandboxVars.workingSeatbelt.airbagsAffectedByCondition then
            local vehicle = character:getVehicle()
            if vehicle then
                local seat = vehicle:getSeat(character)
                local airbagPart = ServerUtils.getAirbagPart(seat, vehicle)
                local airbagCondition = airbagPart and airbagPart:getCondition() or 0
                airbagFractureReduction = (SandboxVars.workingSeatbelt.airbagFractureReduction / 100)
                    * (airbagCondition / 100)
            end
        else
            airbagFractureReduction = SandboxVars.workingSeatbelt.airbagFractureReduction / 100
        end

        local seatbeltFractureReduction = SandboxVars.workingSeatbelt.seatbeltFractureReduction / 100
        fracturesReduction = seatbeltFractureReduction + airbagFractureReduction
        if fracturesReduction > 1 then fracturesReduction = 1 end
    end

    -- Get the current fracture times of player's body parts (AFTER crash damage was applied).
    local currentBodyPartsFractures = ServerUtils.getBodyPartsFractures(character)

    for key, valueBefore in pairs(snapshotFractures) do
        local valueAfter = currentBodyPartsFractures[key]

        if valueAfter and valueBefore ~= valueAfter then
            local fractureTimeDifference = valueAfter - valueBefore
            local reducedFractureTime = fractureTimeDifference * fracturesReduction
            local newFractureTime = valueAfter - reducedFractureTime

            local bodyPartType = BodyPartType[tostring(key)]
            character:getBodyDamage():getBodyPart(bodyPartType):setFractureTime(newFractureTime)
        end
    end
end

---@param seat    number
---@param vehicle BaseVehicle
function ServerUtils.getAirbagPart(seat, vehicle)
    local part = nil

    if seat == 0 then
        part = vehicle:getPartById("AirbagFrontLeft")
    elseif seat == 1 then
        part = vehicle:getPartById("AirbagFrontRight")
    end

    return part
end

return ServerUtils
