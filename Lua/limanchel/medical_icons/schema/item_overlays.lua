---@class item_overlay
---@field overlay string
---@field item string

local _, LUA_PATH = ...

---@type SchemaConsts
local consts = dofile(LUA_PATH .. "/schema/consts.lua")

---@type Utils
local utils = dofile(LUA_PATH .. "/lib/utils/init.lua")

---@type SchemaUtils
local schema_utils = assert(loadfile(LUA_PATH .. "/schema/utils.lua"))(nil, LUA_PATH)

---@class item_overlays_schema
---@field validate fun(value: table)
---@field parse fun(content: string|nil): item_overlay[]

---@type item_overlays_schema
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
            if key ~= "overlay" and key ~= "item" then
                error(consts.ERROR_INVALID_SCHEMA, 0)
            end
        end

        if not utils.is_non_empty_string(item.overlay) or not utils.is_non_empty_string(item.item) then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end
    end
end

---@param content string|nil
---@return item_overlay[]
---@throws schemas_error
function schema.parse(content)
    local parsed = schema_utils.parse_with(content, schema.validate)
    ---@cast parsed item_overlay[]
    return parsed
end

return schema
