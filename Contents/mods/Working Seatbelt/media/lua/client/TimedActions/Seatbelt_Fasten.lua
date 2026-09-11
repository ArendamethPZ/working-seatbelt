require "TimedActions/ISBaseTimedAction"

Seatbelt_Fasten = ISBaseTimedAction:derive("Seatbelt_Fasten");

function Seatbelt_Fasten:isValid() -- Check if the action can be done. Calls :stop() if false is returned
    return true
end

function Seatbelt_Fasten:start() -- Trigger when the action starts
    self.character:getEmitter():playSound("seatbelt_fasten")
end

function Seatbelt_Fasten:stop() -- Trigger if the action is cancelled
    ISBaseTimedAction.stop(self);
end

function Seatbelt_Fasten:perform() -- Trigger when the action is complete
    self.character:getModData().Seatbelt_sbStatus = true
    local vehicle = self.character:getVehicle()
    -- local vehicle = self.character:getVehicle()
    -- local seat = vehicle:getSeat(self.character)

    -- if seat == 0 then
    --     local emitter = vehicle:getEmitter()
    --     if emitter:isPlaying("Chime") then
    --         emitter:stopSoundByName("Chime")
    --     end
    -- end

    if SandboxVars.workingSeatbelt.seatbeltWarningChime then
        if WorkingSeatbelt.getSeatbeltChimeState(vehicle) then
            if vehicle then
                -- Stop the chime sound if the player is the driver
                if vehicle:isDriver(self.character) then
                    if vehicle:isEngineRunning() then
                        if vehicle:getEmitter():isPlaying("Chime") then
                            vehicle:getEmitter():stopSoundByName("Chime")
                        end
                    end
                    if SandboxVars.workingSeatbelt.seatbeltWarningIndicator then
                        ISVehicleDashboard.sbTex:setVisible(false)
                    end
                end
            end
        end
    end
    ISBaseTimedAction.perform(self)
end

function Seatbelt_Fasten:new(character, playerIndex) -- What to call in your code
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.character = character;
    o.maxTime = 40; -- Time take by the action
    if o.character:isTimedActionInstant() then o.maxTime = 1; end
    return o;
end
