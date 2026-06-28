---@type MenuController
local controller

---@type Logger
local log

-- pause_menu.lua is loaded as a small adapter around Barotrauma's built-in
-- ESC pause menu. The real Medical Icons settings window is owned by the
-- controller/view pair; this module only adds and synchronizes the entry button.
controller, log = ...

---@class PauseMenu
---@field force_open fun()
---@field sync_button fun()

---@type PauseMenu
local pause_menu = {}

---@type Barotrauma.GUIButton|nil
local menu_button = nil

-- UserData is used as a stable tag in Barotrauma's GUI tree. If Lua loses its
-- cached menu_button reference, the sync code can still find an existing button
-- and avoid adding duplicates.
local PAUSE_MENU_BUTTON_USER_DATA = "MedicalIconsMenuButton"
local PAUSE_MENU_LIST_USER_DATA = "PauseMenuList"

-- Pause menu buttol label
local PAUSE_MENU_BUTTON_LABEL = "Medical Icons"

---@param component Barotrauma.GUIComponent
---@return Barotrauma.GUIComponent[]
local function get_children(component)
    local children = {}
    for child in component.GetAllChildren() do
        table.insert(children, child)
    end

    return children
end

-- Finds the central button list inside Barotrauma's ESC pause menu.
---@return Barotrauma.GUIComponent|nil
local function find_pause_menu_list()
    if GUI.PauseMenu == nil then
        return nil
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    local pause_menu_list = GUI.PauseMenu.FindChild(PAUSE_MENU_LIST_USER_DATA)
    if pause_menu_list ~= nil then
        return pause_menu_list
    end

    -- Fallback for game builds or UI states where the named child is missing.
    -- The expected structure is GUI.PauseMenu -> frame children -> button list.
    local frame_children = get_children(GUI.PauseMenu)
    if #frame_children <= 1 then
        return nil
    end

    local second_child_children = get_children(frame_children[2])
    if #second_child_children > 0 then
        return second_child_children[1]
    end

    return nil
end

-- Opens the vanilla pause menu first because the Medical Icons settings window
-- is attached to GUI.PauseMenu by view.lua.
function pause_menu.force_open()
    if not GUI.PauseMenuOpen then
        ---@diagnostic disable-next-line: invisible
        GUI.TogglePauseMenu()
    end

    if GUI.PauseMenuOpen then
        controller.open()
    end
end

-- Keeps the Medical Icons entry button in sync with the lifetime of the
-- vanilla pause menu. This is called after GUI.TogglePauseMenu is patched in
-- menu/init.lua.
function pause_menu.sync_button()
    if GUI.PauseMenuOpen then
        local pause_menu_list = find_pause_menu_list()
        if pause_menu_list == nil then
            log.warn("pause menu list not found; Medical Icons button was not added")
            return
        end

        -- Fast path: our cached button still belongs to the active GUI tree.
        if menu_button ~= nil and menu_button.Parent ~= nil then
            return
        end

        -- Recovery path: the Lua cache is empty/stale, but the GUI tree may
        -- still contain a button from a previous sync call.
        for child in pause_menu_list.Children do
            if child.UserData == PAUSE_MENU_BUTTON_USER_DATA then
                ---@cast child Barotrauma.GUIButton
                menu_button = child
                return
            end
        end

        menu_button = GUI.Button(
            GUI.RectTransform(Vector2(1, 0.1), pause_menu_list.RectTransform),
            ---@diagnostic disable-next-line: param-type-mismatch
            PAUSE_MENU_BUTTON_LABEL,
            GUI.Alignment.Center,
            "GUIButtonSmall"
        )
        ---@diagnostic disable-next-line: assign-type-mismatch
        menu_button.UserData = PAUSE_MENU_BUTTON_USER_DATA
        menu_button.OnClicked = function()
            local ok, err = pcall(controller.open)
            if not ok then
                log.error(string.format("menu open failed: %s", tostring(err)))
            end

            return true
        end
    else
        -- The settings window is parented to the pause menu, so closing the
        -- vanilla menu should also close any open Medical Icons window.
        controller.close()
        menu_button = nil
    end
end

return pause_menu
