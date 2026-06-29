local SETTINGS_ACTUAL_VERSION = 2
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
    overlays = {},
}

---@class settings
---@field version integer
---@field texturepack string
---@field overlays overlay_setting[]

---@class overlay_setting
---@field overlaypack string
---@field slot overlay_slot

---@class settings_schema
---@field get_defaults fun(): settings
---@field serialize fun(value: settings): string
---@field validate fun(value: table)
---@field parse fun(content: string|nil): settings

---@type settings_schema
local schema = {}

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
        if key ~= "version" and key ~= "texturepack" and key ~= "overlays" then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end
    end

    if value.version == nil or value.texturepack == nil or value.overlays == nil then
        error(consts.ERROR_INVALID_SCHEMA, 0)
    end

    if value.version ~= SETTINGS_ACTUAL_VERSION then
        error(ERROR_VERSION_MISMATCH, 0)
    end

    if not utils.is_non_empty_string(value.texturepack) then
        error(consts.ERROR_INVALID_SCHEMA, 0)
    end

    if not utils.is_array(value.overlays) then
        error(consts.ERROR_INVALID_SCHEMA, 0)
    end

    for _, overlay in ipairs(value.overlays) do
        if type(overlay) ~= "table" then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end

        for key in pairs(overlay) do
            if key ~= "overlaypack" and key ~= "slot" then
                error(consts.ERROR_INVALID_SCHEMA, 0)
            end
        end

        if
            not utils.is_non_empty_string(overlay.overlaypack)
            or (
                overlay.slot ~= "top-left"
                and overlay.slot ~= "top-right"
                and overlay.slot ~= "bottom-left"
                and overlay.slot ~= "bottom-right"
            )
        then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end
    end

    local occupied_slots = {}
    for _, overlay in ipairs(value.overlays) do
        if occupied_slots[overlay.slot] == true then
            error(consts.ERROR_INVALID_SCHEMA, 0)
        end

        occupied_slots[overlay.slot] = true
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
