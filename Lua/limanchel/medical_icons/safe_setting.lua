---@type string
local MOD_PATH

---@type string
local LUA_PATH

MOD_PATH, LUA_PATH = ...

---@type schemas
local schema = assert(loadfile(LUA_PATH .. "/schema/init.lua"))(MOD_PATH, LUA_PATH)

---@type Logger
local log

---@type Storage|nil
local storage

-- The module always keeps the active settings in memory. Storage is only a
-- persistence layer and can disappear without breaking the menu.
---@type settings
local settings = {}

-- Storage paths are relative to the C# MedicalIcons.Storage root.
local STORAGE_TYPE_NAME = "MedicalIcons.Storage"
local SETTINGS_PATH = "medical-icons/settings.json"

---@class MenuSettings
---@field init fun(logger: Logger)
---@field safe_get_settings fun(): settings
---@field safe_save fun(new_settings: settings): boolean

---@type MenuSettings
local safe_setting = {}

---@param err StorageError|any
---@return string
local function get_storage_error(err)
    if err == nil then
        return "unknown"
    end

    local ok, message = pcall(function()
        return err.message or err.code
    end)
    if ok and message ~= nil then
        return tostring(message)
    end

    return tostring(err)
end

---@param err StorageError|any
---@return nil
local function disable_storage(err)
    storage = nil

    if log ~= nil and log.debug ~= nil then
        log.debug(string.format("settings storage disabled: %s", get_storage_error(err)))
    end
end

---@return nil
local function save_to_storage()
    if storage == nil then
        return
    end

    local ok, err = storage.save_string(SETTINGS_PATH, schema.settings.serialize(settings))
    if not ok then
        disable_storage(err)
    end
end

-- Loads settings from storage once during init. Runtime reads use memory only.
---@return nil
local function load_from_storage()
    if storage == nil then
        return
    end

    local content, err = storage.load_string(SETTINGS_PATH)
    if err ~= nil then
        disable_storage(err)
        return
    end

    if content == nil then
        save_to_storage()
        return
    end

    local ok, loaded_settings = pcall(schema.settings.parse, content)
    if ok then
        settings = schema.settings.copy(loaded_settings)
        return
    end

    -- Bad stored data is the only case where we intentionally reset to defaults.
    settings = schema.settings.get_defaults()
    if log ~= nil and log.warn ~= nil then
        log.warn(string.format("invalid settings in storage; using defaults: %s", tostring(loaded_settings)))
    end
    save_to_storage()
end

---@param logger Logger
---@return nil
function safe_setting.init(logger)
    log = logger
    settings = schema.settings.get_defaults()
    storage = nil

    local ok, result = pcall(function()
        return dofile(LUA_PATH .. "/lib/storage/init.lua").new({
            log = log,
            type_name = STORAGE_TYPE_NAME,
        })
    end)

    if ok then
        ---@cast result Storage
        storage = result
        load_from_storage()
    elseif log ~= nil and log.debug ~= nil then
        log.debug(string.format("settings storage unavailable: %s", tostring(result)))
    end
end

---@return settings
function safe_setting.safe_get_settings()
    return schema.settings.copy(settings)
end

---@param new_settings settings
---@throws schemas_error
---@return boolean
function safe_setting.safe_save(new_settings)
    schema.settings.validate(new_settings)
    settings = schema.settings.copy(new_settings)
    save_to_storage()
    return true
end

return safe_setting
