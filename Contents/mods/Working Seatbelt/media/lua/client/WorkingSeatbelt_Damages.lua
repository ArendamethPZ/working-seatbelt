WorkingSeatbelt = WorkingSeatbelt or {}

-- Function to apply damage reduction to the player's damaged body parts.
local function applyDamageReduction(character, newBodyPartsHealth, currentHealth)
    -- If player is dead, do not do anything. (Otherwise, it'll REALLY bug him out)
    if currentHealth <= 0 then return end

    -- Get the current health of player's body parts.
    local currentBodyPartsHealth = WorkingSeatbelt.getBodyPartsHealth(character)

    -- For each body part, check if it's damaged and update its health if necessary.
    for key, value in pairs(currentBodyPartsHealth) do
        local newBodyPartHealthValue = newBodyPartsHealth[key]

        -- If the key exists and current body part health is not equal to the new expected reduced health.
        if newBodyPartHealthValue then
            if value ~= newBodyPartHealthValue then
                --For debugging
                --[[
                print("Damage detected in " .. tostring(key))
                print("Current reduction setting: " .. tostring(SandboxVars.workingSeatbelt.damageReduction / 100))
                print("Current part health (After damage is applied): " .. tostring(value))
                print("Expected new part health (After reduction is applied): " .. tostring(newBodyPartHealthValue))
                ]]
                --

                -- Convert the key to string and get the body part type.
                key = tostring(key)
                local bodyPartType = BodyPartType[key]

                -- Set the body part health to the new reduced health.
                character:getBodyDamage():getBodyPart(bodyPartType):SetHealth(newBodyPartHealthValue)
            end
        end
    end
end

-- Function to compare player's current health to health after damage each tick.
function WorkingSeatbelt.onTickDamageReduction()
    -- Get local player.
    local character = getPlayer()

    -- Get player's health and body parts health before damage.
    local healthBeforeDamage = character:getModData().Seatbelt_healthBeforeDamage
    local bodypartsHealthBeforeDamage = character:getModData().Seatbelt_bodypartsHealthBeforeDamage

    -- Get player's current health and body parts health after the damage.
    local currentHealth = character:getBodyDamage():getHealth()
    local currentBodyPartsHealth = WorkingSeatbelt.getBodyPartsHealth(character)

    -- If player's current health is not equal to health after damage (Typically the tick after the car crash damage is applied).
    if currentHealth ~= healthBeforeDamage then
        -- Stop comparing the player's current health to the player's health after damage each tick.
        Events.OnTick.Remove(WorkingSeatbelt.onTickDamageReduction)

        -- Compare body parts health before damage to current body parts health and find damaged body parts.
        local newBodyPartsHealth = WorkingSeatbelt.getBodyPartsHealthReduction(bodypartsHealthBeforeDamage,
            currentBodyPartsHealth, character)

        -- Apply damage reduction to the damaged body parts.
        applyDamageReduction(character, newBodyPartsHealth, currentHealth)
    end
end

-- Function to constantly monitor and store player's body parts health, to be able to compare them to the health after damage is applied
function WorkingSeatbelt.onTickWatchBPHealth()
    local character = getPlayer()
    if not character:getVehicle() then return end --No point in going further if player is not in a vehicle
    character:getModData().Seatbelt_bodypartsHealthBeforeDamage = WorkingSeatbelt.getBodyPartsHealth(character)
end

-- Add the function to event
--Events.OnTick.Add(WorkingSeatbelt.onTickWatchBPHealth)

--[[
Algorithm:


-- onTickWatchBPHealth() function
-----------------------------------
1- The player's bodyparts health is constantly monitored each tick and stored in player's moddata

-- OnPlayerGetDamage(character, damageType, damage) function
-----------------------------------
2- Once the player crashes, and assuming seatbelt is on, the script stops monitoring the bodyparts health temporarily
3- The script fetches the player's body average health before damage is applied from the onPlayerGetDamage function.
It then stores that fetched number in the player's moddata
NOTE: The function can't return the body health after the damage.
4- The script starts comparing the body's health each tick to the previously fetched body health using onTickDamageReduction()
This is done because the player's body health after damage can't be fetched in the same tick that damage is applied in the onPlayerGetDamage function,
so we fetch it in the next tick

-- OnTickDamageReduction() function
-----------------------------------
5- The script returns True if player's current health is not equal to health before damage
(which is fetched previously and stored in OnPlayerGetDamage(character, damageType, damage)).
This is typically occurring in the tick right after the player damage got applied
6- Remove the function onTickDamageReduction() from the onTick event.
7- Compare the table of body parts health before damage, which is constantly monitored and stored before crash, to the table of body parts health
after damage is applied, and then find the differences, and return a table of affected body parts, alongside their expected health after
damage reduction. This is done using the function WorkingSeatbelt.getBodyPartsHealthReduction(table1, table2)
8- Apply damage reduction using the function applyDamageReduction(character, newBodyPartsHealth, currentHealth)

--WorkingSeatbelt.getBodyPartsHealthReduction(table1, table2) function
-----------------------------------
TBA

--applyDamageReduction(character, newBodyPartsHealth, currentHealth) function
-----------------------------------
9- If player is dead, do not do anything
10- Get the current body parts health using WorkingSeatbelt.getBodyPartsHealth()
11- Compare the current body parts health to the body parts health stored previously before the crash using the onTickWatchBPHealth
12- For each current bodypart health, compare it to the new body part health passed into the function. If the key exists, update the health.
--]]
