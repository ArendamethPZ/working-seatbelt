local WorkingSeatbelt = require("WorkingSeatbelt")
local SharedUtils = require("WorkingSeatbelt_SharedUtils")

WorkingSeatbelt.lastCheck = 0
local function onTick()
    local character = getPlayer()
    if not character then return end
    local vehicle = character:getVehicle()
    if not vehicle then return end
    if getTimestamp() == WorkingSeatbelt.lastCheck then return end

    if not vehicle:getPartById("Engine") then return end

    if SandboxVars.workingSeatbelt.seatbeltWarningChime then
        if SharedUtils.getSeatbeltChimeState(vehicle) then
            local fullName = vehicle:getScript():getFullName()
            if not WorkingSeatbelt.seatbeltBlacklist[fullName] then
                if vehicle:isEngineRunning() then
                    if vehicle:isDriver(character) then
                        local speed = vehicle:getCurrentSpeedKmHour()
                        if speed >= SandboxVars.workingSeatbelt.chimeMinimumSpeed then
                            if not SharedUtils.isWearingSeatbelt(character) then
                                if not vehicle:getEmitter():isPlaying("Chime") then
                                    vehicle:getEmitter():playSoundImpl("Chime", IsoObject.new())
                                end
                            end
                        else
                            if vehicle:getEmitter():isPlaying("Chime") then
                                vehicle:getEmitter():stopSoundByName("Chime")
                            end
                        end
                    end
                end
            end
        end
    end
    WorkingSeatbelt.lastCheck = getTimestamp()
end

Events.OnTick.Add(onTick)
