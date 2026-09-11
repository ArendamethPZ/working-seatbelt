WorkingSeatbelt = WorkingSeatbelt or {}

-- DAMAGES
----------------------------------------------------------------------
function WorkingSeatbelt.getBodyPartsHealth(character)
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

function WorkingSeatbelt.getBodyPartsHealthReduction(table1, table2, character)
    local damageReduction = 0
    local type = character:getModData().Seatbelt_reductionType
    if type == "seatbelt" then
        damageReduction = SandboxVars.workingSeatbelt.seatbeltDamageReduction / 100
    elseif type == "airbag" then
        if SandboxVars.workingSeatbelt.airbagsAffectedByCondition then
            local vehicle = character:getVehicle()
            if vehicle then
                local seat = vehicle:getSeat(character)

                local airbagPart = WorkingSeatbelt.getAirbagPart(seat, vehicle)
                local airbagCondition
                if airbagPart then
                    airbagCondition = airbagPart:getCondition()
                end

                damageReduction = (SandboxVars.workingSeatbelt.airbagDamageReduction / 100) * (airbagCondition / 100)
            end
        else
            damageReduction = SandboxVars.workingSeatbelt.airbagDamageReduction / 100
        end
        character:getModData().Seatbelt_crashDamage = nil
    else
        local airbagDamageReduction
        if SandboxVars.workingSeatbelt.airbagsAffectedByCondition then
            local vehicle = character:getVehicle()
            if vehicle then
                local seat = vehicle:getSeat(character)

                local airbagPart = WorkingSeatbelt.getAirbagPart(seat, vehicle)
                local airbagCondition
                if airbagPart then
                    airbagCondition = airbagPart:getCondition()
                end

                airbagDamageReduction = (SandboxVars.workingSeatbelt.airbagDamageReduction / 100) *
                    (airbagCondition / 100)
            end
        else
            airbagDamageReduction = SandboxVars.workingSeatbelt.airbagDamageReduction / 100
        end
        character:getModData().Seatbelt_crashDamage = nil

        local seatbeltDamageReduction = SandboxVars.workingSeatbelt.seatbeltDamageReduction / 100
        local damageReduction = seatbeltDamageReduction + airbagDamageReduction
        if damageReduction > 1 then
            damageReduction = 1
        end
    end

    local newBodyPartsHealth = {}
    for key, value in pairs(table1) do
        local valueFromTable2 = table2[key]

        if value ~= valueFromTable2 then
            local damage = value - valueFromTable2
            local reducedDamage = damage * damageReduction
            local newPartHealth = valueFromTable2 + reducedDamage
            newBodyPartsHealth[key] = newPartHealth
        end
    end
    Events.OnTick.Add(WorkingSeatbelt.onTickWatchBPHealth)

    return newBodyPartsHealth
end

-- FRACTURES
----------------------------------------------------------------------
function WorkingSeatbelt.getBodyPartsFractures(character)
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

function WorkingSeatbelt.getBodyPartsFracturesReduction(table1, table2, character)
    local fracturesReduction = 0
    local type = character:getModData().Seatbelt_reductionType
    if type == "seatbelt" then
        fracturesReduction = SandboxVars.workingSeatbelt.seatbeltFractureReduction / 100
    elseif type == "airbag" then
        if SandboxVars.workingSeatbelt.airbagsAffectedByCondition then
            local vehicle = character:getVehicle()
            if vehicle then
                local seat = vehicle:getSeat(character)

                local airbagPart = WorkingSeatbelt.getAirbagPart(seat, vehicle)
                local airbagCondition
                if airbagPart then
                    airbagCondition = airbagPart:getCondition()
                end

                fracturesReduction = (SandboxVars.workingSeatbelt.airbagFractureReduction / 100) *
                    (airbagCondition / 100)
            end
        else
            fracturesReduction = SandboxVars.workingSeatbelt.airbagFractureReduction / 100
        end
        character:getModData().Seatbelt_crashDamage = nil
    elseif type == "both" then
        local airbagFractureReduction
        if SandboxVars.workingSeatbelt.airbagsAffectedByCondition then
            local vehicle = character:getVehicle()
            if vehicle then
                local seat = vehicle:getSeat(character)

                local airbagPart = WorkingSeatbelt.getAirbagPart(seat, vehicle)
                local airbagCondition
                if airbagPart then
                    airbagCondition = airbagPart:getCondition()
                end

                airbagFractureReduction = (SandboxVars.workingSeatbelt.airbagFractureReduction / 100) *
                    (airbagCondition / 100)
            end
        else
            airbagFractureReduction = SandboxVars.workingSeatbelt.airbagFractureReduction / 100
        end
        character:getModData().Seatbelt_crashDamage = nil

        local seatbeltFractureReduction = SandboxVars.workingSeatbelt.seatbeltFractureReduction / 100
        local fracturesReduction = seatbeltFractureReduction + airbagFractureReduction
        if fracturesReduction > 1 then
            fracturesReduction = 1
        end
    end

    local newBodyPartsFractures = {}
    for key, value in pairs(table1) do
        local valueFromTable2 = table2[key]

        if value ~= valueFromTable2 then
            local fractureTimeDifference = valueFromTable2 - value
            local reducedFractureTime = fractureTimeDifference * fracturesReduction
            local newFractureTime = valueFromTable2 - reducedFractureTime
            newBodyPartsFractures[key] = newFractureTime
        end
    end
    Events.OnTick.Add(WorkingSeatbelt.onTickWatchBPFractures)
    character:getModData().Seatbelt_reductionType = nil

    return newBodyPartsFractures
