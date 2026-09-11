require "TimedActions/ISBaseTimedAction"

Seatbelt_Unfasten = ISBaseTimedAction:derive("Seatbelt_Unfasten");

function Seatbelt_Unfasten:isValid() -- Check if the action can be done. Calls :stop() if false is returned
    return true
end

function Seatbelt_Unfasten:start() -- Trigger when the action starts
    self.character:getEmitter():playSound("seatbelt_unfasten")
end

function Seatbelt_Unfasten:stop() -- Trigger if the action is cancelled
    ISBaseTimedAction.stop(self);
end

function Seatbelt_Unfasten:perform() -- Trigger when the action is complete
    self.character:getModData().Seatbelt_sbStatus = false
    local vehicle = self.character:getVehicle()
    -- local vehicle = self.character:getVehicle()
    -- local seat = vehicle:getSeat(self.character)

    -- if seat == 0 then
    --     local emitter = vehicle:getEmitter()

    --     if not emitter:isPlaying("Chime") then
    --         emitter:playSound("Chime")
    --     end
    -- end
    if SandboxVars.workingSeatbelt.seatbeltWarningChime then
        if WorkingSeatbelt.getSeatbeltChimeState(vehicle) then
            if vehicle then
                if vehicle:isDriver(self.character) then
                    if vehicle:isEngineRunning() then
                        if not vehicle:getEmitter():isPlaying("Chime") then
                            local speed = vehicle:getCurrentSpeedKmHour()
                            if speed >= SandboxVars.workingSeatbelt.chimeMinimumSpeed then
                                vehicle:getEmitter():playSoundImpl("Chime", IsoObject.new())
                            end
                        end
                    end
                    if SandboxVars.workingSeatbelt.seatbeltWarningIndicator then
                        ISVehicleDashboard.sbTex:setVisible(true)
                    end
                end
            end
        end
    end
    ISBaseTimedAction.perform(self)
end

function Seatbelt_Unfasten:new(character) -- What to call in your code
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.character = character;
    o.maxTime = 40; -- Time take by the action
    if o.character:isTimedActionInstant() then o.maxTime = 1; end
    return o;
end
