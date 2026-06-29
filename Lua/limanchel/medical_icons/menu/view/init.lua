---@class MenuViewOpenOptions
---@field settings settings
---@field texturepacks string[]
---@field overlaypacks string[]|nil
---@field texturepack_data table<string, texturepack>|nil
---@field overlaypack_data table<string, overlaypack>|nil
---@field overlay_availability overlay_availability|nil
---@field texturepack_items table<string, string[]>|nil
---@field on_apply fun(new_settings: settings)

---@class MenuView
---@field open fun(options: MenuViewOpenOptions)
---@field close fun()

---@param lua_path string
return function(lua_path)
    local texturepack_section = dofile(lua_path .. "/menu/view/texturepack_section.lua")
    local overlays_section = dofile(lua_path .. "/menu/view/overlays_section.lua")
    local preview_section = dofile(lua_path .. "/menu/view/preview_section.lua")

    ---@type MenuView
    local view = {}

    local menu_frame = nil

    -- Removes only this mod's menu window. The pause-menu button is managed by
    -- pause_menu.lua because it belongs to the pause menu list.
    function view.close()
        if menu_frame ~= nil and menu_frame.Parent ~= nil then
            menu_frame.Parent.RemoveChild(menu_frame)
        end

        menu_frame = nil
    end

    ---@param settings settings
    ---@return settings
    local function copy_settings(settings)
        local result = {
            version = settings.version,
            texturepack = settings.texturepack,
            overlays = {},
        }

        if type(settings.overlays) == "table" then
            for _, overlay in ipairs(settings.overlays) do
                table.insert(result.overlays, {
                    overlaypack = overlay.overlaypack,
                    slot = overlay.slot,
                })
            end
        end

        return result
    end

    -- Builds the settings window from the current settings state.
    ---@param options MenuViewOpenOptions
    function view.open(options)
        if GUI.PauseMenu == nil then
            return
        end

        view.close()

        local draft_settings = copy_settings(options.settings)

        menu_frame = GUI.Frame(GUI.RectTransform(Vector2(0.56, 0.64), GUI.PauseMenu.RectTransform, GUI.Anchor.Center))

        local layout =
            GUI.LayoutGroup(GUI.RectTransform(Vector2(0.9, 0.86), menu_frame.RectTransform, GUI.Anchor.Center), false)
        layout.Stretch = true
        layout.RelativeSpacing = 0.025

        GUI.TextBlock(
            GUI.RectTransform(Vector2(1, 0.13), layout.RectTransform),
            "Medical Icons",
            nil,
            GUI.GUIStyle.LargeFont,
            GUI.Alignment.Center
        )

        local refresh_overlays = function() end
        local refresh_preview = function() end

        texturepack_section.create(options, layout, draft_settings, function()
            refresh_overlays()
            refresh_preview()
        end)
        refresh_overlays = overlays_section.create(options, layout, draft_settings, function()
            refresh_preview()
        end)
        refresh_preview = preview_section.create(options, layout, draft_settings)

        local button_row = GUI.LayoutGroup(GUI.RectTransform(Vector2(1, 0.12), layout.RectTransform), true)
        button_row.Stretch = true
        button_row.RelativeSpacing = 0.04

        local apply_button = GUI.Button(GUI.RectTransform(Vector2(0.48, 1), button_row.RectTransform), "Apply")
        apply_button.OnClicked = function()
            options.on_apply(copy_settings(draft_settings))
            return true
        end

        local close_button = GUI.Button(GUI.RectTransform(Vector2(0.48, 1), button_row.RectTransform), "Close")
        close_button.OnClicked = function()
            view.close()
            return true
        end
    end

    return view
end
