---@alias LoggerLevel integer

---@class LoggerLevels
---@field debug LoggerLevel
---@field info LoggerLevel
---@field warning LoggerLevel
---@field error LoggerLevel

---@type LoggerLevels
local level = {
    debug = 0,
    info = 1,
    warning = 2,
    error = 3,
}

---@type table<LoggerLevel, string>
local level_label = {
    [level.debug] = "DEBUG",
    [level.info] = "INFO",
    [level.warning] = "WARN",
    [level.error] = "ERROR",
}

---@class Logger
---@field private prefix string
---@field private level LoggerLevel
---@field private console Barotrauma.DebugConsole|nil
---@field levels LoggerLevels
local logger = {
    prefix = "Logger",
    level = level.info,
    console = nil,
    levels = level,
}

---Initializes the logger prefix, minimum visible level, and DebugConsole handle.
---@param prefix string
---@param min_level LoggerLevel
---@return nil
function logger.init(prefix, min_level)
    logger.prefix = prefix
    logger.level = min_level

    local ok, console = pcall(function()
        return LuaUserData.CreateStatic("Barotrauma.DebugConsole")
    end)

    if ok and console ~= nil then
        ---@diagnostic disable-next-line: assign-type-mismatch
        logger.console = console
    else
        logger.console = nil
        logger.warn("DebugConsole initialization failed: " .. tostring(console))
    end
end

---@param message string
---@param message_level LoggerLevel
---@param color Microsoft.Xna.Framework.Color
---@private
---@return nil
function logger.log(message, message_level, color)
    local text = string.format("[%s][%s] %s", logger.prefix, level_label[message_level], message)

    if logger.console ~= nil then
        local ok, err = pcall(function()
            ---@diagnostic disable-next-line: invisible
            logger.console.NewMessage(text, color, false)
        end)

        if ok then return end

        print(
            string.format(
                "[%s][%s] DebugConsole.NewMessage failed: %s; using print fallback",
                logger.prefix,
                level_label[level.error],
                tostring(err)
            )
        )
    end

    print(text)
end

---Writes a debug message when the logger level allows it.
---@param message string
---@return nil
function logger.debug(message)
    if logger.level > level.debug then return end

    logger.log(message, level.debug, Color.Green)
end

---Writes an informational message when the logger level allows it.
---@param message string
---@return nil
function logger.info(message)
    if logger.level > level.info then return end

    logger.log(message, level.info, Color.Cyan)
end

---Writes a warning message when the logger level allows it.
---@param message string
---@return nil
function logger.warn(message)
    if logger.level > level.warning then return end

    logger.log(message, level.warning, Color.Yellow)
end

---Writes an error message when the logger level allows it.
---@param message string
---@return nil
function logger.error(message)
    if logger.level > level.error then return end

    logger.log(message, level.error, Color.Red)
end

---@return Logger logger
return logger
