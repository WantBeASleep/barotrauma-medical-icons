---@class PreviewSection
---@field create fun(registry: Registry, parent: Barotrauma.GUIComponent, draft_settings: settings): fun()

local _, LUA_PATH = ...

---@type MenuUi
local ui = assert(loadfile(LUA_PATH .. "/menu/view/ui.lua"))(nil, LUA_PATH)

---@type PreviewRenderer
local preview_renderer = assert(loadfile(LUA_PATH .. "/menu/preview_renderer.lua"))(nil, LUA_PATH)

---@type PreviewSection
local preview_section = {}

local LARGE_PREVIEW_SCALE = 3
local SAMPLE_PREVIEW_SCALE = 1
local SAMPLE_COUNT = 6

---@param texturepack TexturepackAssets|nil
---@return string[]
---Extracts item names for the preview dropdown from the selected texturepack.
local function get_item_names(texturepack)
    local names = {}
    if texturepack == nil then
        return names
    end

    for _, item in ipairs(texturepack.item_atlas) do
        table.insert(names, item.item)
    end

    return names
end

---@param item_names string[]
---@param item_name string|nil
---@return boolean
---Checks whether the current selection is still present after texturepack changes.
local function has_item(item_names, item_name)
    if item_name == nil then
        return false
    end

    for _, available_item_name in ipairs(item_names) do
        if available_item_name == item_name then
            return true
        end
    end

    return false
end

---@param item_names string[]
---@param selected_item string|nil
---@return string|nil
---Keeps the current item when possible, otherwise picks a stable useful default.
local function choose_item(item_names, selected_item)
    if has_item(item_names, selected_item) then
        return selected_item
    end
    if has_item(item_names, "antidama1") then
        return "antidama1"
    end
    return item_names[1]
end

---@param parent Barotrauma.GUIComponent
---@param layer PreviewLayer
---@param scale integer
---Draws one source atlas rectangle into its planned 64px icon-space position.
local function draw_layer(parent, layer, scale)
    local sprite = Sprite(
        layer.atlas_path,
        Rectangle(layer.source_x, layer.source_y, layer.source_width, layer.source_height),
        Vector2(0.5, 0.5),
        0
    )

    local image = GUI.Image(
        GUI.RectTransform(
            Point(layer.target_width * scale, layer.target_height * scale),
            parent.RectTransform,
            GUI.Anchor.TopLeft,
            GUI.Pivot.TopLeft
        ),
        sprite,
        true
    )
    image.RectTransform.AbsoluteOffset = Point(layer.target_x * scale, layer.target_y * scale)
    image.CanBeFocused = false
end

---@param parent Barotrauma.GUIComponent
---@param plan PreviewRenderPlan|nil
---@param scale integer
---Composes the base icon and overlay layers inside a clipped preview viewport.
local function draw_preview(parent, plan, scale)
    local preview_box =
        GUI.ScissorComponent(GUI.RectTransform(Point(64 * scale, 64 * scale), parent.RectTransform, GUI.Anchor.Center))
    preview_box.CanBeFocused = false

    if plan == nil then
        return
    end

    draw_layer(preview_box.Content, plan.base, scale)
    for _, layer in ipairs(plan.overlays) do
        draw_layer(preview_box.Content, layer, scale)
    end
end

---@param registry Registry
---@param draft_settings settings
---@param item_names string[]
---@param selected_item string|nil
---@return string[]
---Builds the small preview strip, skipping items that cannot be rendered.
local function get_sample_items(registry, draft_settings, item_names, selected_item)
    local samples = {}
    if selected_item ~= nil then
        table.insert(samples, selected_item)
    end

    for _, item_name in ipairs(item_names) do
        if #samples >= SAMPLE_COUNT then
            break
        end
        if item_name ~= selected_item and preview_renderer.render(registry, draft_settings, item_name) ~= nil then
            table.insert(samples, item_name)
        end
    end

    return samples
end

