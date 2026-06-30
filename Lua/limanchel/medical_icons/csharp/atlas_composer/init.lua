---@alias AtlasComposerWrapperErrorCode
---| '"unknown"'

---@alias AtlasComposerOperation
---| '"init"'
---| '"compose"'

---@class AtlasComposerError
---@field operation AtlasComposerOperation
---@field input_atlas_path string
---@field output_storage_path string
---@field code AtlasComposerErrorCode|AtlasComposerWrapperErrorCode|string
---@field message string|nil
---@field cause any

---@class AtlasComposerOptions
---@field type_name string|nil
---@field csharp_composer AtlasComposerUserData|nil

---@class AtlasComposer
---@field compose fun(input_atlas_path: string, output_storage_path: string, operations: AtlasOverlayPackOperation[]): integer|nil, AtlasComposerError|nil

---@class AtlasComposerLib
---@field new fun(options: AtlasComposerOptions|nil): AtlasComposer

---@type AtlasComposerLib
local atlas_composer_lib = {}

---@type Logger|nil
local _, _, log = ...

local DEFAULT_TYPE_NAME = "MedicalIcons.AtlasComposer"
local UNKNOWN_ERROR_CODE = "unknown"
local ERROR_CAUSE_CODE_FIELD = "Code"
local ERROR_CAUSE_MESSAGE_FIELD = "Message"

local OPERATION = {
    init = "init",
    compose = "compose",
}

local error_factory = {}

---Reads a field from a LuaCs/C# error object without letting field access throw.
---@param cause any
---@param field_name string
---@return string|nil
function error_factory.read_cause_field(cause, field_name)
    if cause == nil then
        return nil
    end

    local ok, result = pcall(function()
        return cause[field_name]
    end)

    if not ok or result == nil then
        return nil
    end

    return tostring(result)
end

---Returns a stable error code, preferring the C# exception Code field when present.
---@param cause any
---@return AtlasComposerErrorCode|AtlasComposerWrapperErrorCode|string
function error_factory.get_code(cause)
    local code = error_factory.read_cause_field(cause, ERROR_CAUSE_CODE_FIELD)
    if code ~= nil and code ~= "" then
        return code
    end

    return UNKNOWN_ERROR_CODE
end

---Returns a human-readable error message, preferring the C# exception Message field when present.
---@param cause any
---@return string|nil
function error_factory.get_message(cause)
    local message = error_factory.read_cause_field(cause, ERROR_CAUSE_MESSAGE_FIELD)
    if message ~= nil and message ~= "" then
        return message
    end
end

---Normalizes any Lua/LuaCs/C# failure into the atlas composer error shape.
---@param operation AtlasComposerOperation
---@param input_atlas_path string
---@param output_storage_path string
---@param cause any
---@return AtlasComposerError
function error_factory.new(operation, input_atlas_path, output_storage_path, cause)
    return {
        operation = operation,
        input_atlas_path = input_atlas_path,
        output_storage_path = output_storage_path,
        code = error_factory.get_code(cause),
        message = error_factory.get_message(cause),
        cause = cause,
    }
end

local tracing = {}

---Writes one TRACE line when a compatible logger was provided.
---@param message string
---@private
---@return nil
function tracing.write(message)
    if log ~= nil and log.trace ~= nil then
        log.trace(message)
    end
end

---Logs the start of a composer operation before calling into C#.
---@param operation AtlasComposerOperation
---@param input_atlas_path string
---@param output_storage_path string
---@param details string|nil
---@return nil
function tracing.call(operation, input_atlas_path, output_storage_path, details)
    local message = string.format(
        "lua call C# atlas_composer.%s -> input=%s; output=%s",
        operation,
        input_atlas_path,
        output_storage_path
    )

    if details ~= nil and details ~= "" then
        message = string.format("%s; %s", message, details)
    end

    tracing.write(message)
end

