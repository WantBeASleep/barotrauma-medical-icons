---@type MenuSettings
local settings_manager

---@type MenuRegistry
local registry

---@type MenuView
local view

---@type Logger
local log

---@type Utils
local utils

-- The controller is the menu coordinator: it does not build GUI components or
-- persist settings itself, it only connects the settings model, registry data,
-- and view callbacks.
---@class MenuController
---@field init fun(settings: MenuSettings, menu_registry: MenuRegistry, menu_view: MenuView, logger: Logger, helper_utils: Utils)
---@field open fun()
---@field close fun()

---@type MenuController
local controller = {}

---@param settings MenuSettings
---@param menu_registry MenuRegistry
---@param menu_view MenuView
---@param logger Logger
---@param helper_utils Utils
function controller.init(settings, menu_registry, menu_view, logger, helper_utils)
    -- Non-context dependencies are injected during init so dofile only carries
    -- loader context such as MOD_PATH/LUA_PATH in modules that need paths.
    settings_manager = settings
    registry = menu_registry
    view = menu_view
    log = logger
    utils = helper_utils
end

---@return string[]
local function get_texturepack_names()
    -- Registry stores texturepacks as a lookup table. The view needs a stable,
    -- sorted array so the dropdown order does not depend on hash iteration.
    local names = {}
    for name in pairs(registry.texturepacks) do
        table.insert(names, name)
    end

    table.sort(names)
    return names
end

---@return string[]
local function get_overlaypack_names()
    local names = {}
    for name in pairs(registry.overlaypacks) do
        table.insert(names, name)
    end

    table.sort(names)
    return names
end

---@return table<string, string[]>
local function get_texturepack_items()
    local result = {}
    for texturepack_name, texturepack in pairs(registry.texturepacks) do
        local items = {}
        for _, item_atlas_item in ipairs(texturepack.item_atlas) do
            table.insert(items, item_atlas_item.item)
        end

        table.sort(items)
        result[texturepack_name] = items
    end

    return result
end

---@return table<string, texturepack>
local function get_texturepacks()
    return registry.texturepacks
end

---@return table<string, overlaypack>
local function get_overlaypacks()
    return registry.overlaypacks
end

---@param new_settings settings
---@return nil
local function validate_overlay_settings(new_settings)
    local occupied_slots = {}
    for _, overlay in ipairs(new_settings.overlays) do
        if occupied_slots[overlay.slot] == true then
            error("duplicate_overlay_slot", 0)
        end
        occupied_slots[overlay.slot] = true

        local texturepack_availability = registry.overlay_availability[overlay.overlaypack]
        if texturepack_availability == nil then
            error("unknown_overlaypack", 0)
        end

        local availability = texturepack_availability[new_settings.texturepack]
        if availability == nil or not utils.in_values(availability.slots, overlay.slot) then
            error("overlay_slot_not_allowed", 0)
        end
    end
end

function controller.close()
    view.close()
end

function controller.open()
    -- Open gets a fresh settings snapshot every time so abandoned draft changes
    -- in the view never mutate the active settings table.
    view.open({
        settings = settings_manager.safe_get_settings(),
        texturepacks = get_texturepack_names(),
        overlaypacks = get_overlaypack_names(),
        texturepack_data = get_texturepacks(),
        overlaypack_data = get_overlaypacks(),
        overlay_availability = registry.overlay_availability,
        texturepack_items = get_texturepack_items(),
        on_apply = function(new_settings)
            -- Keep validation and storage failures visible to callers such as
            -- pause_menu, while still logging the specific apply failure here.
            local apply_ok, apply_err = pcall(function()
                validate_overlay_settings(new_settings)
                settings_manager.safe_save(new_settings)
            end)
            if not apply_ok then
                log.error(string.format("settings apply failed: %s", tostring(apply_err)))
                error(apply_err)
            end

            view.close()
        end,
    })
end

return controller
