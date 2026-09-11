WorkingSeatbelt = WorkingSeatbelt or {}

local blacklistedTextures = {
    ["fencing_01_8"] = true,
    ["fencing_01_9"] = true,
    ["fencing_01_10"] = true,
    ["fencing_01_11"] = true,
    ["fencing_01_13"] = true,
    ["fencing_01_40"] = true,
    ["fencing_01_41"] = true,
    ["fencing_01_56"] = true,
    ["fencing_01_57"] = true,
    ["fencing_01_58"] = true,
    ["fencing_01_59"] = true,
    ["fencing_01_64"] = true,
    ["fencing_01_65"] = true,
    ["fencing_01_66"] = true,
    ["fencing_01_67"] = true,
    ["fencing_01_89"] = true,
    ["fencing_01_90"] = true,
    ["fencing_01_91"] = true,
    ["fixtures_doors_fences_01_32"] = true,
    ["fixtures_doors_fences_01_41"] = true,
    ["fixtures_doors_fences_01_74"] = true,
    ["fixtures_doors_fences_01_75"] = true,
    ["fixtures_doors_fences_01_66"] = true,
    ["fixtures_doors_fences_01_67"] = true,
}

-- Function to check for buildings at the specified coordinates
local function hasBuilding(x, y, z)
    local square = getSquare(x, y, z)
    return square and square:getBuilding()
end

-- Function to check for blacklisted textures at the specified coordinates
local function hasBlacklistedTexture(x, y, z)
    local square = getSquare(x, y, z)
    if square then
        local tileObjects = square:getLuaTileObjectList()

        for _, tileObject in ipairs(tileObjects) do
            if blacklistedTextures[tileObject:getTextureName()] then
                return true
            end
        end
    end

    return false
end

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

    -- Check for buildings or blacklisted textures within the specified offset
    local breakSquareDetected = false
    for i = 1, offset do
        x, y = x + dx, y + dy

        if hasBuilding(x, y, z) or hasBlacklistedTexture(x, y, z) then
            breakSquareDetected = true
            break
        end
    end

    -- If a building or blacklisted texture is detected, move back one square
    if breakSquareDetected then
        x, y = x - dx, y - dy
    end

    return x, y, z
end

WorkingSeatbelt.ejectPlayer = function()
    Events.OnTick.Remove(WorkingSeatbelt.ejectPlayer)
    local player = getPlayer()
    local vehicle = player:getVehicle()
    if not vehicle then return end

    local offset = 5
    if vehicle then
        player:getVehicle():exit(player)
        triggerEvent("OnExitVehicle", player)
        vehicle:updateHasExtendOffsetForExitEnd(player);
    end

    --if not vehicle then return end
    local x, y, z = calculateNewCoords(player, offset)

    player:setPosition(x, y, z)

    player:setBumpType("stagger")
    player:setVariable("BumpDone", false)
    player:setVariable("BumpFall", true)
    player:setVariable("BumpFallType", "pushedBehind")


    --Apply damage to player
    if not getActivatedMods():contains("ProperVehicleInjuriesMP") then
        player:getBodyDamage():ReduceGeneralHealth(85)
    end
end

if isDebugEnabled() then
    WorkingSeatbelt.printSquareTextures = function()
        local square = getPlayer():getSquare()
        local tileObjects = square:getLuaTileObjectList()
        for _, tileObject in ipairs(tileObjects) do
            print(tileObject:getTextureName())
        end
    end
end

-- WorkingSeatbelt.Testfunction = function()
--     if getPlayer():getVehicle() then
--         WorkingSeatbelt.ejectPlayer(getPlayer(), 20)
--     end
-- end
