local SETTINGS_ACTUAL_VERSION = 1

local ERROR_INVALID_JSON = "invalid_json"
local ERROR_INVALID_SHEMA = "invalid_shema"
local ERROR_VERSION_MISMATCH = "version_mismatch"

local SLOT_TOP_LEFT = "top-left"
local SLOT_TOP_RIGHT = "top-right"
local SLOT_BOTTOM_LEFT = "bottom-left"
local SLOT_BOTTOM_RIGHT = "bottom-right"

local overlay_rule_slots = {
    SLOT_TOP_LEFT,
    SLOT_TOP_RIGHT,
    SLOT_BOTTOM_LEFT,
    SLOT_BOTTOM_RIGHT,
}

---@class settings
---@field version integer
---@field texturepack string

---@class texturepack_mapping_item
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

---@class overlay_mapping_item
---@field overlay string
---@field item string

---@class overlay_rule_target
---@field slots string[]

---@alias overlay_rules table<string, table<string, overlay_rule_target>>

---@alias shemas_error
---| '"invalid_json"'
---| '"invalid_shema"'
---| '"version_mismatch"'

---@class settings_shema
---@field private fields string[]
---@field get_defaults fun(): settings
---@field serialize fun(value: settings): string
---@field validate fun(value: table)
---@field parse fun(content: string|nil): settings

---@class name_list_shema
---@field validate fun(value: table)
---@field parse fun(content: string|nil): string[]

---@class texturepack_mapping_shema
---@field private fields string[]
---@field private integer_fields string[]
---@field validate fun(value: table)
---@field parse fun(content: string|nil): texturepack_mapping_item[]

---@class overlay_mapping_shema
---@field private fields string[]
---@field validate fun(value: table)
---@field parse fun(content: string|nil): overlay_mapping_item[]

---@class overlay_rules_shema
---@field private rule_fields string[]
---@field private validate_slots fun(slots: any)
---@field validate fun(value: table)
---@field parse fun(content: string|nil): overlay_rules

---@class shemas
---@field settings settings_shema
---@field texturepacks_list name_list_shema
---@field overlaypacks_list name_list_shema
---@field texturepack_mapping texturepack_mapping_shema
---@field overlay_mapping overlay_mapping_shema
---@field overlay_rules overlay_rules_shema

---@type shemas
local shemas = {
    settings = {
        fields = {
            "version",
            "texturepack",
        },
    },
    texturepacks_list = {},
    overlaypacks_list = {},
    texturepack_mapping = {
        fields = {
            "item",
            "texture",
            "icon_x",
            "icon_y",
            "icon_width",
            "icon_height",
            "sprite_x",
            "sprite_y",
            "sprite_width",
            "sprite_height",
        },
        integer_fields = {
            "icon_x",
            "icon_y",
            "icon_width",
            "icon_height",
            "sprite_x",
            "sprite_y",
            "sprite_width",
            "sprite_height",
        },
    },
    overlay_mapping = {
        fields = {
            "overlay",
            "item",
        },
    },
    overlay_rules = {
        rule_fields = {
            "slots",
        },
    },
}

---@type settings
local settings_defaults = {
    version = SETTINGS_ACTUAL_VERSION,
    texturepack = "default",
}

