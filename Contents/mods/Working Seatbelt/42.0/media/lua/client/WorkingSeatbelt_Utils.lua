local WorkingSeatbelt = require("WorkingSeatbelt")
local Utils = {}

-- Helper functions to detect when an engine starts
--- -------------------------------------------------------------------
WorkingSeatbelt.checkSuccess = false
WorkingSeatbelt.checkStartTime = 0

local old_ISStartVehicleEngine_perform = ISStartVehicleEngine.perform
function ISStartVehicleEngine:perform(...)
    old_ISStartVehicleEngine_perform(self, ...)

    local character = getPlayer()
    if not character then return end
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
    if not character then return end
    local vehicle = character:getVehicle()

    if not vehicle then return end

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
    if not character then return end
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

return Utils
