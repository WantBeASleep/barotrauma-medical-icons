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

local ui_runtime = assert(loadfile(LUA_PATH .. "/lib/ui_runtime/init.lua"))({
    mod_path = MOD_PATH,
    lua_path = LUA_PATH,
})

local LAYOUT_PATH = MOD_PATH .. "/Lua/limanchel/medical_icons/ui/layouts/medical_icons_static.json"

---@type ui_runtime.Tree|nil
local rendered_menu = nil

local function get_mount_parent()
    if not GUI.PauseMenuOpen then
        GUI.TogglePauseMenu()
    end

    if GUI.PauseMenu ~= nil then
        return GUI.PauseMenu.RectTransform
    end

    return GUI.Canvas
end

local function close_rendered_menu()
    if rendered_menu ~= nil then
        rendered_menu.root:remove()
        rendered_menu = nil
    end
end

Game.AddCommand("show_menu", "Render Medical Icons static JSON UI experiment.", function()
    local ok, err = pcall(function()
        close_rendered_menu()
        local layout = ui_runtime.load_layout(LAYOUT_PATH)
        rendered_menu = ui_runtime.render(layout, get_mount_parent(), {
            mod_path = MOD_PATH,
        })
    end)

    if ok then
        log.info("static JSON UI rendered")
    else
        log.error("static JSON UI render failed: " .. tostring(err))
    end
end)

log.info("Medical Icons static UI experiment loaded; use show_menu")
