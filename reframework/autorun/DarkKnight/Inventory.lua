local p         = require("_NickCore/Properties")
local fns       = require("_NickCore/Functions")
local registry  = require("SkillCreator/UIHandler/Registry")
local state     = require("SkillCreator/UIHandler/VocationState")
local config    = require("SkillCreator/Config")

local keepAlive = require("DarkKnight/KeepAlive")
local vocation  = require("DarkKnight/Vocation")

assert(config.NEW_VOCATIONS, "Dark Knight requires Skill Creator NEW_VOCATIONS=true and a game restart")

---------------------------------------------------------------------------
-- THE LIST
-- IDs come from any vocation; the source is found automatically.
-- Turn on DUMP_IDS once to log every native skill ID with its name.
---------------------------------------------------------------------------
local SKILLS = {
    weapon = { },   -- native weapon skills (CustomSkillJobDefineDictionary)
    core   = { },   -- core skills (NormalSkillDefineDictionary), e.g. Fighter's minus Tusk Toss
    actions_from   = 5,  -- basic attacks / moveset copied from this job (1 = Fighter)
    abilities_from = 5,  -- augments copied from this job
}
local DUMP_IDS = false
local JOB = 9

---------------------------------------------------------------------------
local create = sdk.find_type_definition("System.Activator"):get_method("CreateInstance")
local msg_get = sdk.find_type_definition("via.gui.message"):get_method("get(System.Guid)")

local function get(dict, key)
    if dict and dict:ContainsKey(key) then return dict[key] end
end
local function new_like(dict) return create:call(nil, dict:GetType()):add_ref() end
local function hold(obj) return keepAlive.hold(obj:MemberwiseClone():add_ref(), math.huge) end
local function job_key(dict, n)  -- some dictionaries use "Job09", others 9
    local k = dict:GetType():GetGenericArguments()[0]
    return k:get_FullName() == "System.String" and ("Job%02d"):format(n) or n
end
local function text(guid)
    local ok, t = pcall(function() return msg_get:call(nil, guid) end)
    return ok and t and tostring(t) or "?"
end

-- Deep-enough copy: weapon skills hold a per-level dictionary/array, core skills are single records.
local function copy_value(v)
    if v._entries then
        local c = new_like(v)
        for _, e in pairs(v._entries) do if e.value then c:Add(e.key, hold(e.value)) end end
        return keepAlive.hold(c, math.huge)
    end
    if v:GetType():get_IsArray() then
        local c = v:MemberwiseClone():add_ref()
        for i = 0, v:get_size() - 1 do if v[i] then c[i] = hold(v[i]) end end
        return keepAlive.hold(c, math.huge)
    end
    return hold(v)
end

-- Find skill `id` in any job's inner dictionary of `outer`.
local function find(outer, id)
    for _, job in pairs(outer._entries) do
        if job.value and job.key ~= 0 then
            local v = get(job.value, id)
            if v then return v end
        end
    end
end

-- Build a dictionary shaped like `template` containing only `ids`.
local function build(outer, template, ids)
    local d = new_like(template)
    for _, id in ipairs(ids) do
        local v = find(outer, id)
        if v then d:Add(id, copy_value(v)) else log.warn("[DarkKnight] skill id not found: " .. tostring(id)) end
    end
    return d
end

---------------------------------------------------------------------------
-- Install / restore
---------------------------------------------------------------------------
local swapped = {}   -- { dict, key, previous, value }
local installed_for = nil
local weapon_set = {}
for _, id in ipairs(SKILLS.weapon) do weapon_set[id] = true end