---Logs the successful completion of a composer operation.
---@param operation AtlasComposerOperation
---@param input_atlas_path string
---@param output_storage_path string
---@param details string|nil
---@return nil
function tracing.success(operation, input_atlas_path, output_storage_path, details)
    local message = string.format(
        "lua call C# atlas_composer.%s <- input=%s; output=%s",
        operation,
        input_atlas_path,
        output_storage_path
    )

    if details ~= nil and details ~= "" then
        message = string.format("%s; %s", message, details)
    end

    tracing.write(message)
end

---Logs the failed completion of a composer operation.
---@param err AtlasComposerError
---@return nil
function tracing.failure(err)
    tracing.write(
        string.format(
            "lua call C# atlas_composer.%s !! input=%s; output=%s; code=%s; message=%s",
            err.operation,
            err.input_atlas_path,
            err.output_storage_path,
            err.code,
            tostring(err.message)
        )
    )
end

---Creates a Lua wrapper around the LuaCs-visible static C# atlas composer.
---@param options AtlasComposerOptions|nil
---@return AtlasComposer
function atlas_composer_lib.new(options)
    options = options or {}

    local type_name = options.type_name or DEFAULT_TYPE_NAME
    local csharp_composer = options.csharp_composer
    local csharp_composer_unavailable = false

    ---Returns the cached C# atlas composer helper, registering and creating it on first use.
    ---@return AtlasComposerUserData|nil, AtlasComposerError|nil
    local function get_csharp_composer()
        if csharp_composer_unavailable then
            return nil, error_factory.new(OPERATION.init, type_name, "", "C# atlas composer is unavailable")
        end

        if csharp_composer ~= nil then
            return csharp_composer, nil
        end

        local register_ok, register_result = pcall(function()
            return LuaUserData.RegisterType(type_name)
        end)

        if not register_ok or register_result == nil then
            csharp_composer_unavailable = true
            return nil, error_factory.new(OPERATION.init, type_name, "", register_result)
        end

        local create_ok, create_result = pcall(function()
            return LuaUserData.CreateStatic(type_name)
        end)

        if not create_ok or create_result == nil then
            csharp_composer_unavailable = true
            return nil, error_factory.new(OPERATION.init, type_name, "", create_result)
        end

        ---@cast create_result AtlasComposerUserData
        csharp_composer = create_result
        return csharp_composer, nil
    end

    ---@type AtlasComposer
    local atlas_composer = {}

    ---Loads one atlas PNG, applies overlaypack rectangles, and writes a Storage PNG.
    ---
    ---`input_atlas_path` and every `overlay_pack_atlas_path` must be absolute filesystem paths.
    ---Each operation carries one overlaypack-wide offset/scale setting; each overlay carries its overlay atlas source rect and output atlas icon position.
    ---`output_storage_path` must be relative to Barotrauma storage, matching the C# Storage contract.
    ---@param input_atlas_path string
    ---@param output_storage_path string
    ---@param operations AtlasOverlayPackOperation[]
    ---@return integer|nil applied_count
    ---@return AtlasComposerError|nil err
    function atlas_composer.compose(input_atlas_path, output_storage_path, operations)
        local operation_count = 0
        if operations ~= nil then
            operation_count = #operations
        end

        tracing.call(
            OPERATION.compose,
            input_atlas_path,
            output_storage_path,
            string.format("operations=%d", operation_count)
        )

        local composer, init_err = get_csharp_composer()
        if composer == nil then
            init_err.operation = OPERATION.compose
            init_err.input_atlas_path = input_atlas_path
            init_err.output_storage_path = output_storage_path
            ---@diagnostic disable-next-line: param-type-mismatch
            tracing.failure(init_err)
            return nil, init_err
        end

        local ok, result = pcall(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            return composer.Compose(input_atlas_path, output_storage_path, operations)
        end)

        if not ok then
            local err = error_factory.new(OPERATION.compose, input_atlas_path, output_storage_path, result)
            tracing.failure(err)
            return nil, err
        end

        local applied_count = tonumber(result) or 0
        tracing.success(
            OPERATION.compose,
            input_atlas_path,
            output_storage_path,
            string.format("applied_count=%d", applied_count)
        )
        return applied_count, nil
    end

    return atlas_composer
end

return atlas_composer_lib
