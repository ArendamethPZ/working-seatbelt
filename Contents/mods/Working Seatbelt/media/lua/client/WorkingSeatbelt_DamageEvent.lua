WorkingSeatbelt = WorkingSeatbelt or {}
local vars = SandboxVars.workingSeatbelt

function WorkingSeatbelt.deployAirbag(character, charVehicleId, charSeat)
    character:getEmitter():playSound("Airbag")
    if vars.airbagDeploymentAlert then
        character:Say(getText("IGUI_PlayerSayDeployAirbag"))
    end
    local args =
    {
        charVehicleId = charVehicleId,
        charSeat = charSeat
    }
    sendClientCommand('WorkingSeatbelt', 'deployAirbag', args)

    --Deploy it locally too
    -- local part
    -- local vehicle = getVehicleById(charVehicleId)
    -- if charSeat == 0 then
    --     part = vehicle:getPartById("AirbagFrontLeft")
    -- elseif args.charSeat == 1 then
    --     part = vehicle:getPartById("AirbagFrontRight")
    -- end

    -- if part then
    --     part:setInventoryItem(nil)
    -- end
end

function WorkingSeatbelt.shouldBeEjected(character, vehicle, damage)
    if not vehicle then return false end                                                                                --Player can't be ejected if there's no vehicle in first place
    if not vars.canPlayerBeEjected then return false end                                                                --Player can't be ejected if the sandbox option isn't enabled
    if damage < vars.ejectMinimumCrashStrength then return false end                                                    --Player can't be ejected if damage is less than sandbox setting
    if WorkingSeatbelt.isWearingSeatbelt(character) then return false end                                               --Player can't be ejected if not wearing seatbelt
    if character:getDir() ~= vehicle:getDir() then return false end                                                     --Player can't be ejected if car is going in reverse
    if vehicle:getPartById("Windshield") and vehicle:getPartById("Windshield"):getCondition() > 0 then return false end --Player can't be be ejected if windshield condition is more than 0
    if vehicle:getPartById("Windshield") and vehicle:getPartById("Windshield"):getInventoryItem() then return false end --Player can't be ejected if windshielf is installed

    return true
end

-- Cases for damage reduction:
-- 1- Player is in driver seat (0), is wearing a seatbelt, but no deployable airbag
-- 2- Player is in driver seat (0), is wearing a seatbelt and a deployable airbag
-- 3- Player is in driver seat (0), is NOT wearing a seatbelt, but has a deployable airbag
-- 4- Player is in passenger seat (1), is wearing a seatbelt, but no deployable airbag
-- 5- Player is in passenger seat (1), is wearing a seatbelt, and a deployable airbag
-- 6- Player is in passenger seat (1), is NOT wearing a seatbelt, but has a deployable airbag
-- 7- Player is in back seats (2 or 3) and is wearing a seatbelt

-- Function triggered when the player takes damage.
local function onPlayerGetDamage(character, damageType, damage)
    if damageType == "CARCRASHDAMAGE" then
        local charVehicle = character:getVehicle()
        local charSeat = charVehicle:getSeat(character)
        local reductionType
        local charVehicleId = charVehicle:getId()

        if WorkingSeatbelt.isWearingSeatbelt(character) then
            if vars.airbagModule then
                local airbagPart = WorkingSeatbelt.getAirbagPart(charSeat, charVehicle)
                if airbagPart and not airbagPart:isInventoryItemUninstalled() then
                    if damage >= vars.airbagMinimumCrashStrength then
                        reductionType = "both"
                        WorkingSeatbelt.deployAirbag(character, charVehicleId, charSeat)
                    else
                        reductionType = "seatbelt"
                    end
                else
                    reductionType = "seatbelt"
                end
            else
                reductionType = "seatbelt"
            end

            if vars.seatbeltCausesChestFracture then
                if damage >= vars.chestFractureMinimumCrashStrength then
                    local chance = ZombRand(100)
                    if chance <= vars.chanceChestFracture then
                        character:getBodyDamage():getBodyPart(BodyPartType.Torso_Upper):setFractureTime(vars
                            .chestFractureTime)
                    end
                end
            end
        else
            if vars.airbagModule then
                if charSeat == 0 or charSeat == 1 then
                    local airbagPart = WorkingSeatbelt.getAirbagPart(charSeat, charVehicle)
                    if airbagPart and not airbagPart:isInventoryItemUninstalled() then
                        if damage >= vars.airbagMinimumCrashStrength then
                            reductionType = "airbag"
                            WorkingSeatbelt.deployAirbag(character, charVehicleId, charSeat)
                        end
                    end
                end
            end
        end

        if reductionType then
            -- Stop monitoring the player's body parts health and fractures.
            Events.OnTick.Remove(WorkingSeatbelt.onTickWatchBPHealth)
            Events.OnTick.Remove(WorkingSeatbelt.onTickWatchBPFractures)

            -- Get the player's body's average health before the damage.
            local healthBeforeDamage = character:getBodyDamage():getHealth()
            character:getModData().Seatbelt_healthBeforeDamage = healthBeforeDamage
            character:getModData().Seatbelt_reductionType = reductionType

            -- Start comparing the player's health and fractures before and after damage each tick.
            -- (In order to apply the damage reduction on the next tick, since it can't be applied
            -- on current tick due to script limitations)
            Events.OnTick.Add(WorkingSeatbelt.onTickDamageReduction)
            Events.OnTick.Add(WorkingSeatbelt.onTickFractureReduction)
        end

        if isDebugEnabled() then
            character:Say("Crash Damage: " .. tostring(damage))
        end

        local shouldBeEjected = WorkingSeatbelt.shouldBeEjected(character, charVehicle, damage)
        if shouldBeEjected then
            Events.OnTick.Add(WorkingSeatbelt.ejectPlayer) --For some reason, we can't directly eject the player without it being buggy, so we use onTick instead
        end
    end
end

Events.OnPlayerGetDamage.Add(onPlayerGetDamage)
