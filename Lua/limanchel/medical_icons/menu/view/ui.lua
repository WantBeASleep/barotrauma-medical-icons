---@class MenuUi
---@field frame fun(parent: Barotrauma.GUIComponent, size: Microsoft.Xna.Framework.Vector2, style: string|nil, color: Microsoft.Xna.Framework.Color|nil): Barotrauma.GUIFrame
---@field layout fun(parent: Barotrauma.GUIComponent, size: Microsoft.Xna.Framework.Vector2, horizontal: boolean, spacing: number, anchor: Barotrauma.Anchor|nil, stretch: boolean|nil): Barotrauma.GUILayoutGroup
---@field text fun(parent: Barotrauma.GUIComponent, size: Microsoft.Xna.Framework.Vector2, value: string, align: Barotrauma.Alignment|nil, scale: number|nil, font: Barotrauma.GUIFont|nil, color: Microsoft.Xna.Framework.Color|nil): Barotrauma.GUITextBlock
---@field button fun(parent: Barotrauma.GUIComponent, size: Microsoft.Xna.Framework.Vector2, value: string, style: string|nil, on_clicked: fun(): boolean): Barotrauma.GUIButton
---@field open_url fun(url: string): boolean

---@type MenuUi
local ui = {}

local game_main = LuaUserData.CreateStatic("Barotrauma.GameMain")

---@param component Barotrauma.GUIComponent
---@param color Microsoft.Xna.Framework.Color|nil
local function apply_color(component, color)
    if color ~= nil then
        component.Color = color
    end
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2
---@param style string|nil
---@param color Microsoft.Xna.Framework.Color|nil
---@return Barotrauma.GUIFrame
function ui.frame(parent, size, style, color)
    local rect = GUI.RectTransform(size, parent.RectTransform)
    local frame
    if style == nil then
        frame = GUI.Frame(rect)
    else
        frame = GUI.Frame(rect, style)
    end
    frame.CanBeFocused = false
    apply_color(frame, color)
    return frame
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2
---@param horizontal boolean
---@param spacing number
---@param anchor Barotrauma.Anchor|nil
---@param stretch boolean|nil
---@return Barotrauma.GUILayoutGroup
function ui.layout(parent, size, horizontal, spacing, anchor, stretch)
    local layout = GUI.LayoutGroup(GUI.RectTransform(size, parent.RectTransform), horizontal)
    layout.ChildAnchor = anchor or GUI.Anchor.TopLeft
    layout.RelativeSpacing = spacing
    layout.Stretch = stretch == true
    return layout
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2
---@param value string
---@param align Barotrauma.Alignment|nil
---@param scale number|nil
---@param font Barotrauma.GUIFont|nil
---@param color Microsoft.Xna.Framework.Color|nil
---@return Barotrauma.GUITextBlock
function ui.text(parent, size, value, align, scale, font, color)
    local text = GUI.TextBlock(
        GUI.RectTransform(size, parent.RectTransform),
        value,
        nil,
        font,
        align or GUI.Alignment.CenterLeft
    )
    text.TextScale = scale or 1
    if color ~= nil then
        text.TextColor = color
    end
    return text
end

---@param parent Barotrauma.GUIComponent
---@param size Microsoft.Xna.Framework.Vector2
---@param value string
---@param style string|nil
---@param on_clicked fun(): boolean
---@return Barotrauma.GUIButton
function ui.button(parent, size, value, style, on_clicked)
    local rect = GUI.RectTransform(size, parent.RectTransform)
    local button
    if style == nil then
        button = GUI.Button(rect, value)
    else
        button = GUI.Button(rect, value, GUI.Alignment.Center, style)
    end
    button.OnClicked = function()
        return on_clicked()
    end
    return button
end

---@param url string
---@return boolean
function ui.open_url(url)
    local ok = pcall(function()
        game_main.ShowOpenUriPrompt(url, nil, nil)
    end)
    return ok
end

return ui
