local _, LUA_PATH = ...

---@type MenuUi
local ui = assert(loadfile(LUA_PATH .. "/menu/view/ui.lua"))(nil, LUA_PATH)

local DISCUSSION_URL = "https://steamcommunity.com/workshop/filedetails/discussion/3748775860/572668324079492274/"

---@class TexturepackSection
---@field create fun(registry: Registry, parent: Barotrauma.GUIComponent, draft_settings: settings, on_texturepack_changed: fun())

---@type TexturepackSection
local texturepack_section = {}

---@param texturepack TexturepackAssets|nil
---@return integer
local function get_item_count(texturepack)
    if texturepack == nil or texturepack.item_atlas == nil then
        return 0
    end
    return #texturepack.item_atlas
end

---@param registry Registry
---@param texturepack_name string
---@return string
local function get_item_count_text(registry, texturepack_name)
    return tostring(get_item_count(registry.texturepacks[texturepack_name])) .. " base icons"
end

---@param registry Registry
---@param parent Barotrauma.GUIComponent
---@param draft_settings settings
---@param on_texturepack_changed fun()
function texturepack_section.create(registry, parent, draft_settings, on_texturepack_changed)
    local frame = ui.frame(parent, Vector2(1, 1), "InnerFrameDark")
    local layout = ui.layout(frame, Vector2(0.96, 0.86), false, 0.06, GUI.Anchor.CenterLeft, true)

    local header = ui.layout(layout, Vector2(1, 0.22), true, 0.03, GUI.Anchor.CenterLeft, false)
    ui.text(header, Vector2(0.62, 1), "Texture pack", GUI.Alignment.CenterLeft, 1.05, nil, Color(222, 216, 180, 255))
    local count_label = ui.text(
        header,
        Vector2(0.36, 1),
        get_item_count_text(registry, draft_settings.texturepack),
        GUI.Alignment.CenterRight,
        0.9,
        nil,
        Color(178, 198, 184, 230)
    )

    local choose_row = ui.layout(layout, Vector2(1, 0.28), true, 0.03, GUI.Anchor.CenterLeft, false)
    ui.text(choose_row, Vector2(0.32, 1), "Choose texture pack", GUI.Alignment.CenterLeft, 0.96)

    local dropdown = GUI.DropDown(
        GUI.RectTransform(Vector2(0.66, 1), choose_row.RectTransform),
        draft_settings.texturepack,
        #registry.texturepack_names
    )
    for _, texturepack_name in ipairs(registry.texturepack_names) do
        dropdown.AddItem(texturepack_name, texturepack_name)
    end
    dropdown.SelectItem(draft_settings.texturepack)

    dropdown.OnSelected = function(_, selected_texturepack_name)
        local next_texturepack = tostring(selected_texturepack_name)
        if draft_settings.texturepack ~= next_texturepack then
            draft_settings.texturepack = next_texturepack
            count_label.Text = get_item_count_text(registry, next_texturepack)
            on_texturepack_changed()
        end
        return true
    end

    local note = ui.frame(layout, Vector2(1, 0.42), "InnerFrameDark", Color(20, 30, 28, 210))
    local note_layout = ui.layout(note, Vector2(0.96, 0.84), false, 0.05, GUI.Anchor.CenterLeft, true)
    ui.text(
        note_layout,
        Vector2(1, 0.5),
        "Want your texture pack supported? This mod can add new packs without changing the menu.",
        GUI.Alignment.CenterLeft,
        0.88,
        nil,
        Color(203, 215, 201, 245)
    )
    ui.button(note_layout, Vector2(1, 0.38), "Open discussion", "GUIButtonSmall", function()
        return ui.open_url(DISCUSSION_URL)
    end)
end

return texturepack_section
