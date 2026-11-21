local config = {}

config.LANGUAGE = "English"

-- Gameplay options
config.NEW_VOCATIONS = true -- Support for new vocations. REQUIRES GAME RESTART
config.REMOVE_SKILL_VIDEOS = true -- Remove skill videos for performance and consistency
config.SUMMON_AGGRO = false -- Handle summon aggro. Can be performance intensive with tons of enemies

-- READ CAREFULLY BEFORE CHANGING
-- This option allows relics to get Trickster effects when playing custom vocations
-- For example if a custom vocation uses Sword and Shield, the Sword can get Trickster EX skills mixed with Fighter EX skills
-- This can be used to have EX versions of skills from custom vocations, linked to the Trickster EX skills
-- These relics will stay like that even if the mod is removed, so turn this on at your own risk
-- Also, your pawn will be banned from online play if you or them are wearing these mixed relics
config.ALLOW_MIXED_RELIC_EFFECTS = false

-- Debug options
config.SHOW_MENU = true -- Shows debug menu where you can play the moves and refund skills
config.PRINT_FRAMES = false -- Prints current frame of player nodes. Can be changed in the debug menu

return config