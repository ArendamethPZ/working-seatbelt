local SharedUtils = require("WorkingSeatbelt_SharedUtils")
require "TimedActions/ISBaseTimedAction"

ArenSeatbeltTimedAction = ISBaseTimedAction:derive("ArenSeatbeltTimedAction")

function ArenSeatbeltTimedAction:isValid() -- Check if the action can be done. Calls :stop() if false is returned
    return true
end

function ArenSeatbeltTimedAction:start() -- Trigger when the action starts
    self.character:getEmitter():playSound(self.fasten and "seatbelt_fasten" or "seatbelt_unfasten")
end

function ArenSeatbeltTimedAction:stop() -- Trigger if the action is cancelled
    ISBaseTimedAction.stop(self)
end

function ArenSeatbeltTimedAction:perform()
    if self.fasten then
        SharedUtils.fastenSeatbelt(self.character)
    else
        SharedUtils.unfastenSeatbelt(self.character)
    end

    local vehicle = self.character:getVehicle()

    local shouldHandleChime = SandboxVars.workingSeatbelt.seatbeltWarningChime and vehicle
        and SharedUtils.getSeatbeltChimeState(vehicle) and vehicle:isDriver(self.character)
        and vehicle:isEngineRunning()

    if shouldHandleChime then
        if self.fasten then
            if vehicle:getEmitter():isPlaying("Chime") then
                vehicle:getEmitter():stopSoundByName("Chime")
            end
        else
            local speed = vehicle:getCurrentSpeedKmHour()
            if not vehicle:getEmitter():isPlaying("Chime") and speed >= SandboxVars.workingSeatbelt.chimeMinimumSpeed then
                vehicle:getEmitter():playSoundImpl("Chime", IsoObject.new())
            end
        end

        if SandboxVars.workingSeatbelt.seatbeltWarningIndicator then
            ISVehicleDashboard.sbTex:setVisible(not self.fasten)
        end
    end

    ISBaseTimedAction.perform(self)
end

function ArenSeatbeltTimedAction:complete()
    return true
end

function ArenSeatbeltTimedAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 40
end

function ArenSeatbeltTimedAction:new(character, fasten) -- What to call in your code
    local o = ISBaseTimedAction.new(self, character)
    o.fasten = fasten
    o.maxTime = o:getDuration()
    return o
end
