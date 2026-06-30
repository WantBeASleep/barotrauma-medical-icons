local MOD_PATH, LUA_PATH = ...

---@type schemas
local schemas = assert(loadfile(LUA_PATH .. "/schema/init.lua"))(MOD_PATH, LUA_PATH)

---@type MenuUi
local ui = assert(loadfile(LUA_PATH .. "/menu/view/ui.lua"))(nil, LUA_PATH)

---@type MenuTitle
local title = assert(loadfile(LUA_PATH .. "/menu/view/components/title.lua"))(nil, LUA_PATH)

---@type SteamCallout
local steam_callout = assert(loadfile(LUA_PATH .. "/menu/view/components/steam_callout.lua"))(nil, LUA_PATH)

---@type TexturepackSection
local texturepack_section = assert(loadfile(LUA_PATH .. "/menu/view/components/texturepack_section.lua"))(nil, LUA_PATH)

---@type PreviewSection
local preview_section = assert(loadfile(LUA_PATH .. "/menu/view/components/preview_section.lua"))(nil, LUA_PATH)

---@type OverlaysSection
local overlays_section = assert(loadfile(LUA_PATH .. "/menu/view/components/overlays_section.lua"))(nil, LUA_PATH)

---@type MenuActions
local actions = assert(loadfile(LUA_PATH .. "/menu/view/components/actions.lua"))(nil, LUA_PATH)

---@class MenuContent
---@field create fun(registry: Registry, parent: Barotrauma.GUIComponent, draft_settings: settings, on_apply: fun(new_settings: settings), on_close: fun())

---@type MenuContent
local content = {}

---@param registry Registry
---@param parent Barotrauma.GUIComponent
---@param draft_settings settings
---@param on_apply fun(new_settings: settings)
---@param on_close fun()
function content.create(registry, parent, draft_settings, on_apply, on_close)
    local root = ui.frame(parent, Vector2(0.97, 0.96), nil, Color(8, 17, 16, 235))
    local root_layout = ui.layout(root, Vector2(0.96, 0.94), false, 0.024, GUI.Anchor.Center, true)

    local function rebuild()
        root_layout.ClearChildren()

        local title_frame = ui.frame(root_layout, Vector2(1, 0.075), nil, Color(0, 0, 0, 0))
        title.create(title_frame)

        local body_frame = ui.frame(root_layout, Vector2(1, 0.81), nil, Color(0, 0, 0, 0))
        local body = ui.layout(body_frame, Vector2(1, 1), true, 0.025, GUI.Anchor.TopLeft, false)

        local left = ui.layout(body, Vector2(0.56, 1), false, 0.025, GUI.Anchor.TopCenter, true)
        local right = ui.layout(body, Vector2(0.415, 1), false, 0, GUI.Anchor.TopCenter, true)

        local steam_frame = ui.frame(left, Vector2(1, 0.15), nil, Color(0, 0, 0, 0))
        steam_callout.create(steam_frame)

        local texturepack_frame = ui.frame(left, Vector2(1, 0.22), nil, Color(0, 0, 0, 0))
        local refresh_preview = preview_section.create(registry, right, draft_settings)

        texturepack_section.create(registry, texturepack_frame, draft_settings, function()
            refresh_preview()
        end)

        local overlays_frame = ui.frame(left, Vector2(1, 0.6), nil, Color(0, 0, 0, 0))
        overlays_section.create(registry, overlays_frame, draft_settings, function()
            refresh_preview()
        end)

        local actions_frame = ui.frame(root_layout, Vector2(1, 0.085), nil, Color(0, 0, 0, 0))
        actions.create(actions_frame, draft_settings, on_apply, on_close, function()
            draft_settings = schemas.settings.get_defaults()
            rebuild()
        end)
    end

    rebuild()
end

return content