---@param value any
---@return table|any
local function clone(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for key, child in pairs(value) do
        result[key] = clone(child)
    end

    return result
end

---@param content string|nil
---@return table
---@throws shemas_error
local function parse_json_table(content)
    if type(content) ~= "string" or content == "" then
        error(ERROR_INVALID_JSON, 0)
    end

    local parse_ok, parsed = pcall(function()
        return json.parse(content)
    end)
    if not parse_ok or type(parsed) ~= "table" then
        error(ERROR_INVALID_JSON, 0)
    end

    return parsed
end

---@param value any
---@return boolean
local function is_non_empty_string(value)
    return type(value) == "string" and value ~= ""
end

---@generic T
---@param values T[]
---@param value T
---@return boolean
local function in_values(values, value)
    for _, item in ipairs(values) do
        if item == value then
            return true
        end
    end

    return false
end

---@param value any
---@return boolean
local function is_integer(value)
    return type(value) == "number" and math.floor(value) == value
end

---@param value any
---@return boolean
local function is_array(value)
    if type(value) ~= "table" then
        return false
    end

    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or not is_integer(key) or key < 1 then
            return false
        end

        count = count + 1
    end

    return count == #value
end

---@param value any
---@param keys string[]
---@return boolean
local function has_exact_fields(value, keys)
    if type(value) ~= "table" then
        return false
    end

    local expected = {}
    for _, key in ipairs(keys) do
        expected[key] = true
        if value[key] == nil then
            return false
        end
    end

    local count = 0
    for key in pairs(value) do
        if expected[key] ~= true then
            return false
        end

        count = count + 1
    end

    return count == #keys
end

---@param value table
---@param keys string[]
---@return boolean
local function is_all_fields_integer(value, keys)
    for _, key in ipairs(keys) do
        if not is_integer(value[key]) then
            return false
        end
    end

    return true
end

---@return settings
function shemas.settings.get_defaults()
    return clone(settings_defaults)
end

---@param value settings
---@return string
function shemas.settings.serialize(value)
    return json.serialize(value)
end

---@param value table
---@throws shemas_error
function shemas.settings.validate(value)
    ---@diagnostic disable-next-line: invisible
    if not has_exact_fields(value, shemas.settings.fields) then
        error(ERROR_INVALID_SHEMA, 0)
    end

    if value.version ~= SETTINGS_ACTUAL_VERSION then
        error(ERROR_VERSION_MISMATCH, 0)
    end

    if not is_non_empty_string(value.texturepack) then
        error(ERROR_INVALID_SHEMA, 0)
    end
end

---@param content string|nil
---@return settings
---@throws shemas_error
function shemas.settings.parse(content)
    local parsed = parse_json_table(content)
    shemas.settings.validate(parsed)
    ---@cast parsed settings
    return parsed
end

---@param value table
---@throws shemas_error
function shemas.texturepacks_list.validate(value)
    if not is_array(value) then
        error(ERROR_INVALID_SHEMA, 0)
    end

    for _, name in ipairs(value) do
        if not is_non_empty_string(name) then
            error(ERROR_INVALID_SHEMA, 0)
        end
    end
end

---@param content string|nil
---@return string[]
---@throws shemas_error
function shemas.texturepacks_list.parse(content)
    local parsed = parse_json_table(content)
    shemas.texturepacks_list.validate(parsed)
    ---@cast parsed string[]
    return parsed
end

---@param value table
---@throws shemas_error
function shemas.overlaypacks_list.validate(value)
    if not is_array(value) then
        error(ERROR_INVALID_SHEMA, 0)
    end

    for _, name in ipairs(value) do
        if not is_non_empty_string(name) then
            error(ERROR_INVALID_SHEMA, 0)
        end
    end
end

---@param content string|nil
---@return string[]
---@throws shemas_error
function shemas.overlaypacks_list.parse(content)
    local parsed = parse_json_table(content)
    shemas.overlaypacks_list.validate(parsed)
    ---@cast parsed string[]
    return parsed
end

---@param value table
---@throws shemas_error
function shemas.texturepack_mapping.validate(value)
    if not is_array(value) then
        error(ERROR_INVALID_SHEMA, 0)
    end

    for _, item in ipairs(value) do
        if
            ---@diagnostic disable-next-line: invisible
            not has_exact_fields(item, shemas.texturepack_mapping.fields)
            or not is_non_empty_string(item.item)
            or not is_non_empty_string(item.texture)
            ---@diagnostic disable-next-line: invisible
            or not is_all_fields_integer(item, shemas.texturepack_mapping.integer_fields)
        then
            error(ERROR_INVALID_SHEMA, 0)
        end
    end
end

---@param content string|nil
---@return texturepack_mapping_item[]
---@throws shemas_error
function shemas.texturepack_mapping.parse(content)
    local parsed = parse_json_table(content)
    shemas.texturepack_mapping.validate(parsed)
    ---@cast parsed texturepack_mapping_item[]
    return parsed
end

---@param value table
---@throws shemas_error
function shemas.overlay_mapping.validate(value)
    if not is_array(value) then
        error(ERROR_INVALID_SHEMA, 0)
    end

    for _, item in ipairs(value) do
        if
            ---@diagnostic disable-next-line: invisible
            not has_exact_fields(item, shemas.overlay_mapping.fields)
            or not is_non_empty_string(item.overlay)
            or not is_non_empty_string(item.item)
        then
            error(ERROR_INVALID_SHEMA, 0)
        end
    end
end

---@param content string|nil
---@return overlay_mapping_item[]
---@throws shemas_error
function shemas.overlay_mapping.parse(content)
    local parsed = parse_json_table(content)
    shemas.overlay_mapping.validate(parsed)
    ---@cast parsed overlay_mapping_item[]
    return parsed
end

---@param slots any
---@throws shemas_error
---@diagnostic disable-next-line: invisible
function shemas.overlay_rules.validate_slots(slots)
    if not is_array(slots) then
        error(ERROR_INVALID_SHEMA, 0)
    end

    for _, slot in ipairs(slots) do
        if not in_values(overlay_rule_slots, slot) then
            error(ERROR_INVALID_SHEMA, 0)
        end
    end
end

---@param value table
---@throws shemas_error
function shemas.overlay_rules.validate(value)
    for overlaypack_name, texturepack_rules in pairs(value) do
        if not is_non_empty_string(overlaypack_name) then
            error(ERROR_INVALID_SHEMA, 0)
        end

        if type(texturepack_rules) ~= "table" then
            error(ERROR_INVALID_SHEMA, 0)
        end

        for texturepack_name, rule in pairs(texturepack_rules) do
            if not is_non_empty_string(texturepack_name) then
                error(ERROR_INVALID_SHEMA, 0)
            end

            ---@diagnostic disable-next-line: invisible
            if not has_exact_fields(rule, shemas.overlay_rules.rule_fields) then
                error(ERROR_INVALID_SHEMA, 0)
            end

            ---@diagnostic disable-next-line: invisible
            shemas.overlay_rules.validate_slots(rule.slots)
        end
    end
end

---@param content string|nil
---@return overlay_rules
---@throws shemas_error
function shemas.overlay_rules.parse(content)
    local parsed = parse_json_table(content)
    shemas.overlay_rules.validate(parsed)
    ---@cast parsed overlay_rules
    return parsed
end

return shemas
