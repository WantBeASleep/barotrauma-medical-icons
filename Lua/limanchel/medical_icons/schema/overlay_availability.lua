---@class overlay_availability_target
---@field slots string[]

---@alias overlay_availability table<string, table<string, overlay_availability_target>>

local _, LUA_PATH = ...

---@type SchemaConsts
local consts = dofile(LUA_PATH .. "/schema/consts.lua")

---@type Utils
local utils = dofile(LUA_PATH .. "/lib/utils/init.lua")

---@type SchemaUtils
local schema_utils = assert(loadfile(LUA_PATH .. "/schema/utils.lua"))(nil, LUA_PATH)

---@class overlay_availability_schema
---@field validate_slots fun(slots: any)
---@field validate fun(value: table)
---@field parse fun(content: string|nil): overlay_availability

---@type overlay_availability_schema
local schema = {}

---@param slots any
---@throws schemas_error
function schema.validate_slots(slots)
    if not utils.is_array(slots) then
        error(consts.ERROR_INVALID_SCHEMA, 0)
    end

    for _, slot in ipairs(slots) do
        if slot ~= "top-left" and slot ~= "top-right" and slot ~= "bottom-left" and slot ~= "bottom-right" then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end
    end
end

---@param value table
---@throws schemas_error
function schema.validate(value)
    for overlaypack_name, texturepack_rules in pairs(value) do
        if not utils.is_non_empty_string(overlaypack_name) then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end

        if type(texturepack_rules) ~= "table" then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end

        for texturepack_name, rule in pairs(texturepack_rules) do
            if not utils.is_non_empty_string(texturepack_name) then
                error(consts.ERROR_INVALID_SCHEMA, 0)
            end

            if type(rule) ~= "table" then
                error(consts.ERROR_INVALID_SCHEMA, 0)
            end

            for key in pairs(rule) do
                if key ~= "slots" then
                    error(consts.ERROR_INVALID_SCHEMA, 0)
                end
            end

            if rule.slots == nil then
                error(consts.ERROR_INVALID_SCHEMA, 0)
            end

            schema.validate_slots(rule.slots)
        end
    end
end

---@param content string|nil
---@return overlay_availability
---@throws schemas_error
function schema.parse(content)
    local parsed = schema_utils.parse_with(content, schema.validate)
    ---@cast parsed overlay_availability
    return parsed
end

return schema
