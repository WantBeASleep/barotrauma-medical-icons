---@class ErrorsLib
---@field with_context fun(context: string, details: string|nil)

---@type ErrorsLib
local errors = {}

---@param context string
---@param err string|nil
---@return nil
function errors.with_context(context, err)
    if err == nil or err == "" then
        error(context)
    end

    error(string.format("%s: %s", context, err))
end

return errors
