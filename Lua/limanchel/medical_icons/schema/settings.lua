local SETTINGS_ACTUAL_VERSION = 3
local ERROR_VERSION_MISMATCH = "version_mismatch"
local _, LUA_PATH = ...

---@type SchemaConsts
local consts = dofile(LUA_PATH .. "/schema/consts.lua")

---@type Utils
local utils = dofile(LUA_PATH .. "/lib/utils/init.lua")

---@type SchemaUtils
local schema_utils = assert(loadfile(LUA_PATH .. "/schema/utils.lua"))(nil, LUA_PATH)

---@type settings
local defaults = {
    version = SETTINGS_ACTUAL_VERSION,
    texturepack = "default",
    overlaypacks = {
        {
            name = "status_icons",
            x = 0,
            y = 0,
            scale = 1,
        },
    },
}

---@class settings
---@field version integer
---@field texturepack string
---@field overlaypacks overlaypack_setting[]

---@class overlaypack_setting
---@field name string
---@field x number
---@field y number
---@field scale number

---@class settings_schema
---@field copy fun(value: settings): settings
---@field get_defaults fun(): settings
---@field serialize fun(value: settings): string
---@field validate fun(value: table)
---@field parse fun(content: string|nil): settings

---@type settings_schema
local schema = {}

---@param value settings
---@return settings
function schema.copy(value)
    local overlaypacks = {}
    for _, overlaypack in ipairs(value.overlaypacks or {}) do
        table.insert(overlaypacks, {
            name = overlaypack.name,
            x = overlaypack.x,
            y = overlaypack.y,
            scale = overlaypack.scale,
        })
    end

    return {
        version = value.version,
        texturepack = value.texturepack,
        overlaypacks = overlaypacks,
    }
end

---@return settings
function schema.get_defaults()
    return utils.clone(defaults)
end

---@param value settings
---@return string
function schema.serialize(value)
    return json.serialize(value)
end

---@param value table
---@throws schemas_error
function schema.validate(value)
    if type(value) ~= "table" then
        error(consts.ERROR_INVALID_SCHEMA, 0)
    end

    for key in pairs(value) do
        if key ~= "version" and key ~= "texturepack" and key ~= "overlaypacks" then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end
    end

    if value.version == nil or value.texturepack == nil or value.overlaypacks == nil then
        error(consts.ERROR_INVALID_SCHEMA, 0)
    end

    if value.version ~= SETTINGS_ACTUAL_VERSION then
        error(ERROR_VERSION_MISMATCH, 0)
    end

    if not utils.is_non_empty_string(value.texturepack) then
        error(consts.ERROR_INVALID_SCHEMA, 0)
    end

    if not utils.is_array(value.overlaypacks) then
        error(consts.ERROR_INVALID_SCHEMA, 0)
    end

    for _, overlaypack in ipairs(value.overlaypacks) do
        if type(overlaypack) ~= "table" then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end

        for key in pairs(overlaypack) do
            if key ~= "name" and key ~= "x" and key ~= "y" and key ~= "scale" then
                error(consts.ERROR_INVALID_SCHEMA, 0)
            end
        end

        if
            not utils.is_non_empty_string(overlaypack.name)
            or type(overlaypack.x) ~= "number"
            or type(overlaypack.y) ~= "number"
            or type(overlaypack.scale) ~= "number"
            or overlaypack.scale < 0
            or overlaypack.scale > 3
        then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end
    end
end

---@param content string|nil
---@return settings
---@throws schemas_error
function schema.parse(content)
    local parsed = schema_utils.parse_with(content, schema.validate)
    ---@cast parsed settings
    return parsed
end

return schema
