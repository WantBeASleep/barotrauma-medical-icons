---@type MenuSettings
local settings_manager

---@type MenuRegistry
local registry

---@type MenuView
local view

---@type Logger
local log

-- The controller is the menu coordinator: it does not build GUI components or
-- persist settings itself, it only connects the settings model, registry data,
-- and view callbacks.
---@class MenuController
---@field init fun(settings: MenuSettings, menu_registry: MenuRegistry, menu_view: MenuView, logger: Logger)
---@field open fun()
---@field close fun()

---@type MenuController
local controller = {}

---@param settings MenuSettings
---@param menu_registry MenuRegistry
---@param menu_view MenuView
---@param logger Logger
function controller.init(settings, menu_registry, menu_view, logger)
    -- Non-context dependencies are injected during init so dofile only carries
    -- loader context such as MOD_PATH/LUA_PATH in modules that need paths.
    settings_manager = settings
    registry = menu_registry
    view = menu_view
    log = logger
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

function controller.close()
    view.close()
end

function controller.open()
    -- Open gets a fresh settings snapshot every time so abandoned draft changes
    -- in the view never mutate the active settings table.
    view.open({
        settings = settings_manager.safe_get_settings(),
        texturepacks = get_texturepack_names(),
        on_apply = function(new_settings)
            -- Keep validation and storage failures visible to callers such as
            -- pause_menu, while still logging the specific apply failure here.
            local apply_ok, apply_err = pcall(function()
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
