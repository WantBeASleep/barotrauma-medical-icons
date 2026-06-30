---@class TexturepackAssets
---@field name string
---@field path string
---@field icons_path string
---@field sprites_path string
---@field item_atlas item_atlas_item[]

---@class OverlaypackAssets
---@field name string
---@field path string
---@field atlas_path string
---@field overlay_atlas overlay_atlas_item[]
---@field item_overlays table<string, item_overlay[]>

---@class Registry
---@field assets_path string
---@field texturepack_names string[]
---@field overlaypack_names string[]
---@field texturepacks table<string, TexturepackAssets>
---@field overlaypacks table<string, OverlaypackAssets>
---@field init fun()

local MOD_PATH, LUA_PATH = ...

local ASSETS_PATH = MOD_PATH .. "/assets"
local TEXTUREPACKS_PATH = ASSETS_PATH .. "/texturepacks"
local OVERLAYPACKS_PATH = ASSETS_PATH .. "/overlaypacks"

---@type FileLib
local file = dofile(LUA_PATH .. "/lib/file/init.lua")

---@type schemas
local schemas = assert(loadfile(LUA_PATH .. "/schema/init.lua"))(MOD_PATH, LUA_PATH)

---@type Registry
local registry = {
    assets_path = ASSETS_PATH,
    texturepack_names = {},
    overlaypack_names = {},
    texturepacks = {},
    overlaypacks = {},
}

---@param texturepack_name string
---@return TexturepackAssets
local function load_texturepack(texturepack_name)
    local texturepack_path = TEXTUREPACKS_PATH .. "/" .. texturepack_name

    return {
        name = texturepack_name,
        path = texturepack_path,
        icons_path = texturepack_path .. "/icons.png",
        sprites_path = texturepack_path .. "/sprites.png",
        item_atlas = schemas.item_atlas.parse(file.read_all(texturepack_path .. "/item_atlas.json")),
    }
end

---@param overlaypack_name string
---@param texturepack_names string[]
---@return OverlaypackAssets
local function load_overlaypack(overlaypack_name, texturepack_names)
    local overlaypack_path = OVERLAYPACKS_PATH .. "/" .. overlaypack_name
    local item_overlays = {}

    for _, texturepack_name in ipairs(texturepack_names) do
        local item_overlays_path = string.format("%s/item_overlays/%s.json", overlaypack_path, texturepack_name)
        item_overlays[texturepack_name] = schemas.item_overlays.parse(file.read_all(item_overlays_path))
    end

    return {
        name = overlaypack_name,
        path = overlaypack_path,
        atlas_path = overlaypack_path .. "/atlas.png",
        overlay_atlas = schemas.overlay_atlas.parse(file.read_all(overlaypack_path .. "/overlay_atlas.json")),
        item_overlays = item_overlays,
    }
end

function registry.init()
    registry.texturepack_names = schemas.texturepack_index.parse(file.read_all(TEXTUREPACKS_PATH .. "/index.json"))
    registry.overlaypack_names = schemas.overlaypack_index.parse(file.read_all(OVERLAYPACKS_PATH .. "/index.json"))
    registry.texturepacks = {}
    registry.overlaypacks = {}

    for _, texturepack_name in ipairs(registry.texturepack_names) do
        registry.texturepacks[texturepack_name] = load_texturepack(texturepack_name)
    end

    for _, overlaypack_name in ipairs(registry.overlaypack_names) do
        registry.overlaypacks[overlaypack_name] = load_overlaypack(overlaypack_name, registry.texturepack_names)
    end
end

return registry
