if isClient() and not isServer() then return end

local Snapshotter = require('WorkingSeatbelt_Snapshotter')
local ServerUtils = require("WorkingSeatbelt_ServerUtils")
local SharedUtils = require("WorkingSeatbelt_SharedUtils")
local EjectUtils = require("WorkingSeatbelt_EjectUtils")

local function onPlayerGetDamage(character, damageType, damage)
    if damageType ~= "CARCRASHDAMAGE" then return end

    Snapshotter.lockSnapshot(character)

    local vars = SandboxVars.workingSeatbelt

    local vehicleId = character:getVehicle():getId()
    local seat = character:getVehicle():getSeat(character)
    local isWearingSeatbelt = SharedUtils.isWearingSeatbelt(character)

    local vehicle = getVehicleById(vehicleId)
    if not vehicle then return end

    -- Determine what protection applies: seatbelt, airbag, both, or none
    local reductionType = nil
    local airbagPart = vars.airbagModule and ServerUtils.getAirbagPart(seat, vehicle) or nil
    local airbagAvailable = airbagPart and not airbagPart:isInventoryItemUninstalled()

    if isWearingSeatbelt then
        if airbagAvailable and damage >= vars.airbagMinimumCrashStrength then
            reductionType = "both"
        else
            reductionType = "seatbelt"
        end

        if vars.seatbeltCausesChestFracture and damage >= vars.chestFractureMinimumCrashStrength then
            if ZombRand(101) <= vars.chanceChestFracture then
                character:getBodyDamage():getBodyPart(BodyPartType.Torso_Upper):setFractureTime(vars.chestFractureTime)
            end
        end
    else
        if airbagAvailable and (seat == 0 or seat == 1) and damage >= vars.airbagMinimumCrashStrength then
            reductionType = "airbag"
        end
    end

    if damage >= vars.airbagMinimumCrashStrength and airbagAvailable then
        SharedUtils.deployAirbag(character, vehicle)
    end

    if reductionType then
        local snapshot = Snapshotter.getSnapshot(character)
        if snapshot then
            ServerUtils.applyHealthReduction(character, snapshot.health, reductionType)
            ServerUtils.applyFractureReduction(character, snapshot.fractures, reductionType)
        end
    end

    Snapshotter.unlockSnapshot(character)
    Snapshotter.clearSnapshot(character)

    if isDebugEnabled() then
        character:Say("Crash Damage: " .. tostring(damage))
    end

    if EjectUtils.shouldBeEjected(character, vehicle, damage) then
        local function doEject()
            Events.OnTick.Remove(doEject)
            EjectUtils.ejectPlayer(character)
        end
        Events.OnTick.Add(doEject)
    end
end

Events.OnPlayerGetDamage.Add(onPlayerGetDamage)
