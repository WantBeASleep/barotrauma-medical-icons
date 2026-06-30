---@alias StorageOperation
---| '"init"'
---| '"exists"'
---| '"load_string"'
---| '"save_string"'
---| '"delete"'
---| '"delete_recursive_extension"'
---| '"get_full_path"'

---@class StorageError
---@field operation StorageOperation
---@field path string
---@field code MedicalIcons.StorageErrorCode|string
---@field message string|nil
---@field cause any

---@class StorageOptions
---@field type_name string|nil
---@field csharp_storage MedicalIcons.Storage|nil

---@class Storage
---@field exists fun(path: string): boolean|nil, StorageError|nil
---Returns nil without a StorageError when the file does not exist.
---@field load_string fun(path: string): string|nil, StorageError|nil
---@field save_string fun(path: string, content: string): boolean, StorageError|nil
---@field delete fun(path: string): boolean|nil, StorageError|nil
---@field delete_recursive_extension fun(path: string, extension: string): integer|nil, StorageError|nil
---@field get_full_path fun(path: string): string|nil, StorageError|nil

---@class StorageLib
---@field new fun(options: StorageOptions): Storage

---@type StorageLib
local storage_lib = {}

---@type Logger|nil
local _, _, log = ...

local UNKNOWN_ERROR_CODE = "unknown"
local ERROR_CAUSE_CODE_FIELD = "Code"
local ERROR_CAUSE_MESSAGE_FIELD = "Message"

