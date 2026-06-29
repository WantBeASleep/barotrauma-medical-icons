---@class item_atlas_item
---@field item string
---@field texture string
---@field icon_x integer
---@field icon_y integer
---@field icon_width integer
---@field icon_height integer
---@field sprite_x integer
---@field sprite_y integer
---@field sprite_width integer
---@field sprite_height integer

local _, LUA_PATH = ...

---@type SchemaConsts
local consts = dofile(LUA_PATH .. "/schema/consts.lua")

---@type Utils
local utils = dofile(LUA_PATH .. "/lib/utils/init.lua")

---@type SchemaUtils
local schema_utils = assert(loadfile(LUA_PATH .. "/schema/utils.lua"))(nil, LUA_PATH)

---@class item_atlas_schema
---@field validate fun(value: table)
---@field parse fun(content: string|nil): item_atlas_item[]

---@type item_atlas_schema
local schema = {}

---@param value table
---@throws schemas_error
function schema.validate(value)
    if not utils.is_array(value) then
        error(consts.ERROR_INVALID_SCHEMA, 0)
    end

    for _, item in ipairs(value) do
        if type(item) ~= "table" then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end

        for key in pairs(item) do
            if
                key ~= "item"
                and key ~= "texture"
                and key ~= "icon_x"
                and key ~= "icon_y"
                and key ~= "icon_width"
                and key ~= "icon_height"
                and key ~= "sprite_x"
                and key ~= "sprite_y"
                and key ~= "sprite_width"
                and key ~= "sprite_height"
            then
                error(consts.ERROR_INVALID_SCHEMA, 0)
            end
        end

        if
            not utils.is_non_empty_string(item.item)
            or not utils.is_non_empty_string(item.texture)
            or not utils.is_integer(item.icon_x)
            or not utils.is_integer(item.icon_y)
            or not utils.is_integer(item.icon_width)
            or not utils.is_integer(item.icon_height)
            or not utils.is_integer(item.sprite_x)
            or not utils.is_integer(item.sprite_y)
            or not utils.is_integer(item.sprite_width)
            or not utils.is_integer(item.sprite_height)
        then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end
    end
end

---@param content string|nil
---@return item_atlas_item[]
---@throws schemas_error
function schema.parse(content)
    local parsed = schema_utils.parse_with(content, schema.validate)
    ---@cast parsed item_atlas_item[]
    return parsed
end

return schema
