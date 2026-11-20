local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")
local timers = require("_NickCore/Timers")
local utils = require("SkillCreator/Utils")
local skillHandler = require("SkillCreator/SkillHandler")

skillHandler.skills.DarkKnight.Unmend = {
	params = {
		job = 5, icon = 20, type = "New", -- Warrior
		uiName = "Unmend",
		unlockRank = 1,
		helpText = "Press the assigned button.",
		description = "Jump in the air and shoot 3 dark projectiles from the hand",
	},
	conditions = { sameMove = true },
	sequence = {
		{
			nodeName = "VerticalJump",
			nextFrame = 30.0,
			stamina = {
				cost = 200.0,
				frame = 20.0
			}
		},
		{
			motionData = { 0, 190, 0, 0.0, 12.0 },
			softLock = true,
			nextFrame = 55.0,
			lockStamina = true,   -- the clip's own action spends no stamina: only the cost below
			stamina = { cost = 0.0, frame = 28.0 },   -- 2 frames before the first damage
			shell = {
				path = "AppSystem/ch/ch226/60/UserData/ch226002_60ShellParamData_JobMagic.user",
				shellID = 1,
				type = "Owner",
				frame = 32.0, omentime = 0.0, lifetime = 1.0, size = 0.75, positionOffset = { front = 3.0 }
			},
		},
	}
}