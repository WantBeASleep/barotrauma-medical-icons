local _, LUA_PATH = ...

---@type MenuUi
local ui = assert(loadfile(LUA_PATH .. "/menu/view/ui.lua"))(nil, LUA_PATH)

---@class MenuTitle
---@field create fun(parent: Barotrauma.GUIComponent)

---@type MenuTitle
local title = {}

---@param parent Barotrauma.GUIComponent
---@return nil
function title.create(parent)
    local row = ui.layout(parent, Vector2(1, 1), true, 0.02, GUI.Anchor.CenterLeft, false)
    ui.text(row, Vector2(0.62, 1), "Medical Icons", GUI.Alignment.CenterLeft, 1.28, GUI.GUIStyle.LargeFont)
    ui.text(row, Vector2(0.36, 1), "Settings", GUI.Alignment.CenterRight, 0.95, nil, Color(185, 205, 190, 210))
end

return title
