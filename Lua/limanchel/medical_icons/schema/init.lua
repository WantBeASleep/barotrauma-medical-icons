---@class schemas
---@field settings settings_schema
---@field texturepack_index name_list_schema
---@field overlaypack_index name_list_schema
---@field item_atlas item_atlas_schema
---@field item_overlays item_overlays_schema
---@field overlay_atlas overlay_atlas_schema
---@field overlay_availability overlay_availability_schema

local MOD_PATH, LUA_PATH = ...

---@param name string
---@return table
local function load_schema(name)
    return assert(loadfile(string.format("%s/schema/%s.lua", LUA_PATH, name)))(MOD_PATH, LUA_PATH)
end

---@type schemas
return {
    settings = load_schema("settings"),
    texturepack_index = load_schema("name_list"),
    overlaypack_index = load_schema("name_list"),
    item_atlas = load_schema("item_atlas"),
    item_overlays = load_schema("item_overlays"),
    overlay_atlas = load_schema("overlay_atlas"),
    overlay_availability = load_schema("overlay_availability"),
}
