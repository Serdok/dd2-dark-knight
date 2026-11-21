local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")
local skillHandler = require("SkillCreator/SkillHandler")

--register new vocation
fns.run_once["Dark Knight registration"] = function()
    if not p.vocations then return end
    p.vocations["DarkKnight"] = {
        name = "Dark Knight",
        weaponJob = 5,
        armorJobs = {5},
        detail = "Dark Knight Vocation based on FF XIV and FF Stranger of Paradise"
    }
    return true
end

skillHandler.skills.DarkKnight = {}

require("DarkKnight/HardSlash")
