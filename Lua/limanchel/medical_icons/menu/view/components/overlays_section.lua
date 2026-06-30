local _, LUA_PATH = ...

---@type MenuUi
local ui = assert(loadfile(LUA_PATH .. "/menu/view/ui.lua"))(nil, LUA_PATH)

---@class OverlaysSection
---@field create fun(registry: Registry, parent: Barotrauma.GUIComponent, draft_settings: settings, on_changed: fun()): fun()

---@type OverlaysSection
local overlays_section = {}

---@class OverlayPosition
---@field label string
---@field x number|nil
---@field y number|nil

---@type OverlayPosition[]
-- Preset coordinates are expressed in icon-space. The renderer later clamps
-- right/bottom presets against the final overlay size, so 64 means "edge".
local POSITIONS = {
    { label = "top-left", x = 0, y = 0 },
    { label = "top-right", x = 64, y = 0 },
    { label = "bottom-left", x = 0, y = 64 },
    { label = "bottom-right", x = 64, y = 64 },
    { label = "custom" },
}

local CUSTOM_POSITION_INDEX = 5
local ROW_HEIGHT = 112

---@param value number
---@param min_value number
---@param max_value number
---@return number
---Keeps a numeric setting inside the slider/rendering bounds.
local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

---@param value number
---@return integer
---Rounds UI values for integer labels and pixel positions.
local function round(value)
    return math.floor(value + 0.5)
end

---@param value number
---@param step number
---@return number
---Moves a slider value onto the configured increment.
local function snap(value, step)
    return math.floor(value / step + 0.5) * step
end

---@param value number
---@param decimals integer
---@return string
---Formats the value label under each slider.
local function format_number(value, decimals)
    if decimals <= 0 then
        return tostring(round(value))
    end
    return string.format("%." .. tostring(decimals) .. "f", value)
end

---@param draft_settings settings
---@param overlaypack_name string
---@return integer|nil
---Finds an active overlaypack row by name, if it is already selected.
local function find_overlaypack_index(draft_settings, overlaypack_name)
    for index, overlaypack in ipairs(draft_settings.overlaypacks) do
        if overlaypack.name == overlaypack_name then
            return index
        end
    end
end

---@param registry Registry
---@param draft_settings settings
---@param current_name string|nil
---@return string[]
---Builds dropdown choices while preventing duplicate active overlaypacks.
---The current row's own name stays selectable so the dropdown remains stable.
local function get_available_overlaypack_names(registry, draft_settings, current_name)
    local names = {}
    for _, overlaypack_name in ipairs(registry.overlaypack_names) do
        if overlaypack_name == current_name or find_overlaypack_index(draft_settings, overlaypack_name) == nil then
            table.insert(names, overlaypack_name)
        end
    end
    return names
end

---@param setting overlaypack_setting
---@return integer
---Maps saved x/y coordinates back to a preset, falling back to custom.
local function get_position_index(setting)
    for index, position in ipairs(POSITIONS) do
        if position.x ~= nil and position.y ~= nil and setting.x == position.x and setting.y == position.y then
            return index
        end
    end
    return CUSTOM_POSITION_INDEX
end

---@param parent Barotrauma.GUIComponent
---@param label_text string
---@param value number
---@param min_value number
---@param max_value number
---@param step number
---@param decimals integer
---@param on_value_changed fun(value: number)
---@return Barotrauma.GUITextBlock
---Creates a labeled slider and wires it to mutate one setting field.
local function create_slider(parent, label_text, value, min_value, max_value, step, decimals, on_value_changed)
    local row = ui.layout(parent, Vector2(0.31, 1), false, 0.02, GUI.Anchor.Center, false)
    ui.text(row, Vector2(1, 0.32), label_text, GUI.Alignment.Center, 0.82, nil, Color(210, 205, 170, 245))

    local slider = GUI.ScrollBar(GUI.RectTransform(Vector2(1, 0.34), row.RectTransform), 0.08, nil, "GUISlider")
    slider.Range = Vector2(min_value, max_value)
    slider.StepValue = step
    slider.BarScrollValue = clamp(snap(value, step), min_value, max_value)

    local value_label = ui.text(
        row,
        Vector2(1, 0.26),
        format_number(slider.BarScrollValue, decimals),
        GUI.Alignment.Center,
        0.78,
        nil,
        Color(190, 220, 202, 230)
    )

    slider.OnMoved = function()
        local next_value = clamp(snap(slider.BarScrollValue, step), min_value, max_value)
        slider.BarScrollValue = next_value
        value_label.Text = format_number(next_value, decimals)
        on_value_changed(next_value)
        return true
    end

    return value_label
end

