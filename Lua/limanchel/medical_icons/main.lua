---@type Logger
local log

---@type string
local MOD_PATH

---@type string
local SOURCE_PATH

MOD_PATH, SOURCE_PATH = ...

---@type Config
local config = dofile(SOURCE_PATH .. "/config.lua")
---@type Atlases
local atlases = dofile(SOURCE_PATH .. "/generated/atlases.lua")

---@class MedicalIcons
---@field apply fun(logger: Logger) Applies new icons and sprites to prefabs and registers holdable settings for newly created items.
---@field apply_existing_item_holdable_settings fun() DEV only. Iterates all existing items and applies holdable settings to them.

---@type MedicalIcons
---@diagnostic disable-next-line: missing-fields
local medical_icons = {}

local function make_sprite_init_accessible()
    local sprite_descriptor = LuaUserData["Barotrauma.Sprite"]
    LuaUserData.MakeMethodAccessible(sprite_descriptor, "Init")
end

-- Overriders predab icon and sprite
---@param prefab Barotrauma.ItemPrefab
---@param atlas_item AtlasItem
local function override_prefab_sprites(prefab, atlas_item)
    ---@diagnostic disable-next-line: invisible // private Init expose earlier
    prefab.InventoryIcon.Init(
        string.format("%s/%s", MOD_PATH, atlases.assets.icons),
        Rectangle(table.unpack(atlas_item.icon.rect)),
        config.defaults.icon_origin,
        nil,
        config.defaults.sprite_rotation
    )

    ---@diagnostic disable-next-line: invisible // private Init expose earlier
    prefab.Sprite.Init(
        string.format("%s/%s", MOD_PATH, atlases.assets.sprites),
        Rectangle(table.unpack(atlas_item.sprite.rect)),
        config.defaults.sprite_origin,
        nil,
        config.defaults.sprite_rotation
    )
    prefab.Sprite.Depth = config.defaults.sprite_depth
end

---@param item Barotrauma.Item
local function apply_item_hold_settings(item)
    if item == nil then
        error("item is nil")
    end

    if item.Prefab == nil then
        error("prefab is nil")
    end

    local identifier = item.Prefab.Identifier.Value
    if identifier == nil or identifier == "" then
        error("item prefab identifier is nil or empty")
    end

    local atlas_item = atlases.items[identifier]
    -- If atlas hasnt this item, skipping
    if atlas_item == nil then
        return
    end

    local texture_data = config.textures[atlas_item.texture]
    -- No special config for this item, skipping
    if texture_data == nil then
        return
    end

    local holdable_data = texture_data.holdable
    -- No holdable config for this item, skipping
    if holdable_data == nil then
        return
    end

    local holdable = Game.GetHoldableComponent(item)
    if holdable == nil then
        error(string.format("item '%s' not has holdable component", identifier))
    end

    if holdable_data.hold_angle ~= nil then
        holdable.HoldAngle = holdable_data.hold_angle
    end

    if holdable_data.handle1 ~= nil then
        holdable.Handle1 = holdable_data.handle1
    end

    if holdable_data.handle2 ~= nil then
        holdable.Handle2 = holdable_data.handle2
    end
end

local function register_item_holdable_settings_hook()
    Hook.Add("item.created", "medical_icons.holdable_settings", function(item)
        ---@cast item Barotrauma.Item
        local ok, err = pcall(apply_item_hold_settings, item)
        if not ok then
            log.warn(string.format("hook item.created: apply holdable settings to item: %s", err))
        end

        return item
    end)
end

---DEV only.
---
---Iterates all existing items and applies holdable settings to them.
---@return nil
function medical_icons.apply_existing_item_holdable_settings()
    local applied_count = 0

    ---@diagnostic disable-next-line: param-type-mismatch
    for _, item in pairs(Item.ItemList) do
        ---@cast item Barotrauma.Item
        local ok, err = pcall(apply_item_hold_settings, item)
        if not ok then
            log.warn(string.format("existing item list: apply holdable settings to item: %s", err))
        end
        applied_count = applied_count + 1
    end

    log.debug(string.format("hold settings checked for %d existing items", applied_count))
end

---Applies new icons and sprites to prefabs.
---
---Registers an item.created hook for holdable settings.
---@param logger Logger
---@return nil
function medical_icons.apply(logger)
    log = logger

    make_sprite_init_accessible()
    register_item_holdable_settings_hook()

    for identifier, item in pairs(atlases.items) do
        local prefab = Game.GetItemPrefab(identifier)

        if prefab == nil then
            log.warn(string.format("Item prefab '%s' not found; skipping icon and sprite override", identifier))
            goto continue
        end

        override_prefab_sprites(prefab, item)

        ::continue::
    end

    log.info("Icons && Sprites successfully loaded!")
end

return medical_icons
