local SharedUtils = require("WorkingSeatbelt_SharedUtils")
local EjectUtils = {}

local function calculateNewCoords(player, offset)
    -- Get player direction as a string
    local direction = tostring(player:getDir())

    -- Get player coordinates
    local x, y, z = player:getX(), player:getY(), player:getZ()

    -- Define a table to map directions to coordinate changes
    local directionOffsets = {
        N = { 0, -1 },
        S = { 0, 1 },
        E = { 1, 0 },
        W = { -1, 0 },
        NW = { -1, -1 },
        NE = { 1, -1 },
        SW = { -1, 1 },
        SE = { 1, 1 }
    }

    -- Calculate the offset based on the direction
    local offsetChange = directionOffsets[direction] or { 0, 0 }
    local dx, dy = offsetChange[1], offsetChange[2]

    -- Walk outward one square at a time, using the same collision check the
    -- game's own movement/pathfinding uses, and stop at the last clear square
    -- instead of overshooting through walls, fences, closed doors, etc.
    local currentSquare = getSquare(x, y, z)
    local finalX, finalY = x, y

    for i = 1, offset do
        local nextX, nextY = finalX + dx, finalY + dy
        local nextSquare = getSquare(nextX, nextY, z)

        if not currentSquare or not nextSquare or currentSquare:isBlockedTo(nextSquare) then
            break
        end

        finalX, finalY = nextX, nextY
        currentSquare = nextSquare
    end

    return { x = finalX, y = finalY, z = z }
end

---@param character IsoPlayer
---@param vehicle   BaseVehicle
---@param damage    number
function EjectUtils.shouldBeEjected(character, vehicle, damage)
    local vars = SandboxVars.workingSeatbelt

    if not vehicle then return false end -- Player can't be ejected if there's no vehicle in first place
    if not vars.canPlayerBeEjected then return false end -- Player can't be ejected if the sandbox option isn't enabled
    if damage < vars.ejectMinimumCrashStrength then return false end -- Player can't be ejected if damage is less than sandbox setting
    if SharedUtils.isWearingSeatbelt(character) then return false end -- Player can't be ejected if not wearing seatbelt

    -- Neutral just means the driver let off the pedal; it says nothing about
    -- which way the car was actually travelling (momentum keeps it going
    -- forward or backward regardless of gear). So when coasting in neutral,
    -- fall back to the last gear that was actually engaged to decide that.
    -- Required lazily since EjectUtils is shared and loads on real MP clients
    -- too, where this server/SP-only module self-guards to an empty return.
    local Snapshotter = require("WorkingSeatbelt_Snapshotter")
    local gear = vehicle:getTransmissionNumberLetter()
    if gear == "N" then
        gear = Snapshotter.lastGear[vehicle:getId()]
    end
    if gear == "R" then return false end -- Player can't be ejected if car is (or was, and is now coasting) in reverse
    if vehicle:getPartById("Windshield") and vehicle:getPartById("Windshield"):getCondition() > 0 then
        return false
    end -- Player can't be be ejected if windshield condition is more than 0
    if vehicle:getPartById("Windshield") and vehicle:getPartById("Windshield"):getInventoryItem() then
        return false
    end -- Player can't be ejected if windshield is installed
    return true
end

---@param character IsoPlayer
function EjectUtils.applyEject(character)
    local vehicle = character:getVehicle()
    if not vehicle then return end

    vehicle:exit(character)
    triggerEvent("OnExitVehicle", character)
    vehicle:updateHasExtendOffsetForExitEnd(character)

    -- Calculated here (rather than passed in) so it always uses this
    -- machine's own live position/direction instead of a stale copy.
    local coords = calculateNewCoords(character, 5)
    character:setPosition(coords.x, coords.y, coords.z)

    character:setBumpType("stagger")
    character:setVariable("BumpDone", false)
    character:setVariable("BumpFall", true)
    character:setVariable("BumpFallType", "pushedBehind")
end

---@param character IsoPlayer
function EjectUtils.ejectPlayer(character)
    -- Apply damage to player
    if not getActivatedMods():contains("ProperVehicleInjuriesMP") then
        character:getBodyDamage():ReduceGeneralHealth(SandboxVars.workingSeatbelt.ejectDamage)
    end
    if not isClient() and not isServer() then
        EjectUtils.applyEject(character)
    else
        sendServerCommand(character, 'WorkingSeatbelt', 'ejectPlayer', {})
    end
end

return EjectUtils

-- if isDebugEnabled() then
--     WorkingSeatbelt.printSquareTextures = function ()
--         local square = getPlayer():getSquare()
--         local tileObjects = square:getLuaTileObjectList()
--         for _, tileObject in ipairs(tileObjects) do
--             print(tileObject:getTextureName())
--         end
--     end
-- end

-- WorkingSeatbelt.Testfunction = function()
--     if getPlayer():getVehicle() then
--         WorkingSeatbelt.ejectPlayer(getPlayer(), 20)
--     end
-- end