local function swap(dict, key, value)
    if not dict then return end
    swapped[#swapped + 1] = { dict = dict, key = key, previous = get(dict, key), value = value }
    dict[key] = value
end

local function restore()
    for i = #swapped, 1, -1 do
        local s = swapped[i]
        if get(s.dict, s.key) == s.value then
            if s.previous ~= nil then s.dict[s.key] = s.previous else s.dict:Remove(s.key) end
        end
    end
    swapped, installed_for = {}, nil
end

local function dump(gui)
    for name, outer in pairs({ core = gui.NormalSkillDefineDictionary, weapon = gui.CustomSkillJobDefineDictionary }) do
        for _, job in pairs(outer._entries) do
            if job.value then
                for _, e in pairs(job.value._entries) do
                    local name_guid = e.value and e.value._SkillName
                    log.info(("[DarkKnight ids] %s job=%s id=%s name=%s"):format(name, tostring(job.key), tostring(e.key),
                        name_guid and text(name_guid) or "?"))
                end
            end
        end
    end
    DUMP_IDS = false
end

local function install(gui)
    if installed_for == gui then return end
    restore()
    if DUMP_IDS then dump(gui) end

    local core, weapon = gui.NormalSkillDefineDictionary, gui.CustomSkillJobDefineDictionary
    local coreKey, weaponKey = job_key(core, JOB), job_key(weapon, JOB)
    swap(core,   coreKey,   build(core,   get(core, coreKey)     or get(core, job_key(core, 1)),     SKILLS.core))
    swap(weapon, weaponKey, build(weapon, get(weapon, weaponKey) or get(weapon, job_key(weapon, 1)), SKILLS.weapon))

    local ex = gui:get_field("ExCustomSkillJobDefineDictionary")
    if ex and get(ex, job_key(ex, JOB)) then swap(ex, job_key(ex, JOB), new_like(get(ex, job_key(ex, JOB)))) end

    for name, from in pairs({ NormalActionDefineDictionary = SKILLS.actions_from, AbilityDefineDictionary = SKILLS.abilities_from }) do
        local d = gui:get_field(name)
        local src = d and get(d, job_key(d, from))
        if src then swap(d, job_key(d, JOB), copy_value(src)) end
    end

    for _, id in ipairs(SKILLS.core) do
        registry.normalSkills[id] = { job = "Job09", vocation = vocation.key }
    end
    installed_for = gui
    log.info("[DarkKnight] inventory installed: " .. #SKILLS.core .. " core, " .. #SKILLS.weapon .. " weapon skills")
end

local function refresh()
    if not vocation.selected() then
        if #swapped > 0 then restore() end
        return
    end
    local gui = sdk.get_managed_singleton("app.GuiManager")
    if gui and p.player and p.player:get_Valid() and registry.normalSkills then
        local ok, err = pcall(install, gui)
        if not ok then log.error("[DarkKnight] install failed: " .. tostring(err)); restore() end
    end
end

---------------------------------------------------------------------------
-- When to refresh
---------------------------------------------------------------------------
local next_check = 0
fns.on_frame["DarkKnight inventory"] = function()
    if p.gameTime < next_check then return end
    next_check = p.gameTime + 0.25
    refresh()
end

-- The Vocation Guild menus read the lists before the next frame; install first.
local guild = sdk.find_type_definition("app.ui040101_00")
for _, m in ipairs({ "addCustomSkillContentsList", "setupNormalSkillMenu" }) do
    local method = guild:get_method(m)
    if method then sdk.hook(method, function() refresh() end) end
end

-- Skill Creator clears Job09 learning on vocation switch; don't let it touch our swapped lists.
local clear = state.clear_job09_skills
local function clear_wrapped(...) restore(); return clear(...) end
state.clear_job09_skills = clear_wrapped

-- Which weapon skills are selectable: the list above, plus this vocation's Skill Creator skills.
sdk.hook(sdk.find_type_definition("app.ui010201"):get_method("isDisableCustomSkill"),
    function(args)
        local s = thread.get_hook_storage(); s.dark_knight = false
        if not vocation.selected() then return end
        local id = sdk.to_int64(args[3])
        local custom = registry.customSkills and registry.customSkills[id]
        s.dark_knight = weapon_set[id] or (custom and custom.vocation == vocation.key) or false
    end,
    function(retval)
        if thread.get_hook_storage().dark_knight then return sdk.to_ptr(0) end
        return retval
    end)

re.on_script_reset(function()
    restore()
    if state.clear_job09_skills == clear_wrapped then state.clear_job09_skills = clear end
    if p.vocations then p.vocations[vocation.key] = nil end
end)