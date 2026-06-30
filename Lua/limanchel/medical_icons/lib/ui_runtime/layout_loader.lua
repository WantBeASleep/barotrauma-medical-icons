---@class ui_runtime.LayoutLoader
---@field load fun(path: string): table

---@type ui_runtime.LayoutLoader
local loader = {}

---@param path string
---@return string
local function read_all(path)
    local handle, open_err = io.open(path, "r")
    if handle == nil then
        error(string.format("ui layout open failed: %s: %s", path, tostring(open_err)), 0)
    end

    local content = handle:read("*a")
    handle:close()

    if content == nil or content == "" then
        error("ui layout read failed or empty: " .. path, 0)
    end

    return content
end

---@param path string
---@return table
function loader.load(path)
    local content = read_all(path)
    local ok, parsed = pcall(function()
        return json.parse(content)
    end)
    if not ok or type(parsed) ~= "table" then
        error("ui layout json parse failed: " .. path .. ": " .. tostring(parsed), 0)
    end

    return parsed
end

return loader
