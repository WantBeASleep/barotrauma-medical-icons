---@class FileLib
---@field read_all fun(path: string): string

---@type FileLib
local file = {}

---@param path string
---@return string
function file.read_all(path)
    local handle, open_err = io.open(path, "r")
    if handle == nil then
        error(string.format("file open failed: %s: %s", path, tostring(open_err)))
    end

    local content = handle:read("*a")
    handle:close()

    if content == nil then
        error(string.format("file read failed: %s", path))
    end

    return content
end

return file
