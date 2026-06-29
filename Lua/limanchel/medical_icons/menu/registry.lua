---@type string
local MOD_PATH

---@type string
local LUA_PATH

return function(mod_path, lua_path)
    MOD_PATH, LUA_PATH = mod_path, lua_path

    ---@type schemas
    local schema = assert(loadfile(LUA_PATH .. "/schema/init.lua"))(MOD_PATH, LUA_PATH)

    ---@type FileLib
    local file = dofile(LUA_PATH .. "/lib/file/init.lua")

    ---@class texturepack
    ---@field source_icons string
    ---@field source_sprites string
    ---@field item_atlas item_atlas_item[]

    ---@class overlaypack
    ---@field source string
    ---@field item_overlays table<string, item_overlay[]>
    ---@field overlay_atlas overlay_atlas_item[]

    ---@class MenuRegistry
    ---@field texturepacks table<string, texturepack>
    ---@field overlaypacks table<string, overlaypack>
    ---@field overlay_availability overlay_availability
    ---@field init fun()

    ---@type MenuRegistry
    local registry = {
        texturepacks = {},
        overlaypacks = {},
        overlay_availability = {},
    }

    ---@param path string
    ---@return string
    local function asset_path(path)
        return string.format("%s/assets/%s", MOD_PATH, path)
    end

    ---@return string[]
    local function load_texturepacks()
        return schema.texturepack_index.parse(file.read_all(asset_path("texturepacks/index.json")))
    end

    ---@param texturepack string
    ---@return texturepack
    local function load_texturepack(texturepack)
        return {
            source_icons = asset_path(string.format("texturepacks/%s/icons.png", texturepack)),
            source_sprites = asset_path(string.format("texturepacks/%s/sprites.png", texturepack)),
            item_atlas = schema.item_atlas.parse(
                file.read_all(asset_path(string.format("texturepacks/%s/item_atlas.json", texturepack)))
            ),
        }
    end

    ---@param overlaypack string
    ---@param texturepack_availability table<string, overlay_availability_target>
    ---@return overlaypack
    local function load_overlaypack(overlaypack, texturepack_availability)
        local item_overlays = {}

        for texturepack in pairs(texturepack_availability) do
            item_overlays[texturepack] = schema.item_overlays.parse(
                file.read_all(
                    asset_path(string.format("overlaypacks/%s/item_overlays/%s.json", overlaypack, texturepack))
                )
            )
        end

        return {
            source = asset_path(string.format("overlaypacks/%s/atlas.png", overlaypack)),
            item_overlays = item_overlays,
            overlay_atlas = schema.overlay_atlas.parse(
                file.read_all(asset_path(string.format("overlaypacks/%s/overlay_atlas.json", overlaypack)))
            ),
        }
    end

    ---@return overlay_availability
    local function load_overlay_availability()
        return schema.overlay_availability.parse(file.read_all(asset_path("overlaypacks/availability.json")))
    end

    ---@return nil
    function registry.init()
        local overlay_availability = load_overlay_availability()

        local texturepack_index = load_texturepacks()
        local texturepacks = {}
        ---@cast texturepacks table<string, texturepack>
        for _, texturepack_name in ipairs(texturepack_index) do
            texturepacks[texturepack_name] = load_texturepack(texturepack_name)
        end

        local overlaypacks = {}
        ---@cast overlaypacks table<string, overlaypack>
        for overlaypack_name, texturepack_availability in pairs(overlay_availability) do
            overlaypacks[overlaypack_name] = load_overlaypack(overlaypack_name, texturepack_availability)
        end

        registry.texturepacks = texturepacks
        registry.overlaypacks = overlaypacks
        registry.overlay_availability = overlay_availability
    end

    return registry
end
