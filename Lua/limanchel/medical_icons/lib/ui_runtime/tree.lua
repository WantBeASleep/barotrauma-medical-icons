---@class ui_runtime.Tree
---@field root ui_runtime.Node
---@field templates table<string, table>
---@field diagnostics table
---@field get fun(self: ui_runtime.Tree, path: string): ui_runtime.Node
---@field maybe fun(self: ui_runtime.Tree, path: string): ui_runtime.Node|nil
---@field create fun(self: ui_runtime.Tree, template_name: string, parent: ui_runtime.Node|table): ui_runtime.Node
local Tree = {}
Tree.__index = Tree

---@param root ui_runtime.Node
---@param templates table<string, table>
---@param diagnostics table
---@return ui_runtime.Tree
function Tree.new(root, templates, diagnostics)
    return setmetatable({
        root = root,
        templates = templates or {},
        diagnostics = diagnostics or { warnings = {} },
        instantiate = nil,
    }, Tree)
end

---@param path string
---@return ui_runtime.Node
function Tree:get(path)
    local root_id = self.root.id
    if path == root_id then
        return self.root
    end
    local prefix = root_id .. "."
    if string.sub(path, 1, #prefix) == prefix then
        return self.root:get(string.sub(path, #prefix + 1))
    end
    return self.root:get(path)
end

---@param path string
---@return ui_runtime.Node|nil
function Tree:maybe(path)
    local root_id = self.root.id
    if path == root_id then
        return self.root
    end
    local prefix = root_id .. "."
    if string.sub(path, 1, #prefix) == prefix then
        return self.root:maybe(string.sub(path, #prefix + 1))
    end
    return self.root:maybe(path)
end

---@param template_name string
---@param parent ui_runtime.Node|table
---@return ui_runtime.Node
function Tree:create(template_name, parent)
    if self.instantiate == nil then
        error("ui tree has no template instantiator", 0)
    end

    local parent_node = parent
    if type(parent) == "table" and parent._node ~= nil then
        parent_node = parent._node
    end

    return self.instantiate(template_name, parent_node)
end

return Tree
