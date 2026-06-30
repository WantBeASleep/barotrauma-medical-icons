local _, LUA_PATH = ...

---@class SchemaUtils
---@field parse_json_table fun(content: string|nil): table
---@field parse_with fun(content: string|nil, validate: fun(value: table)): table

---@type SchemaConsts
local consts = dofile(LUA_PATH .. "/schema/consts.lua")

---@type SchemaUtils
local schema_utils = {}

---@param content string|nil
---@return table
function schema_utils.parse_json_table(content)
    if type(content) ~= "string" or content == "" then
        error(consts.ERROR_INVALID_JSON, 0)
    end

    local parse_ok, parsed = pcall(function()
        return json.parse(content)
    end)
    if not parse_ok or type(parsed) ~= "table" then
        error(consts.ERROR_INVALID_JSON, 0)
    end

    return parsed
end

---@param content string|nil
---@param validate fun(value: table)
---@return table
function schema_utils.parse_with(content, validate)
    local parsed = schema_utils.parse_json_table(content)
    validate(parsed)
    return parsed
end

return schema_utils
