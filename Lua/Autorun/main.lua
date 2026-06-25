if not CLIENT then return end

local mod_path = ...
local log = require("limanchel.medical_icons.lib.logger")
log.init("QoL - Medical Items", log.levels.debug)

local data = require("limanchel.medical_icons.data")
local atlases = require("limanchel.medical_icons.generated.atlases")

-- expose sprite Init() method
local sprite_descriptor = LuaUserData["Barotrauma.Sprite"]
LuaUserData.MakeMethodAccessible(sprite_descriptor, "Init")

for identifier, item in pairs(atlases.items) do
    local prefab = Game.GetItemPrefab(identifier)

    -- skip wrong identifier
    if prefab == nil then
        log.warn(string.format("Item prefab '%s' not found; skipping icon and sprite override", identifier))
        goto continue
    end

    ---@diagnostic disable-next-line: invisible // private Init expose earlier
    prefab.InventoryIcon.Init(
        mod_path .. "/" .. atlases.assets.icons,
        Rectangle(table.unpack(item.icon.rect)),
        data.defaults.icon_origin,
        nil,
        data.defaults.sprite_rotation
    )

    ---@diagnostic disable-next-line: invisible // private Init expose earlier
    prefab.Sprite.Init(
        mod_path .. "/" .. atlases.assets.sprites,
        Rectangle(table.unpack(item.sprite.rect)),
        data.defaults.sprite_origin,
        nil,
        data.defaults.sprite_rotation
    )
    prefab.Sprite.Depth = data.defaults.sprite_depth

    ::continue::
end

log.info("Icons && Sprites successfully loaded!")