local OPERATION = {
    init = "init",
    exists = "exists",
    load_string = "load_string",
    save_string = "save_string",
    delete = "delete",
    delete_recursive_extension = "delete_recursive_extension",
    get_full_path = "get_full_path",
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
---@return MedicalIcons.StorageErrorCode|string
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

---Normalizes any Lua/LuaCs/C# failure into the storage library error shape.
---@param operation StorageOperation
---@param path string
---@param cause any
---@return StorageError
function error_factory.new(operation, path, cause)
    return {
        operation = operation,
        path = path,
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

---Logs the start of a storage operation before calling into C#.
---@param operation StorageOperation
---@param path string
---@param details string|nil
---@return nil
function tracing.call(operation, path, details)
    if details == nil or details == "" then
        tracing.write(string.format("lua call C# storage.%s -> %s", operation, path))
        return
    end

    tracing.write(string.format("lua call C# storage.%s -> %s; %s", operation, path, details))
end

---Logs the successful completion of a storage operation.
---@param operation StorageOperation
---@param path string
---@param details string|nil
---@return nil
function tracing.success(operation, path, details)
    if details == nil or details == "" then
        tracing.write(string.format("lua call C# storage.%s <- %s", operation, path))
        return
    end

    tracing.write(string.format("lua call C# storage.%s <- %s; %s", operation, path, details))
end

---Logs the failed completion of a storage operation.
---@param operation StorageOperation
---@param path string
---@param err StorageError
---@return nil
function tracing.failure(operation, path, err)
    tracing.write(
        string.format(
            "lua call C# storage.%s !! %s; code=%s; message=%s",
            operation,
            path,
            err.code,
            tostring(err.message)
        )
    )
end

---Creates a Lua wrapper around a LuaCs-visible static C# storage type.
---@param options StorageOptions
---@return Storage
function storage_lib.new(options)
    if options == nil then
        error("storage options are required")
    end

    local type_name = options.type_name
    local csharp_storage = options.csharp_storage
    local csharp_storage_unavailable = false

    if type_name == nil or type_name == "" then
        error("storage type_name is required")
    end

    ---Returns the cached C# storage helper, registering and creating it on first use.
    ---@return MedicalIcons.Storage|nil, StorageError|nil
    local function get_csharp_storage()
        if csharp_storage_unavailable then
            return nil, error_factory.new(OPERATION.init, type_name, "C# storage is unavailable")
        end

        if csharp_storage ~= nil then
            return csharp_storage, nil
        end

        local register_ok, register_result = pcall(function()
            return LuaUserData.RegisterType(type_name)
        end)

        if not register_ok or register_result == nil then
            csharp_storage_unavailable = true
            return nil, error_factory.new(OPERATION.init, type_name, register_result)
        end

        local create_ok, create_result = pcall(function()
            return LuaUserData.CreateStatic(type_name)
        end)

        if not create_ok or create_result == nil then
            csharp_storage_unavailable = true
            return nil, error_factory.new(OPERATION.init, type_name, create_result)
        end

        ---@cast create_result MedicalIcons.Storage
        csharp_storage = create_result
        return csharp_storage, nil
    end

    ---Runs one protected call against the C# storage helper and normalizes failures.
    ---@generic T
    ---@param operation StorageOperation
    ---@param path string
    ---@param call fun(csharp_storage: MedicalIcons.Storage): T
    ---@return T|nil, StorageError|nil
    local function call_storage(operation, path, call)
        local storage, init_err = get_csharp_storage()
        if storage == nil then
            init_err.operation = operation
            init_err.path = path
            ---@diagnostic disable-next-line: param-type-mismatch
            tracing.failure(operation, path, init_err)
            return nil, init_err
        end

        local ok, result = pcall(function()
            return call(storage)
        end)

        if ok then
            return result, nil
        end

        local err = error_factory.new(operation, path, result)
        tracing.failure(operation, path, err)
        return nil, err
    end

    ---@type Storage
    local storage_api = {}

    ---Checks whether a storage-relative file exists.
    ---@param path string
    ---@return boolean|nil, StorageError|nil
    function storage_api.exists(path)
        tracing.call(OPERATION.exists, path, nil)

        local result, err = call_storage(OPERATION.exists, path, function(storage)
            return storage.Exists(path)
        end)

        if err ~= nil then
            return nil, err
        end

        local exists = result == true
        tracing.success(OPERATION.exists, path, string.format("exists=%s", tostring(exists)))
        return exists, nil
    end

    ---Loads a text file from storage. Returns nil without a StorageError when the file does not exist.
    ---@param path string
    ---@return string|nil, StorageError|nil
    function storage_api.load_string(path)
        tracing.call(OPERATION.load_string, path, nil)

        local result, err = call_storage(OPERATION.load_string, path, function(storage)
            return storage.LoadString(path)
        end)

        if err ~= nil then
            return nil, err
        end

        if result == nil then
            tracing.success(OPERATION.load_string, path, "missing=true")
            return nil, nil
        end

        local content = tostring(result)
        tracing.success(OPERATION.load_string, path, string.format("bytes=%d", string.len(content)))
        return content, nil
    end

    ---Saves text content to a storage-relative file path.
    ---@param path string
    ---@param content string
    ---@return boolean, StorageError|nil
    function storage_api.save_string(path, content)
        tracing.call(OPERATION.save_string, path, string.format("bytes=%d", string.len(content or "")))

        local _, err = call_storage(OPERATION.save_string, path, function(storage)
            storage.SaveString(path, content)
            return true
        end)

        if err ~= nil then
            return false, err
        end

        tracing.success(OPERATION.save_string, path, nil)
        return true, nil
    end

    ---Deletes one storage-relative file if it exists.
    ---@param path string
    ---@return boolean|nil, StorageError|nil
    function storage_api.delete(path)
        tracing.call(OPERATION.delete, path, nil)

        local result, err = call_storage(OPERATION.delete, path, function(storage)
            return storage.Delete(path)
        end)

        if err ~= nil then
            return nil, err
        end

        local deleted = result == true
        tracing.success(OPERATION.delete, path, string.format("deleted=%s", tostring(deleted)))
        return deleted, nil
    end

    ---Deletes files with the given extension under a storage-relative directory tree.
    ---@param path string
    ---@param extension string
    ---@return integer|nil, StorageError|nil
    function storage_api.delete_recursive_extension(path, extension)
        tracing.call(OPERATION.delete_recursive_extension, path, string.format("extension=%s", extension))

        local result, err = call_storage(OPERATION.delete_recursive_extension, path, function(storage)
            return storage.DeleteRecursiveExtension(path, extension)
        end)

        if err ~= nil then
            return nil, err
        end

        local deleted_count = tonumber(result) or 0
        tracing.success(OPERATION.delete_recursive_extension, path, string.format("deleted_count=%d", deleted_count))
        return deleted_count, nil
    end

    ---Resolves a storage-relative path to the full path reported by the C# helper.
    ---@param path string
    ---@return string|nil, StorageError|nil
    function storage_api.get_full_path(path)
        tracing.call(OPERATION.get_full_path, path, nil)

        local result, err = call_storage(OPERATION.get_full_path, path, function(storage)
            return storage.GetFullPath(path)
        end)

        if err ~= nil then
            return nil, err
        end

        local full_path = tostring(result or "")
        tracing.success(OPERATION.get_full_path, path, string.format("full_path=%s", full_path))
        return full_path, nil
    end

    return storage_api
end

return storage_lib
