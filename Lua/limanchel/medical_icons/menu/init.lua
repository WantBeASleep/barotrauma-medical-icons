---@type string
local MOD_PATH

---@type string
local LUA_PATH

---@type Logger
local log

-- The loader passes shared technical context through assert(loadfile(...))(...).
MOD_PATH, LUA_PATH, log = ...

---@class MedicalIconsMenu
---@field init fun()

---@type MedicalIconsMenu
local menu = {}

---@return nil
function menu.init()
    ---@type SafeSettings
    local settings = assert(loadfile(LUA_PATH .. "/safe_setting.lua"))(MOD_PATH, LUA_PATH, log)
    ---@type Registry
    local registry = assert(loadfile(LUA_PATH .. "/registry.lua"))(MOD_PATH, LUA_PATH)
    ---@type MenuView
    local view = assert(loadfile(LUA_PATH .. "/menu/view/init.lua"))(MOD_PATH, LUA_PATH)
    ---@type MenuController
    local controller = assert(loadfile(LUA_PATH .. "/menu/controller.lua"))(MOD_PATH, LUA_PATH, log)
    ---@type PauseMenu
    local pause_menu = assert(loadfile(LUA_PATH .. "/menu/pause_menu.lua"))(MOD_PATH, LUA_PATH, log)

    local init_ok, init_err = pcall(function()
        registry.init()
        settings.init()
        view.init(registry)
        controller.init(settings, view)
        pause_menu.init(controller)
    end)
    if not init_ok then
        log.error(string.format("Medical Icons menu init failed: %s", tostring(init_err)))
        error(init_err)
    end

    Hook.Patch("Barotrauma.GUI", "TogglePauseMenu", {}, function(_, _)
        ---@diagnostic disable-next-line: missing-return
        pause_menu.sync_button()
    end, Hook.HookMethodType.After)

    Game.AddCommand("medical_icons", "Opens the Medical Icons menu.", function()
        local ok, err = pcall(pause_menu.force_open)
        if not ok then
            log.error(string.format("menu command failed: %s", tostring(err)))
        end
    end)

    log.info("Medical Icons menu loaded")
end

return menu
