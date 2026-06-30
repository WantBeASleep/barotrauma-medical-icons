local _, _, log = ...

---@type SafeSettings
local settings_manager

---@type MenuView
local view

-- The controller is the menu coordinator: it does not build GUI components or
-- persist settings itself, it only connects the settings model, registry data,
-- and view callbacks.
---@class MenuController
---@field init fun(settings: SafeSettings, menu_view: MenuView)
---@field open fun()
---@field close fun()

---@type MenuController
local controller = {}

---@param settings SafeSettings
---@param menu_view MenuView
function controller.init(settings, menu_view)
    -- Runtime collaborators are injected during init; shared technical context
    -- such as the logger arrives through the loader call.
    settings_manager = settings
    view = menu_view
end

function controller.close()
    view.close()
end

function controller.open()
    view.open(settings_manager.safe_get_settings(), function(new_settings)
        -- Keep validation and storage failures visible to callers such as
        -- pause_menu, while still logging the specific apply failure here.
        local apply_ok, apply_err = pcall(function()
            settings_manager.safe_save(new_settings)
        end)
        if not apply_ok then
            log.error(string.format("settings apply failed: %s", tostring(apply_err)))
            error(apply_err)
        end
    end)
end

return controller
