local _, LUA_PATH = ...

---@type SchemaConsts
local consts = dofile(LUA_PATH .. "/schema/consts.lua")

---@type Utils
local utils = dofile(LUA_PATH .. "/lib/utils/init.lua")

---@type SchemaUtils
local schema_utils = assert(loadfile(LUA_PATH .. "/schema/utils.lua"))(nil, LUA_PATH)

---@class name_list_schema
---@field validate fun(value: table)
---@field parse fun(content: string|nil): string[]

---@type name_list_schema
local schema = {}

---@param value table
---@throws schemas_error
function schema.validate(value)
    if not utils.is_array(value) then
        error(consts.ERROR_INVALID_SCHEMA, 0)
    end

    for _, name in ipairs(value) do
        if not utils.is_non_empty_string(name) then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end
    end
end

---@param content string|nil
---@return string[]
---@throws schemas_error
function schema.parse(content)
    local parsed = schema_utils.parse_with(content, schema.validate)
    ---@cast parsed string[]
    return parsed
end

return schema
