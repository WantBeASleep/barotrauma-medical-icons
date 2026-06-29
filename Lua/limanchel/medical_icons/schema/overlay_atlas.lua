---@class overlay_atlas_item
---@field overlay string
---@field x integer
---@field y integer
---@field width integer
---@field height integer

local _, LUA_PATH = ...

---@type SchemaConsts
local consts = dofile(LUA_PATH .. "/schema/consts.lua")

---@type Utils
local utils = dofile(LUA_PATH .. "/lib/utils/init.lua")

---@type SchemaUtils
local schema_utils = assert(loadfile(LUA_PATH .. "/schema/utils.lua"))(nil, LUA_PATH)

---@class overlay_atlas_schema
---@field validate fun(value: table)
---@field parse fun(content: string|nil): overlay_atlas_item[]

---@type overlay_atlas_schema
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
            if key ~= "overlay" and key ~= "x" and key ~= "y" and key ~= "width" and key ~= "height" then
                error(consts.ERROR_INVALID_SCHEMA, 0)
            end
        end

        if
            not utils.is_non_empty_string(item.overlay)
            or not utils.is_integer(item.x)
            or not utils.is_integer(item.y)
            or not utils.is_integer(item.width)
            or not utils.is_integer(item.height)
            or item.width <= 0
            or item.height <= 0
        then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end
    end
end

---@param content string|nil
---@return overlay_atlas_item[]
---@throws schemas_error
function schema.parse(content)
    local parsed = schema_utils.parse_with(content, schema.validate)
    ---@cast parsed overlay_atlas_item[]
    return parsed
end

return schema
