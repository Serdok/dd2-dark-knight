local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")
local skillHandler = require("SkillCreator/SkillHandler")

local vocation = require("DarkKnight/Vocation")

--register new vocation
fns.run_once["Dark Knight registration"] = function()
    if not p.vocations then return end
    p.vocations[vocation.key] = {
        name = "Dark Knight",
        weaponJob = 5,
        armorJobs = { 5 },
        detail = "Dark Knight Vocation based on FF XIV and FF Stranger of Paradise"
    }
    return true
end

-- register skills
skillHandler.skills.DarkKnight = {}
require("DarkKnight/Skills/HardSlash")

-- link skills to vocation
require("DarkKnight/Inventory")