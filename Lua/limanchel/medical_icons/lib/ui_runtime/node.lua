---@class ui_runtime.Node
---@field id string
---@field type string
---@field path string
---@field component Barotrauma.GUIComponent
---@field children ui_runtime.Node[]
---@field index table<string, ui_runtime.Node>
---@field parent ui_runtime.Node|nil
local Node = {}
Node.__index = Node

---@param component Barotrauma.GUIComponent
---@param node_type string
---@param id string
---@param path string
---@param parent ui_runtime.Node|nil
---@return ui_runtime.Node
function Node.new(component, node_type, id, path, parent)
    local node = {
        id = id,
        type = node_type,
        path = path,
        component = component,
        children = {},
        index = {},
        parent = parent,
    }
    return setmetatable(node, Node)
end

---@param child ui_runtime.Node
---@param indexable boolean|nil
function Node:add_child(child, indexable)
    table.insert(self.children, child)
    if indexable ~= false then
        self.index[child.id] = child
    end
end

---@param path string
---@return ui_runtime.Node
function Node:get(path)
    local current = self
    for segment in string.gmatch(path, "[^%.]+") do
        current = current.index[segment]
        if current == nil then
            error(string.format("ui node not found: %s under %s", path, self.path), 0)
        end
    end
    return current
end

---@param path string
---@return ui_runtime.Node|nil
function Node:maybe(path)
    local current = self
    for segment in string.gmatch(path, "[^%.]+") do
        current = current.index[segment]
        if current == nil then
            return nil
        end
    end
    return current
end

---@return Barotrauma.GUIComponent
function Node:component()
    return self.component
end

function Node:remove()
    pcall(function()
        self.component.Remove()
    end)
end

function Node:clear()
    local target = self.component
    if self.type == "ListBox" or self.type == "ScissorComponent" then
        local ok, content = pcall(function()
            return self.component.Content
        end)
        if ok and content ~= nil then
            target = content
        end
    end

    pcall(function()
        target.ClearChildren()
    end)
    self.children = {}
    self.index = {}
end

---@param value boolean
function Node:set_enabled(value)
    pcall(function()
        self.component.Enabled = value == true
    end)
end

---@param value boolean
function Node:set_visible(value)
    pcall(function()
        self.component.Visible = value == true
    end)
end

---@param color Microsoft.Xna.Framework.Color
function Node:set_color(color)
    self.component.Color = color
end

---@param expected string
local function assert_type(self, expected)
    if self.type ~= expected then
        error(string.format("ui node type mismatch at %s: expected %s, got %s", self.path, expected, self.type), 0)
    end
end

function Node:as_text()
    assert_type(self, "TextBlock")
    local component = self.component
    return {
        set_text = function(_, value)
            component.Text = tostring(value or "")
        end,
    }
end

function Node:as_button()
    assert_type(self, "Button")
    local component = self.component
    return {
        on_click = function(_, callback)
            component.OnClicked = function()
                return callback()
            end
        end,
    }
end

function Node:as_dropdown()
    assert_type(self, "DropDown")
    local component = self.component
    return {
        set_items = function(_, items)
            pcall(function()
                component.ClearChildren()
            end)
            for _, item in ipairs(items or {}) do
                component.AddItem(tostring(item), item)
            end
        end,
        set_selected = function(_, value)
            pcall(function()
                component.SelectItem(value)
            end)
        end,
        on_selected = function(_, callback)
            component.OnSelected = function(_, selected)
                callback(selected)
                return true
            end
        end,
    }
end

function Node:as_slider()
    assert_type(self, "ScrollBar")
    local component = self.component
    return {
        set_value = function(_, value)
            component.BarScrollValue = tonumber(value) or 0
        end,
        on_changed = function(_, callback)
            component.OnMoved = function()
                callback(component.BarScrollValue)
                return true
            end
        end,
    }
end

function Node:as_image()
    assert_type(self, "Image")
    local component = self.component
    return {
        set_sprite = function(_, path, source_rect)
            local sprite
            if type(source_rect) == "table" then
                sprite = Sprite(
                    path,
                    Rectangle(
                        tonumber(source_rect.x or source_rect[1]) or 0,
                        tonumber(source_rect.y or source_rect[2]) or 0,
                        tonumber(source_rect.width or source_rect[3]) or 0,
                        tonumber(source_rect.height or source_rect[4]) or 0
                    ),
                    Vector2(0.5, 0.5),
                    0
                )
            else
                sprite = Sprite(path, nil, Vector2(0.5, 0.5), 0)
            end
            component.Sprite = sprite
        end,
        set_offset = function(_, x, y)
            component.RectTransform.AbsoluteOffset = Point(tonumber(x) or 0, tonumber(y) or 0)
        end,
        set_size = function(_, width, height)
            component.RectTransform.IsFixedSize = true
            component.RectTransform.NonScaledSize = Point(tonumber(width) or 0, tonumber(height) or 0)
        end,
    }
end

function Node:as_container()
    local node = self
    return {
        _node = node,
        clear = function()
            node:clear()
        end,
    }
end

return Node
