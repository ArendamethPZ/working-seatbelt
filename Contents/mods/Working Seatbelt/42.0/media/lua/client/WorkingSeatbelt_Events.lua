local WorkingSeatbelt = require("WorkingSeatbelt")
local SharedUtils = require("WorkingSeatbelt_SharedUtils")

----------------------------------------------------------------------
-- Custom onEngineStart event
function WorkingSeatbelt.onEngineStart(vehicle)
    local character = getPlayer()
    if not character then return end

    if not vehicle then return end

    local fullName = vehicle:getScript():getFullName()

    -- This part plays the chime sound if the player starts the engine while not wearing a seatbelt.
    -- (The dashboard warning light works itself out every frame; see WorkingSeatbelt_Hooks.lua.)
    if not WorkingSeatbelt.seatbeltBlacklist[fullName] then -- If vehicle accepts seatbelts
        if not SharedUtils.isWearingSeatbelt(character) then -- If player is not wearing a seatbelt
            if SandboxVars.workingSeatbelt.seatbeltWarningChime then
                if SharedUtils.getSeatbeltChimeState(vehicle) then
                    if not vehicle:getEmitter():isPlaying("Chime") then -- If the chime warning sound is not playing
                        local speed = vehicle:getCurrentSpeedKmHour()
                        if speed >= SandboxVars.workingSeatbelt.chimeMinimumSpeed then
                            vehicle:getEmitter():playSoundImpl("Chime", IsoObject.new()) -- Play chime warning sound
                        end
                    end
                end
            end
        end
    end
end

----------------------------------------------------------------------
-- Check if player loads into a vehicle with no seatbelt buckled, and act accordingly

local function onEnterVehicle(character)
    -- This event also fires on every client when ANOTHER player enters a nearby vehicle (network sync). The
    -- indicator and chime below belong to the local player's own dashboard, so ignore everyone else.
    if not character or character ~= getPlayer() then return end

    local vehicle = character:getVehicle()
    WorkingSeatbelt.lastOccupiedVehicle = vehicle
    if not vehicle then return end

    if SandboxVars.workingSeatbelt.seatbeltWarningChime then
        if SharedUtils.getSeatbeltChimeState(vehicle) then
            if not WorkingSeatbelt.seatbeltBlacklist[vehicle:getScript():getFullName()] then
                if not SharedUtils.isWearingSeatbelt(character) then
                    if vehicle:isEngineRunning() then
                        if vehicle:isDriver(character) then
                            if not vehicle:getEmitter():isPlaying("Chime") then
                                local speed = vehicle:getCurrentSpeedKmHour()
                                if speed >= SandboxVars.workingSeatbelt.chimeMinimumSpeed then
                                    vehicle:getEmitter():playSoundImpl("Chime", IsoObject.new())
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.OnEnterVehicle.Add(onEnterVehicle)

local function onExitVehicle(character)
    if not character or character ~= getPlayer() then return end

    local vehicle = WorkingSeatbelt.lastOccupiedVehicle
    if not vehicle then return end

    if not vehicle:getDriver() then
        if SandboxVars.workingSeatbelt.seatbeltWarningChime then
            if SharedUtils.getSeatbeltChimeState(vehicle) then
                if not WorkingSeatbelt.seatbeltBlacklist[vehicle:getScript():getFullName()] then
                    if vehicle:isEngineRunning() then
                        if vehicle:getEmitter():isPlaying("Chime") then
                            vehicle:getEmitter():stopSoundByName("Chime")
                        end
                    end
                end
            end
        end
    end
end

Events.OnExitVehicle.Add(onExitVehicle)
----------------------------------------------------------------------
local bind = {}
bind.value = "[Seatbelt Options]"
table.insert(keyBinding, bind)

bind = {}
bind.value = "ToggleSeatbelt"
bind.key = Keyboard.KEY_NUMPAD0 -- 1-8 are vanilla's hotbar keys; numpad 0 is unbound in vanilla
table.insert(keyBinding, bind)

-- Function to handle seatbelt toggle
local function KeyUp(keynum)
    local player = getPlayer()
    if not player then return end

    local vehicle = player:getVehicle()
    if not vehicle then return end

    local fullName = vehicle:getScript():getFullName()
    if not WorkingSeatbelt.seatbeltBlacklist[fullName] then
        if keynum == getCore():getKey("ToggleSeatbelt") then
            -- Check the seatbelt status
            if player:getModData().Seatbelt_sbStatus then
                WorkingSeatbelt.onDoSeatbelt(player, false)
            else
                WorkingSeatbelt.onDoSeatbelt(player, true)
            end
        end
    end
end

Events.OnKeyPressed.Add(KeyUp)
