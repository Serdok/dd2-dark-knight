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
        job = 5, icon = 20, type = "New",
        uiName = "Hard Slash",
        unlockRank = 1,
        helpText = "Press the assigned button.",
        description = "Basic attack string. Swing once horizontally and once vertically.",
    },
    conditions = { sameMove = true },
    sequence = {
        {
            motionData = { 0, 150, 1705, 0.0, 12.0 }, -- ch00_005_atk_custom_stormslash_1st
            nextFrame = 75,
            softLock = true,
            on_start = safe("on_start", function(ctx)
                p.fullLayer:set_MirrorSymmetry(true)
            end),
            on_end = safe("on_end", function(ctx)
                p.fullLayer:set_MirrorSymmetry(false)
            end),
        },
        {
            motionData = { 0, 150, 1102, 0.0, 12.0 }, -- ch00_005_atk_custom_crescentslash_atk_normal
            nextFrame = 154,
            softLock = true,
        }
    }
}