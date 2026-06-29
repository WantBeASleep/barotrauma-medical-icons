---@class PreviewSection
---@field create fun(options: MenuViewOpenOptions, parent: Barotrauma.GUIComponent, draft_settings: settings): fun()

---@type PreviewSection
local preview_section = {}

local ICON_SIZE = 64

local SLOT_ANCHORS = {
    ["top-left"] = GUI.Anchor.TopLeft,
    ["top-right"] = GUI.Anchor.TopRight,
    ["bottom-left"] = GUI.Anchor.BottomLeft,
    ["bottom-right"] = GUI.Anchor.BottomRight,
}

---@param rect item_atlas_item|overlay_atlas_item
---@return Microsoft.Xna.Framework.Rectangle
local function source_rect(rect)
    return Rectangle(
        rect.icon_x or rect.x,
        rect.icon_y or rect.y,
        rect.icon_width or rect.width,
        rect.icon_height or rect.height
    )
end

---@param texturepack texturepack|nil
---@param item string
---@return item_atlas_item|nil
local function find_item_rect(texturepack, item)
    if texturepack == nil then
        return nil
    end

    for _, item_atlas_item in ipairs(texturepack.item_atlas) do
        if item_atlas_item.item == item then
            return item_atlas_item
        end
    end
end

---@param overlaypack overlaypack|nil
---@param texturepack string
---@param item string
---@return overlay_atlas_item|nil
local function find_overlay_rect(overlaypack, texturepack, item)
    if overlaypack == nil then
        return nil
    end

    local overlay_name = nil
    local item_overlays = overlaypack.item_overlays[texturepack]
    if type(item_overlays) ~= "table" then
        return nil
    end

    for _, item_overlay in ipairs(item_overlays) do
        if item_overlay.item == item then
            overlay_name = item_overlay.overlay
            break
        end
    end

    if overlay_name == nil then
        return nil
    end

    for _, overlay_rect in ipairs(overlaypack.overlay_atlas) do
        if overlay_rect.overlay == overlay_name then
            return overlay_rect
        end
    end
end

---@param parent Barotrauma.GUIComponent
---@param sprite Barotrauma.Sprite
---@param relative_size Microsoft.Xna.Framework.Vector2
---@param anchor Barotrauma.Anchor
local function create_image(parent, sprite, relative_size, anchor)
    GUI.Image(GUI.RectTransform(relative_size, parent.RectTransform, anchor), sprite, true, nil)
end

---@param options MenuViewOpenOptions
---@param parent Barotrauma.GUIComponent
---@param draft_settings settings
---@return fun()
function preview_section.create(options, parent, draft_settings)
    local section = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.2), parent.RectTransform), false)
    section.Stretch = true
    section.RelativeSpacing = 0.04

    GUI.TextBlock(
        GUI.RectTransform(Vector2(1, 0.28), section.RectTransform),
        "Preview",
        nil,
        GUI.GUIStyle.SmallFont,
        GUI.Alignment.CenterLeft
    )

    local row = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.5), section.RectTransform), true)
    row.Stretch = true
    row.RelativeSpacing = 0.04

    local content = nil
    local selected_item = nil

    ---@return nil
    local function clear_content()
        if content ~= nil and content.Parent ~= nil then
            row.RemoveChild(content)
        end

        content = nil
    end

    ---@return nil
    local function render()
        clear_content()

        local items = type(options.texturepack_items) == "table"
                and options.texturepack_items[draft_settings.texturepack]
            or nil
        if type(items) ~= "table" or #items == 0 then
            content = GUI.TextBlock(
                GUI.RectTransform(Vector2(1, 1), row.RectTransform),
                "Preview items are not available yet.",
                nil,
                GUI.GUIStyle.SmallFont,
                GUI.Alignment.Center
            )
            return
        end

        content = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 1), row.RectTransform), true)
        content.Stretch = true
        content.RelativeSpacing = 0.04

        local selected_item_available = false
        for _, item in ipairs(items) do
            if item == selected_item then
                selected_item_available = true
                break
            end
        end
        if not selected_item_available then
            selected_item = items[1]
        end

        local dropdown = GUI.DropDown(GUI.RectTransform(Vector2(0.54, 1), content.RectTransform), selected_item, #items)

        local preview_box = GUI.Frame(GUI.RectTransform(Vector2(0.18, 1), content.RectTransform), nil)
        local caption = GUI.TextBlock(
            GUI.RectTransform(Vector2(0.24, 1), content.RectTransform),
            selected_item,
            nil,
            GUI.GUIStyle.SmallFont,
            GUI.Alignment.Center
        )

        local function render_icon()
            preview_box.ClearChildren()
            local icon_canvas = GUI.Frame(
                GUI.RectTransform(Point(ICON_SIZE, ICON_SIZE), preview_box.RectTransform, GUI.Anchor.Center),
                nil
            )

            local texturepack = type(options.texturepack_data) == "table"
                    and options.texturepack_data[draft_settings.texturepack]
                or nil
            local item_rect = find_item_rect(texturepack, selected_item)
            if texturepack == nil or item_rect == nil then
                return
            end

            create_image(
                icon_canvas,
                Sprite(texturepack.source_icons, source_rect(item_rect), Vector2(0.5, 0.5)),
                Vector2(1, 1),
                GUI.Anchor.Center
            )

            if type(draft_settings.overlays) ~= "table" or type(options.overlaypack_data) ~= "table" then
                return
            end

            for _, overlay in ipairs(draft_settings.overlays) do
                local overlaypack = options.overlaypack_data[overlay.overlaypack]
                local overlay_rect = find_overlay_rect(overlaypack, draft_settings.texturepack, selected_item)
                local anchor = SLOT_ANCHORS[overlay.slot]
                if overlaypack ~= nil and overlay_rect ~= nil and anchor ~= nil then
                    create_image(
                        icon_canvas,
                        Sprite(overlaypack.source, source_rect(overlay_rect), Vector2(0.5, 0.5)),
                        Vector2(overlay_rect.width / ICON_SIZE, overlay_rect.height / ICON_SIZE),
                        anchor
                    )
                end
            end
        end

        for index, item in ipairs(items) do
            dropdown.AddItem(item, item)
            if item == selected_item then
                dropdown.Select(index - 1)
            end
        end

        dropdown.OnSelected = function(_, user_data)
            if type(user_data) ~= "string" then
                return true
            end

            selected_item = user_data
            caption.Text = selected_item
            render_icon()
            return true
        end

        render_icon()
    end

    render()
    return render
end

return preview_section
