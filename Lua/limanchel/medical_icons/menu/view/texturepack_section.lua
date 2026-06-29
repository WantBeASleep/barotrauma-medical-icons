---@class TexturepackSection
---@field create fun(options: MenuViewOpenOptions, parent: Barotrauma.GUIComponent, draft_settings: settings, on_change: fun()|nil)

---@type TexturepackSection
local texturepack_section = {}

---@param options MenuViewOpenOptions
---@param parent Barotrauma.GUIComponent
---@param draft_settings settings
---@param on_change fun()|nil
function texturepack_section.create(options, parent, draft_settings, on_change)
    local row = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.18), parent.RectTransform), true)
    row.Stretch = true
    row.RelativeSpacing = 0.04

    GUI.TextBlock(
        GUI.RectTransform(Vector2(0.32, 1), row.RectTransform),
        "Texturepack",
        nil,
        GUI.GUIStyle.SmallFont,
        GUI.Alignment.Center
    )

    local dropdown = GUI.DropDown(
        GUI.RectTransform(Vector2(0.68, 1), row.RectTransform),
        draft_settings.texturepack,
        #options.texturepacks
    )
    local selected_index = 1
    for index, texturepack in ipairs(options.texturepacks) do
        dropdown.AddItem(texturepack, texturepack)
        if texturepack == draft_settings.texturepack then
            selected_index = index
        end
    end

    dropdown.Select(selected_index - 1)
    dropdown.OnSelected = function(_, user_data)
        if type(user_data) ~= "string" or user_data == draft_settings.texturepack then
            return true
        end

        draft_settings.texturepack = user_data
        if on_change ~= nil then
            on_change()
        end

        return true
    end
end

return texturepack_section
