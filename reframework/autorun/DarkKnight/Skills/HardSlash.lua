local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")
local timers = require("_NickCore/Timers")
local utils = require("SkillCreator/Utils")
local skillHandler = require("SkillCreator/SkillHandler")

local KEY = "HardSlash"
local warned = {}

local function fail(what, err)
    if warned[what] then return end
    warned[what] = true
    log.error("[" .. KEY .. "] [FAIL] " .. what .. ": " .. tostring(err))
end

local function safe(what, fn)
    return function(...)
        local ok, r = pcall(fn, ...)
        if ok then return r end
        return fail(what, r)
    end
end

skillHandler.skills.DarkKnight.HardSlash = {
    params = {
        job = 9,
        vocation = "DarkKnight",
        icon = 20,
        type = "New",
        lvl1 = {
            uiName = "Hard Slash",
            unlockRank = 1,
            helpText = "Press the assigned button.",
            description = "Basic attack string. Swing once horizontally and once vertically.",
        },
        lvl2 = {
            uiName = "Syphon Strike",
            unlockRank = 5,
            helpText = "Press the assigned button.",
            description = "A more advanced attack combo. Swing Swing once horizontally and once vertically with dark energy.",
        }
    },
    conditions = { sameMove = true },
    sequence = {
        {
            motionData = { 0, 150, 1706, 20.0, 25.0 }, -- ch00_005_atk_custom_stormslash_2nd
            nextFrame = 62,
            softLock = true,
            speed = 1.2,
        },
        {
            motionData = { 0, 150, 1102, 10.0, 25.0 }, -- ch00_005_atk_custom_crescentslash_atk_normal
            nextFrame = 154,
            softLock = true,
            speed = 1.1,
        }
    }
}
