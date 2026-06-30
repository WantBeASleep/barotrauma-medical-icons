---@class ui_runtime.Context
---@field mod_path string|nil
---@field lua_path string|nil
---@field runtime_path string|nil
---@field load fun(relative_path: string): any

---@class ui_runtime.Runtime
---@field load_layout fun(path: string): table
---@field validate fun(layout: table)
---@field render fun(layout: table, parent: Barotrauma.RectTransform, options: table|nil): ui_runtime.Tree

local args = ...
if type(args) ~= "table" then
    args = {}
end

local runtime_path = args.runtime_path
if runtime_path == nil then
    if args.lua_path == nil then
        error("ui_runtime requires runtime_path or lua_path", 0)
    end
    runtime_path = args.lua_path .. "/lib/ui_runtime"
end

---@type ui_runtime.Context
local context = {
    mod_path = args.mod_path,
    lua_path = args.lua_path,
    runtime_path = runtime_path,
}

---@param relative_path string
---@return any
function context.load(relative_path)
    return assert(loadfile(runtime_path .. "/" .. relative_path))(context)
end

local layout_loader = context.load("layout_loader.lua")
local validator = context.load("validator.lua")
local renderer = context.load("renderer.lua")

---@type ui_runtime.Runtime
local runtime = {}

function runtime.load_layout(path)
    return layout_loader.load(path)
end

function runtime.validate(layout)
    validator.validate(layout)
end

function runtime.render(layout, parent, options)
    validator.validate(layout)
    return renderer.render(layout, parent, options or {})
end

return runtime
