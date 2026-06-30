local _, LUA_PATH = ...

---@type MenuUi
local ui = assert(loadfile(LUA_PATH .. "/menu/view/ui.lua"))(nil, LUA_PATH)

local STEAM_URL = "https://steamcommunity.com/sharedfiles/filedetails/?id=3748775860"

---@class SteamCallout
---@field create fun(parent: Barotrauma.GUIComponent)

---@type SteamCallout
local steam_callout = {}

---@param parent Barotrauma.GUIComponent
---@return nil
function steam_callout.create(parent)
    local frame = ui.frame(parent, Vector2(1, 1), "InnerFrame", Color(38, 72, 88, 210))
    local layout = ui.layout(frame, Vector2(0.96, 0.82), false, 0.08, GUI.Anchor.CenterLeft, true)

    ui.text(
        layout,
        Vector2(1, 0.44),
        "Help these icons get found on Steam, pleeeeeese :)",
        GUI.Alignment.CenterLeft,
        1.02,
        nil,
        Color(230, 244, 245, 255)
    )

    ui.button(layout, Vector2(1, 0.42), "click --> LIKE THIS SHIII <-- click", "GUIButtonSmall", function()
        return ui.open_url(STEAM_URL)
    end)
end

return steam_callout
