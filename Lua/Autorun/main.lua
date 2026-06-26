if not CLIENT then
    return
end

local MOD_PATH = ...
local SOURCE_PATH = MOD_PATH .. "/Lua/limanchel/medical_icons"

local ENV = "dev"

---@type Logger
local log = dofile(SOURCE_PATH .. "/lib/logger.lua")
local log_level = ENV == "prod" and log.levels.warning or log.levels.debug
log.init("QoL - Medical Items", log_level)

---@type MedicalIcons
local medical_icons = assert(loadfile(SOURCE_PATH .. "/main.lua"))(MOD_PATH, SOURCE_PATH)

medical_icons.apply(log)

if ENV == "dev" then
    medical_icons.apply_existing_item_holdable_settings()
end
