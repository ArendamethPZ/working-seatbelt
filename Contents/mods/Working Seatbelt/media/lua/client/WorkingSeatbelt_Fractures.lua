WorkingSeatbelt = WorkingSeatbelt or {}

-- Function to apply fracture time reduction to the player's damaged body parts.
local function applyFractureReduction(character, newBodyPartsFractures, currentHealth)
    -- If player is dead, do not do anything. (Otherwise, it'll REALLY bug him out)
    if currentHealth <= 0 then return end

    -- Get the current fracture times of player's body parts.
    local currentBodyPartsFractures = WorkingSeatbelt.getBodyPartsFractures(character)

    -- For each body part, check if it got fractured and update its fracture time if necessary.
    for key, value in pairs(currentBodyPartsFractures) do
        local newBodyPartFractureTimeValue = newBodyPartsFractures[key]

        -- If the key exists and current body part fracture time is not equal to the new expected reduced fracture time.
        if newBodyPartFractureTimeValue then
            if value ~= newBodyPartFractureTimeValue then
                --For debugging
                --[[
                print("Fracture detected in " .. tostring(key))
                print("Current reduction setting: " .. tostring(SandboxVars.workingSeatbelt.fractureReduction / 100))
                print("Current part fracture time (After damage is applied): " .. tostring(value))
                print("Expected new part fracture time (After reduction is applied): " .. tostring(newBodyPartFractureTimeValue))
                ]]
                --

                -- Convert the key to string and get the body part type.
                key = tostring(key)
                local bodyPartType = BodyPartType[key]

                -- Set the body part fracture time to the new reduced time.
                character:getBodyDamage():getBodyPart(bodyPartType):setFractureTime(newBodyPartFractureTimeValue)
            end
        end
    end
end

-- Function to compare player's current fractures to fractures after damage each tick.
function WorkingSeatbelt.onTickFractureReduction()
    -- Get local player.
    local character = getPlayer()

    -- Get player's health and body parts fractures before damage.
    local healthBeforeDamage = character:getModData().Seatbelt_healthBeforeDamage
    local bodypartsFracturesBeforeDamage = character:getModData().Seatbelt_bodypartsFracturesBeforeDamage

    -- Get player's current health and body parts fractures after the damage.
    local currentHealth = character:getBodyDamage():getHealth()
    local currentBodyPartsFractures = WorkingSeatbelt.getBodyPartsFractures(character)

    -- If player's current health is not equal to health after damage (Typically the tick after the car crash damage is applied).
    if currentHealth ~= healthBeforeDamage then
        -- Stop comparing the player's current health to the player's health after damage each tick.
        Events.OnTick.Remove(WorkingSeatbelt.onTickFractureReduction)

        -- Compare body parts fractures before damage to current body parts fractures and find damaged body parts.
        local newBodyPartsFractures = WorkingSeatbelt.getBodyPartsFracturesReduction(bodypartsFracturesBeforeDamage,
            currentBodyPartsFractures, character)

        -- Apply fracture time reduction to the damaged body parts.
        applyFractureReduction(character, newBodyPartsFractures, currentHealth)
    end
end

-- Function to constantly monitor and store player's body parts fracture time, to be able to compare them to the fracture time after damage is applied
function WorkingSeatbelt.onTickWatchBPFractures()
    local character = getPlayer()
    if not character:getVehicle() then return end --No point in going further if player is not in a vehicle
    character:getModData().Seatbelt_bodypartsFracturesBeforeDamage = WorkingSeatbelt.getBodyPartsFractures(character)
end

-- Add the function to event
--Events.OnTick.Add(WorkingSeatbelt.onTickWatchBPFractures)
