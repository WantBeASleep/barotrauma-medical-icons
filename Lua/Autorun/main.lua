if not CLIENT then
    return
end

local MOD_PATH = ...
local LUA_PATH = MOD_PATH .. "/Lua/limanchel/medical_icons"

local ENV = "dev"

---@type Logger
local log = dofile(LUA_PATH .. "/lib/logger/init.lua")
local log_level = ENV == "prod" and log.levels.warning or log.levels.trace
log.init("QoL - Medical Items", log_level)

---@type MedicalIconsMenu
local menu = assert(loadfile(LUA_PATH .. "/menu/init.lua"))(MOD_PATH, LUA_PATH, log)

menu.init()
