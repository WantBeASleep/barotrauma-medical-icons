---@alias OverlaySlot
---| '"top-left"'
---| '"top-right"'
---| '"bottom-left"'
---| '"bottom-right"'

---@class OverlayDraft
---@field overlaypack string
---@field slot OverlaySlot

---@class OverlayOption
---@field name string
---@field slots OverlaySlot[]

---@class OverlaysSection
---@field create fun(options: MenuViewOpenOptions, parent: Barotrauma.GUIComponent, draft_settings: settings, on_change: fun()|nil): fun()

local SLOT_LABELS = {
    ["top-left"] = "Top left",
    ["top-right"] = "Top right",
    ["bottom-left"] = "Bottom left",
    ["bottom-right"] = "Bottom right",
}

local DEFAULT_SLOTS = {
    "top-left",
    "top-right",
    "bottom-left",
    "bottom-right",
}

---@type OverlaysSection
local overlays_section = {}

---@param options MenuViewOpenOptions
---@return boolean
local function has_overlay_data(options)
    return type(options.overlaypacks) == "table" and type(options.overlay_availability) == "table"
end

---@param overlays OverlayDraft[]|nil
---@param skipped_index integer|nil
---@return table<string, boolean>
local function get_occupied_slots(overlays, skipped_index)
    local occupied = {}
    if type(overlays) ~= "table" then
        return occupied
    end

    for index, overlay in ipairs(overlays) do
        if index ~= skipped_index and type(overlay.slot) == "string" then
            occupied[overlay.slot] = true
        end
    end

    return occupied
end

---@param slots OverlaySlot[]
---@param occupied_slots table<string, boolean>
---@param current_slot OverlaySlot|nil
---@return OverlaySlot[]
local function filter_available_slots(slots, occupied_slots, current_slot)
    local result = {}
    for _, slot in ipairs(slots) do
        if occupied_slots[slot] ~= true or slot == current_slot then
            table.insert(result, slot)
        end
    end

    return result
end

---@param slots OverlaySlot[]
---@param slot OverlaySlot|nil
---@return boolean
local function has_slot(slots, slot)
    if slot == nil then
        return false
    end

    for _, item in ipairs(slots) do
        if item == slot then
            return true
        end
    end

    return false
end

---@param options MenuViewOpenOptions
---@param texturepack string
---@return OverlayOption[]
local function get_overlay_options(options, texturepack)
    local overlay_options = {}
    if type(options.overlaypacks) ~= "table" or type(options.overlay_availability) ~= "table" then
        return overlay_options
    end

    for _, overlaypack in ipairs(options.overlaypacks) do
        local texturepack_availability = options.overlay_availability[overlaypack]
        local availability = type(texturepack_availability) == "table" and texturepack_availability[texturepack] or nil
        if type(availability) == "table" and type(availability.slots) == "table" and #availability.slots > 0 then
            table.insert(overlay_options, {
                name = overlaypack,
                slots = availability.slots,
            })
        end
    end

    return overlay_options
end

---@param overlay_options OverlayOption[]
---@param name string|nil
---@return OverlayOption|nil
local function get_overlay_option(overlay_options, name)
    if type(name) ~= "string" then
        return nil
    end

    for _, option in ipairs(overlay_options) do
        if option.name == name then
            return option
        end
    end

    return nil
end

---@param overlay_options OverlayOption[]
---@param name string|nil
---@return OverlaySlot[]
local function get_slots(overlay_options, name)
    if type(name) ~= "string" then
        return DEFAULT_SLOTS
    end

    for _, option in ipairs(overlay_options) do
        if option.name == name then
            return option.slots
        end
    end

    return DEFAULT_SLOTS
end

---@param overlay_options OverlayOption[]
---@param occupied_slots table<string, boolean>
---@return OverlayDraft|nil
local function first_available_overlay(overlay_options, occupied_slots)
    for _, option in ipairs(overlay_options) do
        local slots = filter_available_slots(option.slots, occupied_slots, nil)
        if #slots > 0 then
            return {
                overlaypack = option.name,
                slot = slots[1],
            }
        end
    end

    return nil
end

---@param overlays OverlayDraft[]
---@param overlay_options OverlayOption[]
local function normalize_overlays(overlays, overlay_options)
    local occupied_slots = {}
    local index = 1
    while index <= #overlays do
        local overlay = overlays[index]
        local option = get_overlay_option(overlay_options, overlay.overlaypack)

        if option == nil then
            table.remove(overlays, index)
        else
            local slots = filter_available_slots(option.slots, occupied_slots, overlay.slot)
            if #slots == 0 then
                table.remove(overlays, index)
            else
                if not has_slot(slots, overlay.slot) then
                    overlay.slot = slots[1]
                end

                occupied_slots[overlay.slot] = true
                index = index + 1
            end
        end
    end
end

---@param draft_settings settings
---@return OverlayDraft[]|nil
local function get_draft_overlays(draft_settings)
    if type(draft_settings.overlays) ~= "table" then
        return nil
    end

    return draft_settings.overlays
end

---@param row_list Barotrauma.GUIComponent
---@param rows Barotrauma.GUIComponent[]
local function clear_rows(row_list, rows)
    for _, row in ipairs(rows) do
        if row.Parent ~= nil then
            row_list.RemoveChild(row)
        end
    end

    for index in ipairs(rows) do
        rows[index] = nil
    end
end

