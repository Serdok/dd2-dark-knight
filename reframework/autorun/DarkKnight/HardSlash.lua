local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")
local timers = require("_NickCore/Timers")
local utils = require("SkillCreator/Utils")
local skillHandler = require("SkillCreator/SkillHandler")

skillHandler.skills.DarkKnight.HardSlash = {
    params = {
        job = 5, icon = 20, type = "New",
        uiName = "Hard Slash",
        unlockRank = 1,
        helpText = "Press the assigned button.",
        description = "Basic attack string. Swing once horizontally and once vertically.",
    },
    sequence = {
        {
            motionData = { 0, 150, 1705, 0.0, 12.0 }, -- ch00_005_atk_custom_stormslash_1st
            nextFrame = 75,
            softLock = true,
        },
        {
            motionData = { 0, 150, 1102, 0.0, 12.0 }, -- ch00_005_atk_custom_crescentslash_atk_normal
            nextFrame = 154,
            softLock = true,
        }
    }
}