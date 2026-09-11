if isClient() and not isServer() then return end
local ServerUtils = require("WorkingSeatbelt_ServerUtils")

local Snapshotter = {}
Snapshotter.snapshots = {}
Snapshotter.lastGear = {} -- vehicle id -> last non-neutral TransmissionNumber letter seen

---@param vehicle BaseVehicle
local function trackGear(vehicle)
    local letter = vehicle:getTransmissionNumberLetter()
    if letter and letter ~= "N" then
        Snapshotter.lastGear[vehicle:getId()] = letter
    end
end

---@param character IsoPlayer
local function takeSnapshot(character)
    if Snapshotter.snapshots[character:getUsername()] and Snapshotter.snapshots[character:getUsername()].locked then
        return
    end
    local username = character:getUsername()
    Snapshotter.snapshots[username] = {
        health    = ServerUtils.getBodyPartsHealth(character),
        fractures = ServerUtils.getBodyPartsFractures(character)
    }
end

---@param character IsoPlayer
---@return table<string, number>
function Snapshotter.getSnapshot(character)
    return Snapshotter.snapshots[character:getUsername()]
end

---@param character IsoPlayer
function Snapshotter.clearSnapshot(character)
    Snapshotter.snapshots[character:getUsername()] = nil
end

function Snapshotter.lockSnapshot(character)
    local username = character:getUsername()
    if Snapshotter.snapshots[username] then
        Snapshotter.snapshots[username].locked = true
    end
end

function Snapshotter.unlockSnapshot(character)
    local username = character:getUsername()
    if Snapshotter.snapshots[username] then
        Snapshotter.snapshots[username].locked = false
    end
end

local function onTick()
    if isServer() then
        -- MP: iterate all connected players
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do
            local character = players:get(i)
            if character:getVehicle() then
                takeSnapshot(character)
                trackGear(character:getVehicle())
            end
        end
    else
        -- Solo: just track the local player
        local character = getPlayer()
        if character and character:getVehicle() then
            takeSnapshot(character)
            trackGear(character:getVehicle())
        end
    end
end

-- Periodic cleanup for players who are no longer connected to server
local lastCleanupTime = 0
local cleanupInterval = 60 -- Cleanup every 60 seconds

local function onTickCleanup()
    if not isServer() then return end

    local now = getTimestamp()
    if now - lastCleanupTime < cleanupInterval then return end

    local online = {}
    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        online[players:get(i):getUsername()] = true
    end

    for username in pairs(Snapshotter.snapshots) do
        if not online[username] then
            Snapshotter.snapshots[username] = nil
        end
    end

    for vehicleId in pairs(Snapshotter.lastGear) do
        if not getVehicleById(vehicleId) then
            Snapshotter.lastGear[vehicleId] = nil
        end
    end

    lastCleanupTime = now
end

Events.OnTick.Add(onTick)
Events.OnTick.Add(onTickCleanup)

return Snapshotter