---@param parent Barotrauma.GUIComponent
---@param registry Registry
---@param draft_settings settings
---@param item_name string
---@param on_selected fun(item_name: string)
---Creates one clickable sample tile for quickly switching the hero preview.
local function create_sample_cell(parent, registry, draft_settings, item_name, on_selected)
    local sample_cell =
        GUI.Button(GUI.RectTransform(Vector2(0.14, 1), parent.RectTransform), "", GUI.Alignment.Center, "InnerFrame")
    sample_cell.OnClicked = function()
        on_selected(item_name)
        return true
    end

    draw_preview(sample_cell, preview_renderer.render(registry, draft_settings, item_name), SAMPLE_PREVIEW_SCALE)
end

---@param registry Registry
---@param parent Barotrauma.GUIComponent
---@param draft_settings settings
---@return fun()
---Creates the preview panel and returns a refresh callback for external setting changes.
function preview_section.create(registry, parent, draft_settings)
    local frame = ui.frame(parent, Vector2(1, 1), "InnerFrameDark")
    local section = ui.layout(frame, Vector2(0.94, 0.9), false, 0.04, GUI.Anchor.Center, true)

    ---@type string|nil
    local selected_item

    -- The section is rebuilt instead of incrementally patched so dropdown state,
    -- selected texturepack name, hero preview, and sample strip stay in sync.
    local function refresh()
        section.ClearChildren()

        local texturepack = registry.texturepacks[draft_settings.texturepack]
        local item_names = get_item_names(texturepack)
        selected_item = choose_item(item_names, selected_item)

        local header = ui.layout(section, Vector2(1, 0.1), true, 0.03, GUI.Anchor.CenterLeft, false)
        ui.text(header, Vector2(0.5, 1), "Preview", GUI.Alignment.CenterLeft, 1.08, nil, Color(222, 216, 180, 255))
        ui.text(
            header,
            Vector2(0.48, 1),
            draft_settings.texturepack,
            GUI.Alignment.CenterRight,
            0.9,
            nil,
            Color(178, 198, 184, 230)
        )

        local choose_row = ui.layout(section, Vector2(1, 0.1), true, 0.03, GUI.Anchor.CenterLeft, false)
        ui.text(choose_row, Vector2(0.26, 1), "Item", GUI.Alignment.CenterLeft, 0.95)

        local dropdown = GUI.DropDown(
            GUI.RectTransform(Vector2(0.72, 1), choose_row.RectTransform),
            selected_item or "",
            math.max(1, #item_names)
        )
        for _, item_name in ipairs(item_names) do
            dropdown.AddItem(item_name, item_name)
        end
        if selected_item ~= nil then
            dropdown.SelectItem(selected_item)
        end

        dropdown.OnSelected = function(_, selected_item_name)
            selected_item = tostring(selected_item_name)
            refresh()
            return true
        end

        local hero = ui.frame(section, Vector2(1, 0.48), "InnerFrame", Color(12, 22, 21, 225))
        local plan = selected_item ~= nil and preview_renderer.render(registry, draft_settings, selected_item) or nil
        draw_preview(hero, plan, LARGE_PREVIEW_SCALE)

        local sample_frame = ui.frame(section, Vector2(1, 0.22), "InnerFrameDark", Color(17, 26, 24, 215))
        local sample_row = ui.layout(sample_frame, Vector2(0.92, 0.78), true, 0.035, GUI.Anchor.Center, false)
        for _, item_name in ipairs(get_sample_items(registry, draft_settings, item_names, selected_item)) do
            create_sample_cell(sample_row, registry, draft_settings, item_name, function(next_item_name)
                selected_item = next_item_name
                refresh()
            end)
        end

        ui.text(
            section,
            Vector2(1, 0.08),
            "Live composition: base icon + active overlays",
            GUI.Alignment.Center,
            0.82,
            nil,
            Color(168, 188, 176, 220)
        )
    end

    refresh()
    return refresh
end

return preview_section
