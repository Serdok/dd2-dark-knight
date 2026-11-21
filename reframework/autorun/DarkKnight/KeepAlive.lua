-- Keeps game objects the mod is still using from being freed by the game.
--
-- How REFramework counts references (its documentation, REManagedObject): every Lua handle to a game object already
-- holds one game reference, taken automatically and given back automatically once Lua no longer refers to the object.
-- A MANUAL add_ref() is never given back (it is meant for brand-new objects, paired with a manual release()).
--
-- 1.0.17: keepAlive.ref no longer calls add_ref. From 1.0.6 to 1.0.16 it did, so every shell, effect, layer and
-- target the mod tracked stayed pinned for the rest of the session - around 1,500 game objects per Cataclysm Cannon
-- (each bolt's shell, its effects, its muzzle flash). They come from the game's limited pools, which ran dry after a
-- few casts: the "refused sigil ring" on later cannons, then the crash about 40 seconds into Cataclysm firing.
--
-- keepAlive.ref(object): returns the handle; storing it keeps the object alive (through the handle's own reference)
--   exactly as long as it is stored, and lets it go once the handle is dropped. Never pins anything.
-- keepAlive.hold(object, seconds) / keepAlive.hold_ref(object, seconds): the timed form, for objects whose use
--   ends by time rather than with a record the mod keeps.
-- keepAlive.forever(object): a permanent reference, ONLY for the few copies the mod itself creates and hands to the
--   game (they are never in a game pool).
local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")
local keepAlive = {}
local held = {} -- key object -> { untilTime, handle }
local nextSweep = 0

function keepAlive.ref(object)
    return object -- the Lua handle itself holds the game reference (see above); no manual add_ref
end

-- Keeps object alive for at least `seconds` of game time (longer if the game is paused). Returns the object.
function keepAlive.hold(object, seconds)
    if object ~= nil then
        local untilTime = (p.gameTime or 0) + (seconds or 60)
        local current = held[object]
        if not current or current.untilTime < untilTime then
            held[object] = { untilTime = untilTime, handle = current and current.handle or object }
        end
    end
    return object
end

-- Keeps the object's handle (as keepAlive.ref) for at least `seconds`.
function keepAlive.hold_ref(object, seconds)
    if object == nil then return object end
    local untilTime = (p.gameTime or 0) + (seconds or 60)
    local current = held[object]
    if current then
        if current.untilTime < untilTime then current.untilTime = untilTime end
    else
        held[object] = { untilTime = untilTime, handle = keepAlive.ref(object) }
    end
    return object
end

-- Ends a timed hold early (the mod no longer uses the object).
function keepAlive.release(object)
    if object ~= nil then held[object] = nil end
end

-- keepAlive.forever(object): a permanent game reference, never released. For the few SHARED copies the mod hands to
-- the game over and over (one copy per source, as the game itself shares one parameter object between all shells of a
-- kind): a shell or hit may keep pointing at such a copy for as long as the game likes, so it must never be freed.
-- Called once per hand-off, so every place the game stores it is matched by a reference of its own.
local forever = {}
function keepAlive.forever(object)
    if object == nil then return nil end
    if not pcall(function() object:add_ref_permanent() end) then
        pcall(function() object:add_ref() end)
    end
    forever[object] = true -- the Lua handle is never dropped either
    return object
end

-- keepAlive.shared(source, variant, build): ONE permanent copy per game object (and variant), built once by
-- build(source) - for settings the game shares between all shells of a kind (shell parameters), so every shell gets
-- the same copy instead of a new one that is freed later. The source is held too, so its address (the cache key) can
-- never be reused by another object. A source that is itself a shared copy is copied again only for a new variant.
local sharedCopies, sharedSet = {}, {}
function keepAlive.shared(source, variant, build)
    local address = source:get_address()
    local key = tostring(address) .. "|" .. tostring(variant)
    local copy = sharedCopies[key]
    if copy then return copy end
    keepAlive.forever(source)
    copy = build(source)
    sharedCopies[key] = copy
    sharedSet[copy:get_address()] = true
    return copy
end
function keepAlive.is_shared(object)
    return object ~= nil and sharedSet[object:get_address()] == true
end

fns.on_frame["Dark Knight Keep Alive"] = function()
    local now = p.gameTime or 0
    if now < nextSweep then return end
    nextSweep = now + 1.0
    for object, entry in pairs(held) do
        if now >= entry.untilTime then held[object] = nil end
    end
end

return keepAlive
