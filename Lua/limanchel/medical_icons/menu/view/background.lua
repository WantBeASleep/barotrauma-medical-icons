---@class MenuBackground
---@field create fun(parent: Barotrauma.RectTransform): Barotrauma.GUIFrame

---@type MenuBackground
local background = {}

---@param parent Barotrauma.RectTransform
---@return Barotrauma.GUIFrame
function background.create(parent)
    local frame = GUI.Frame(GUI.RectTransform(Vector2(0.84, 0.86), parent, GUI.Anchor.Center), "InnerFrameDark")
    frame.CanBeFocused = false
    return frame
end

return background