---@param registry Registry
---@param parent Barotrauma.GUIComponent
---@param draft_settings settings
---@param setting overlaypack_setting
---@param setting_index integer
---@param refresh fun()
---@param on_changed fun()
---Creates one editable overlay layer row in the list.
local function create_overlay_row(registry, parent, draft_settings, setting, setting_index, refresh, on_changed)
    local row_frame = GUI.Frame(GUI.RectTransform(Vector2(1, 0), parent.RectTransform), "InnerFrame")
    row_frame.RectTransform.IsFixedSize = true
    row_frame.RectTransform.NonScaledSize = Point(parent.Rect.Width, ROW_HEIGHT)
    row_frame.CanBeFocused = false
    row_frame.Color = Color(18, 29, 27, 220)

    local row = ui.layout(row_frame, Vector2(0.96, 0.82), false, 0.08, GUI.Anchor.Center, true)

    local top = ui.layout(row, Vector2(1, 0.38), true, 0.025, GUI.Anchor.CenterLeft, false)
    local available_names = get_available_overlaypack_names(registry, draft_settings, setting.name)
    local overlay_dropdown =
        GUI.DropDown(GUI.RectTransform(Vector2(0.41, 1), top.RectTransform), setting.name, #available_names)
    for _, overlaypack_name in ipairs(available_names) do
        overlay_dropdown.AddItem(overlaypack_name, overlaypack_name)
    end
    overlay_dropdown.SelectItem(setting.name)
    overlay_dropdown.OnSelected = function(_, selected_overlaypack_name)
        local next_name = tostring(selected_overlaypack_name)
        if setting.name ~= next_name and find_overlaypack_index(draft_settings, next_name) == nil then
            draft_settings.overlaypacks[setting_index].name = next_name
            refresh()
            on_changed()
        end
        return true
    end

    local position_dropdown = GUI.DropDown(GUI.RectTransform(Vector2(0.39, 1), top.RectTransform), "custom", #POSITIONS)
    for index, position in ipairs(POSITIONS) do
        position_dropdown.AddItem(position.label, index)
    end
    position_dropdown.Select(get_position_index(setting) - 1)

    local x_label
    local y_label

    -- Manual x/y edits make the position no longer match a named preset.
    local function select_custom_position()
        position_dropdown.Select(CUSTOM_POSITION_INDEX - 1)
    end

    position_dropdown.OnSelected = function(_, selected_position_index)
        local position = POSITIONS[tonumber(selected_position_index)]
        if position ~= nil and position.x ~= nil and position.y ~= nil then
            setting.x = position.x
            setting.y = position.y
            if x_label ~= nil then
                x_label.Text = tostring(setting.x)
            end
            if y_label ~= nil then
                y_label.Text = tostring(setting.y)
            end
            on_changed()
        end
        return true
    end

    ui.button(top, Vector2(0.12, 1), "X", "GUIButtonSmall", function()
        table.remove(draft_settings.overlaypacks, setting_index)
        refresh()
        on_changed()
        return true
    end)

    local sliders = ui.layout(row, Vector2(1, 0.5), true, 0.035, GUI.Anchor.CenterLeft, false)
    create_slider(sliders, "scale", setting.scale, 0, 3, 0.1, 1, function(value)
        setting.scale = value
        on_changed()
    end)

    x_label = create_slider(sliders, "x", setting.x, 0, 64, 1, 0, function(value)
        setting.x = value
        select_custom_position()
        on_changed()
    end)

    y_label = create_slider(sliders, "y", setting.y, 0, 64, 1, 0, function(value)
        setting.y = value
        select_custom_position()
        on_changed()
    end)
end

---@param registry Registry
---@param parent Barotrauma.GUIComponent
---@param draft_settings settings
---@param on_changed fun()
---@return fun()
---Creates the whole overlay section and returns a refresh callback.
function overlays_section.create(registry, parent, draft_settings, on_changed)
    local frame = ui.frame(parent, Vector2(1, 1), "InnerFrameDark")
    local section = ui.layout(frame, Vector2(0.96, 0.9), false, 0.04, GUI.Anchor.Center, true)

    local header = ui.layout(section, Vector2(1, 0.13), true, 0.03, GUI.Anchor.CenterLeft, false)
    ui.text(header, Vector2(0.52, 1), "Overlay layers", GUI.Alignment.CenterLeft, 1.02, nil, Color(222, 216, 180, 255))
    local count_label =
        ui.text(header, Vector2(0.21, 1), "", GUI.Alignment.Center, 0.84, nil, Color(215, 214, 172, 235))

    local add_button = ui.button(header, Vector2(0.23, 0.78), "+ ADD", "GUIButtonSmall", function()
        return true
    end)

    local list = GUI.ListBox(GUI.RectTransform(Vector2(1, 0.83), section.RectTransform), false, nil, nil)
    list.CanBeFocused = true
    list.OnSelected = function()
        return false
    end
    list.Spacing = 8
    list.AutoHideScrollBar = true
    list.KeepSpaceForScrollBar = true

    -- Rebuild rows after structural changes so indices and dropdown choices
    -- always reflect the current draft_settings.overlaypacks array.
    local function refresh()
        list.ClearChildren()
        count_label.Text = tostring(#draft_settings.overlaypacks) .. " active"

        for index, setting in ipairs(draft_settings.overlaypacks) do
            create_overlay_row(registry, list.Content, draft_settings, setting, index, refresh, on_changed)
        end

        add_button.Enabled = #get_available_overlaypack_names(registry, draft_settings, nil) > 0
    end

    add_button.OnClicked = function()
        local available_names = get_available_overlaypack_names(registry, draft_settings, nil)
        if #available_names > 0 then
            table.insert(draft_settings.overlaypacks, {
                name = available_names[1],
                x = 0,
                y = 0,
                scale = 1,
            })
            refresh()
            on_changed()
        end
        return true
    end

    refresh()
    return refresh
end

return overlays_section
