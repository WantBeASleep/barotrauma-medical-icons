---@class MenuView
---@field init fun(menu_registry: Registry)
---@field open fun(settings: settings, on_apply: fun(new_settings: settings))
---@field close fun()

---@type string
local MOD_PATH

---@type string
local LUA_PATH

MOD_PATH, LUA_PATH = ...

---@type MenuBackground
local background = assert(loadfile(LUA_PATH .. "/menu/view/background.lua"))(MOD_PATH, LUA_PATH)

---@type MenuContent
local content = assert(loadfile(LUA_PATH .. "/menu/view/content.lua"))(MOD_PATH, LUA_PATH)

---@type schemas
local schemas = assert(loadfile(LUA_PATH .. "/schema/init.lua"))(MOD_PATH, LUA_PATH)

---@type Registry
local registry

---@type MenuView
local view = {}

---@type Barotrauma.GUIFrame|nil
local menu_frame = nil

---@param menu_registry Registry
---@return nil
function view.init(menu_registry)
    -- Keep init free of GUI construction; Barotrauma's pause menu tree only
    -- exists while the menu is open, so components are built in open().
    registry = menu_registry
end

-- Removes only this mod's menu window. The pause-menu button is managed by
-- pause_menu.lua because it belongs to the pause menu list.
function view.close()
    if menu_frame ~= nil and menu_frame.Parent ~= nil then
        menu_frame.Parent.RemoveChild(menu_frame)
    end

    menu_frame = nil
end

-- Builds the settings window from the current settings state.
---@param settings settings
---@param on_apply fun(new_settings: settings)
function view.open(settings, on_apply)
    if GUI.PauseMenu == nil then
        return
    end

    view.close()

    -- The controller owns persisted settings. The view edits a draft copy until
    -- the user applies it.
    local draft_settings = schemas.settings.copy(settings)

    menu_frame = background.create(GUI.PauseMenu.RectTransform)
    content.create(registry, menu_frame, draft_settings, function(new_settings)
        on_apply(schemas.settings.copy(new_settings))
    end, view.close)
end

return view
