---@class Utils
---@field clone fun(value: any): any
---@field is_non_empty_string fun(value: any): boolean
---@field in_values fun(values: any[], value: any): boolean
---@field is_integer fun(value: any): boolean
---@field is_array fun(value: any): boolean

---@type Utils
local utils = {}

---@param value any
---@return table|any
function utils.clone(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for key, child in pairs(value) do
        result[key] = utils.clone(child)
    end

    return result
end

---@param value any
---@return boolean
function utils.is_non_empty_string(value)
    return type(value) == "string" and value ~= ""
end

---@generic T
---@param values T[]
---@param value T
---@return boolean
function utils.in_values(values, value)
    for _, item in ipairs(values) do
        if item == value then
            return true
        end
    end

    return false
end

---@param value any
---@return boolean
function utils.is_integer(value)
    return type(value) == "number" and math.floor(value) == value
end

---@param value any
---@return boolean
function utils.is_array(value)
    if type(value) ~= "table" then
        return false
    end

    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or not utils.is_integer(key) or key < 1 then
            return false
        end

        count = count + 1
    end

    return count == #value
end

return utils
