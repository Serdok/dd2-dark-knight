local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")

local vocation = { key = "DarkKnight" }

function vocation.selected() return p.vocation == vocation.key end

function vocation.active()
    local job = p.jobContext and p.jobContext.CurrentJob or p.job
    return (job == 9 or job == 10)
        and p.vocation == vocation.key
        and p.weaponJob == 5
        and p.player ~= nil
        and p.player:get_Valid()
end

return vocation