---@param options MenuViewOpenOptions
---@param parent Barotrauma.GUIComponent
---@param draft_settings settings
---@param on_change fun()|nil
---@return fun()
function overlays_section.create(options, parent, draft_settings, on_change)
    local section = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.28), parent.RectTransform), false)
    section.Stretch = true
    section.RelativeSpacing = 0.03

    local header = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.2), section.RectTransform), true)
    header.Stretch = true
    header.RelativeSpacing = 0.04

    GUI.TextBlock(
        GUI.RectTransform(Vector2(0.76, 1), header.RectTransform),
        "Overlays",
        nil,
        GUI.GUIStyle.SmallFont,
        GUI.Alignment.CenterLeft
    )

    local rows = {}
    local row_list = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.54), section.RectTransform), false)
    row_list.Stretch = true
    row_list.RelativeSpacing = 0.03

    local overlays = get_draft_overlays(draft_settings)
    local overlay_options = get_overlay_options(options, draft_settings.texturepack)

    local add_button = GUI.Button(GUI.RectTransform(Vector2(0.1, 1), header.RectTransform), "+")
    local remove_button = GUI.Button(GUI.RectTransform(Vector2(0.1, 1), header.RectTransform), "-")

    ---@return nil
    local render_rows

    render_rows = function()
        clear_rows(row_list, rows)

        overlays = get_draft_overlays(draft_settings)
        overlay_options = get_overlay_options(options, draft_settings.texturepack)
        if overlays == nil then
            table.insert(
                rows,
                GUI.TextBlock(
                    GUI.RectTransform(Vector2(1, 1), row_list.RectTransform),
                    "Overlay settings are not available yet.",
                    nil,
                    GUI.GUIStyle.SmallFont,
                    GUI.Alignment.Center
                )
            )
            return
        end

        if not has_overlay_data(options) then
            table.insert(
                rows,
                GUI.TextBlock(
                    GUI.RectTransform(Vector2(1, 1), row_list.RectTransform),
                    "Overlay options are not available yet.",
                    nil,
                    GUI.GUIStyle.SmallFont,
                    GUI.Alignment.Center
                )
            )
            return
        end

        normalize_overlays(overlays, overlay_options)
        if #overlay_options == 0 then
            table.insert(
                rows,
                GUI.TextBlock(
                    GUI.RectTransform(Vector2(1, 1), row_list.RectTransform),
                    "No overlays are available for this texturepack.",
                    nil,
                    GUI.GUIStyle.SmallFont,
                    GUI.Alignment.Center
                )
            )
            return
        end

        if #overlays == 0 then
            table.insert(
                rows,
                GUI.TextBlock(
                    GUI.RectTransform(Vector2(1, 1), row_list.RectTransform),
                    "No overlays selected.",
                    nil,
                    GUI.GUIStyle.SmallFont,
                    GUI.Alignment.Center
                )
            )
            return
        end

        for index, overlay in ipairs(overlays) do
            local occupied_slots = get_occupied_slots(overlays, index)
            local slots =
                filter_available_slots(get_slots(overlay_options, overlay.overlaypack), occupied_slots, overlay.slot)
            if not has_slot(slots, overlay.slot) then
                overlay.slot = slots[1]
            end

            local row = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.48), row_list.RectTransform), true)
            row.Stretch = true
            row.RelativeSpacing = 0.04
            table.insert(rows, row)

            local overlay_dropdown = GUI.DropDown(
                GUI.RectTransform(Vector2(0.58, 1), row.RectTransform),
                overlay.overlaypack,
                math.max(#overlay_options, 1)
            )

            local selected_overlay_index = 1
            for option_index, option in ipairs(overlay_options) do
                overlay_dropdown.AddItem(option.name, option.name)
                if option.name == overlay.overlaypack then
                    selected_overlay_index = option_index
                end
            end

            overlay_dropdown.Select(selected_overlay_index - 1)
            overlay_dropdown.OnSelected = function(_, user_data)
                if type(user_data) ~= "string" or user_data == overlay.overlaypack then
                    return true
                end

                overlay.overlaypack = user_data
                local next_slots = filter_available_slots(
                    get_slots(overlay_options, overlay.overlaypack),
                    get_occupied_slots(overlays, index),
                    overlay.slot
                )
                if not has_slot(next_slots, overlay.slot) then
                    overlay.slot = next_slots[1]
                end
                render_rows()
                if on_change ~= nil then
                    on_change()
                end
                return true
            end

            local slot_dropdown =
                GUI.DropDown(GUI.RectTransform(Vector2(0.38, 1), row.RectTransform), overlay.slot, #slots)
            local selected_slot_index = 1
            for slot_index, slot in ipairs(slots) do
                slot_dropdown.AddItem(SLOT_LABELS[slot] or slot, slot)
                if slot == overlay.slot then
                    selected_slot_index = slot_index
                end
            end

            slot_dropdown.Select(selected_slot_index - 1)
            slot_dropdown.OnSelected = function(_, user_data)
                if type(user_data) ~= "string" or user_data == overlay.slot then
                    return true
                end

                overlays[index].slot = user_data
                if on_change ~= nil then
                    on_change()
                end
                return true
            end
        end
    end

    add_button.OnClicked = function()
        overlays = get_draft_overlays(draft_settings)
        overlay_options = get_overlay_options(options, draft_settings.texturepack)
        local overlay = first_available_overlay(overlay_options, get_occupied_slots(overlays, nil))
        if overlays == nil or overlay == nil then
            return true
        end

        table.insert(overlays, overlay)
        render_rows()
        if on_change ~= nil then
            on_change()
        end
        return true
    end

    remove_button.OnClicked = function()
        overlays = get_draft_overlays(draft_settings)
        if overlays == nil or #overlays == 0 then
            return true
        end

        table.remove(overlays)
        render_rows()
        if on_change ~= nil then
            on_change()
        end
        return true
    end

    render_rows()
    return render_rows
end

return overlays_section
