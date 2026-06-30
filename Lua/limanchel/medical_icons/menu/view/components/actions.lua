---@class MenuActions
---@field create fun(parent: Barotrauma.GUIComponent, draft_settings: settings, on_apply: fun(new_settings: settings), on_close: fun(), on_reset: fun())

local _, LUA_PATH = ...

---@type MenuUi
local ui = assert(loadfile(LUA_PATH .. "/menu/view/ui.lua"))(nil, LUA_PATH)

---@type MenuActions
local actions = {}

---@param parent Barotrauma.GUIComponent
---@param draft_settings settings
---@param on_apply fun(new_settings: settings)
---@param on_close fun()
---@param on_reset fun()
---@return nil
function actions.create(parent, draft_settings, on_apply, on_close, on_reset)
    local row = ui.layout(parent, Vector2(1, 1), true, 0.025, GUI.Anchor.CenterRight, false)

    ui.button(row, Vector2(0.22, 0.72), "Cancel", "GUIButtonSmall", function()
        on_close()
        return true
    end)

    ui.button(row, Vector2(0.22, 0.72), "Reset", "GUIButtonSmall", function()
        on_reset()
        return true
    end)

    ui.button(row, Vector2(0.28, 0.72), "Apply", nil, function()
        on_apply(draft_settings)
        return true
    end)
end

return actions