end

-- MISC FUNCTIONS
----------------------------------------------------------------------
-- Checks if player is wearing a seatbelt
function WorkingSeatbelt.isWearingSeatbelt(character)
    if character:getModData().Seatbelt_sbStatus then return true else return false end
end

-- Gets the airbag part in a vehicle depending on the seat
function WorkingSeatbelt.getAirbagPart(seat, vehicle)
    local part = nil

    if seat == 0 then
        part = vehicle:getPartById("AirbagFrontLeft")
    elseif seat == 1 then
        part = vehicle:getPartById("AirbagFrontRight")
    end

    return part
end

--Helper functions to detect when an engine starts
----------------------------------------------------------------------
WorkingSeatbelt.checkSuccess = false
WorkingSeatbelt.checkStartTime = 0

local old_ISStartVehicleEngine_perform = ISStartVehicleEngine.perform
function ISStartVehicleEngine:perform(...)
    old_ISStartVehicleEngine_perform(self, ...)

    local character = getPlayer()
    local vehicle = character:getVehicle()

    if not vehicle then return end

    WorkingSeatbelt.checkSuccess = false
    WorkingSeatbelt.checkStartTime = 0
    Events.OnTick.Remove(WorkingSeatbelt.checkEngine)

    WorkingSeatbelt.checkStartTime = getTimestamp()
    Events.OnTick.Add(WorkingSeatbelt.checkEngine)
end

local old_ISShutOffVehicleEngine_perform = ISShutOffVehicleEngine.perform
function ISShutOffVehicleEngine:perform(...)
    old_ISShutOffVehicleEngine_perform(self, ...)

    local character = getPlayer()
    local vehicle = character:getVehicle()

    if not vehicle then return end

    if SandboxVars.workingSeatbelt.seatbeltWarningIndicator then
        -- Hide the seatbelt indicator when the engine stops
        ISVehicleDashboard.sbTex:setVisible(false)
    end

    if SandboxVars.workingSeatbelt.seatbeltWarningChime then
        -- Stop the chime sound
        if vehicle:getEmitter():isPlaying("Chime") then
            vehicle:getEmitter():stopSoundByName("Chime")
        end
    end
end

function WorkingSeatbelt.checkEngine()
    if WorkingSeatbelt.checkSuccess or getTimestamp() - WorkingSeatbelt.checkStartTime > 5 then
        WorkingSeatbelt.checkSuccess = false
        WorkingSeatbelt.checkStartTime = 0
        Events.OnTick.Remove(WorkingSeatbelt.checkEngine)
        return
    end

    local character = getPlayer()
    local vehicle = character:getVehicle()
    if not vehicle or not vehicle:isDriver(character) then return end

    if vehicle:isEngineRunning() then
        WorkingSeatbelt.onEngineStart(vehicle)
        WorkingSeatbelt.checkSuccess = true
    end
end

local function onKeyStartPressed(key)
    if key ~= getCore():getKey("Forward") then return end

    local character = getPlayer()
    if not character then return end

    local vehicle = character:getVehicle()
    if not vehicle then return end

    if not vehicle:isDriver(character) then return end
    if vehicle:isEngineRunning() then return end

    WorkingSeatbelt.checkSuccess = false
    WorkingSeatbelt.checkStartTime = 0
    Events.OnTick.Remove(WorkingSeatbelt.checkEngine)

    WorkingSeatbelt.checkStartTime = getTimestamp()
    Events.OnTick.Add(WorkingSeatbelt.checkEngine)
end

Events.OnKeyStartPressed.Add(onKeyStartPressed)

function WorkingSeatbelt.getSeatbeltChimeState(vehicle)
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
