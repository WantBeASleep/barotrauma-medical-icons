---@type string
local MOD_PATH

---@type string
local LUA_PATH

-- The loader passes these paths through assert(loadfile(...))(MOD_PATH, LUA_PATH).
MOD_PATH, LUA_PATH = ...

---@class MedicalIconsMenu
---@field init fun(logger: Logger)

---@type MedicalIconsMenu
local menu = {}

---@param logger Logger
---@return nil
function menu.init(logger)
    local settings = dofile(LUA_PATH .. "/menu/safe_setting.lua")(LUA_PATH)
    local registry = dofile(LUA_PATH .. "/menu/registry.lua")(MOD_PATH, LUA_PATH)
    local view = dofile(LUA_PATH .. "/menu/view/init.lua")(LUA_PATH)
    local controller = dofile(LUA_PATH .. "/menu/controller.lua")
    local pause_menu = dofile(LUA_PATH .. "/menu/pause_menu.lua")
    local utils = dofile(LUA_PATH .. "/lib/utils/init.lua")

    local init_ok, init_err = pcall(function()
        registry.init()
        settings.init(logger)
        controller.init(settings, registry, view, logger, utils)
        pause_menu.init(controller, logger)
    end)
    if not init_ok then
        logger.error(string.format("Medical Icons menu init failed: %s", tostring(init_err)))
        error(init_err)
    end

    Hook.Patch("Barotrauma.GUI", "TogglePauseMenu", {}, function(_, _)
        pause_menu.sync_button()
    end, Hook.HookMethodType.After)

    Game.AddCommand("medical_icons", "Opens the Medical Icons menu.", function()
        local ok, err = pcall(pause_menu.force_open)
        if not ok then
            logger.error(string.format("menu command failed: %s", tostring(err)))
        end
    end)

    logger.info("Medical Icons menu loaded")
end

return menu
