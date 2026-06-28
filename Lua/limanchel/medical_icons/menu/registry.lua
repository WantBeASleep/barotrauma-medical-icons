---@type string
local MOD_PATH

---@type string
local LUA_PATH

MOD_PATH, LUA_PATH = ...

---@type shemas
local shemas = dofile(LUA_PATH .. "/shemas.lua")

---@type FileLib
local file = dofile(LUA_PATH .. "/lib/file/init.lua")

---@class texturepack
---@field source_icons string
---@field source_sprites string
---@field mapping texturepack_mapping_item[]

---@class overlaypack
---@field source string
---@field mapping table<string, overlay_mapping_item[]>

---@class MenuRegistry
---@field texturepacks table<string, texturepack>
---@field overlaypacks table<string, overlaypack>
---@field overlay_rules overlay_rules
---@field init fun()

---@type MenuRegistry
local registry = {
    texturepacks = {},
    overlaypacks = {},
    overlay_rules = {},
}

---@param path string
---@return string
local function asset_path(path)
    return string.format("%s/assets/%s", MOD_PATH, path)
end

---@return string[]
local function load_texturepacks()
    return shemas.texturepacks_list.parse(file.read_all(asset_path("texturepacks/list.json")))
end

---@param texturepack string
---@return texturepack
local function load_texturepack(texturepack)
    return {
        source_icons = asset_path(string.format("texturepacks/%s/icons.png", texturepack)),
        source_sprites = asset_path(string.format("texturepacks/%s/sprites.png", texturepack)),
        mapping = shemas.texturepack_mapping.parse(
            file.read_all(asset_path(string.format("texturepacks/%s/mapping.json", texturepack)))
        ),
    }
end

---@param overlaypack string
---@param texturepack_rules table<string, overlay_rule_target>
---@return overlaypack
local function load_overlaypack(overlaypack, texturepack_rules)
    local mapping = {}

    for texturepack in pairs(texturepack_rules) do
        mapping[texturepack] = shemas.overlay_mapping.parse(
            file.read_all(asset_path(string.format("overlaypacks/%s/mapping/%s.json", overlaypack, texturepack)))
        )
    end

    return {
        source = asset_path(string.format("overlaypacks/%s/atlas.png", overlaypack)),
        mapping = mapping,
    }
end

---@return overlay_rules
local function load_overlay_rules()
    return shemas.overlay_rules.parse(file.read_all(asset_path("overlaypacks/rules.json")))
end

---@return nil
function registry.init()
    local overlay_rules = load_overlay_rules()

    local texturepacks_list = load_texturepacks()
    local texturepacks = {}
    ---@cast texturepacks table<string, texturepack>
    for _, texturepack_name in ipairs(texturepacks_list) do
        texturepacks[texturepack_name] = load_texturepack(texturepack_name)
    end

    local overlaypacks = {}
    ---@cast overlaypacks table<string, overlaypack>
    for overlaypack_name, texturepack_rules in pairs(overlay_rules) do
        overlaypacks[overlaypack_name] = load_overlaypack(overlaypack_name, texturepack_rules)
    end

    registry.texturepacks = texturepacks
    registry.overlaypacks = overlaypacks
    registry.overlay_rules = overlay_rules
end

return registry
