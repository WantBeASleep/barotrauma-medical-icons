local context = ...

local Node = context.load("node.lua")
local Tree = context.load("tree.lua")

---@class ui_runtime.Renderer
---@field render fun(layout: table, parent: Barotrauma.RectTransform, options: table): ui_runtime.Tree

---@type ui_runtime.Renderer
local renderer = {}

local ANCHOR_NAMES = {
    BottomCenter = true,
    BottomLeft = true,
    BottomRight = true,
    Center = true,
    CenterLeft = true,
    CenterRight = true,
    TopCenter = true,
    TopLeft = true,
    TopRight = true,
}

---@param enum table
---@param name string|nil
---@param fallback any
---@return any
local function enum_value(enum, name, fallback)
    if type(name) ~= "string" or name == "" then
        return fallback
    end
    local ok, value = pcall(function()
        return enum[name]
    end)
    if ok and value ~= nil then
        return value
    end
    return fallback
end

---@param value table|nil
---@return Microsoft.Xna.Framework.Color|nil
local function make_color(value)
    if type(value) ~= "table" then
        return nil
    end
    return Color(
        tonumber(value[1]) or 255,
        tonumber(value[2]) or 255,
        tonumber(value[3]) or 255,
        tonumber(value[4]) or 255
    )
end

---@param node table
---@return Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
local function make_size(node)
    if type(node.fixedSize) == "table" then
        return Point(tonumber(node.fixedSize[1]) or 0, tonumber(node.fixedSize[2]) or 0)
    end
    local size = node.size or { 1, 1 }
    return Vector2(tonumber(size[1]) or 1, tonumber(size[2]) or 1)
end

---@param node table
---@param parent_transform Barotrauma.RectTransform
---@return Barotrauma.RectTransform
local function make_rect(node, parent_transform)
    local anchor = enum_value(GUI.Anchor, node.anchor, GUI.Anchor.TopLeft)
    local pivot = enum_value(GUI.Pivot, node.pivot, GUI.Pivot.TopLeft)
    if ANCHOR_NAMES[node.anchor] and node.pivot == nil then
        return GUI.RectTransform(make_size(node), parent_transform, anchor)
    end
    return GUI.RectTransform(make_size(node), parent_transform, anchor, pivot)
end

---@param path string
---@param mod_path string|nil
---@return string
local function resolve_asset_path(path, mod_path)
    if string.match(path, "^%a:[/\\]") or string.sub(path, 1, 1) == "/" then
        return path
    end
    if mod_path ~= nil then
        return mod_path .. "/" .. path
    end
    return path
end

---@param component Barotrauma.GUIComponent
---@param spec table
local function apply_common(component, spec)
    component.UserData = spec.id
    if spec.canBeFocused ~= nil then
        component.CanBeFocused = spec.canBeFocused == true
    end

    local color = make_color(spec.color)
    if color ~= nil then
        component.Color = color
    end
    local hover_color = make_color(spec.hoverColor)
    if hover_color ~= nil then
        component.HoverColor = hover_color
    end
    local selected_color = make_color(spec.selectedColor)
    if selected_color ~= nil then
        component.SelectedColor = selected_color
    end
    if type(spec.absoluteOffset) == "table" then
        component.RectTransform.AbsoluteOffset =
            Point(tonumber(spec.absoluteOffset[1]) or 0, tonumber(spec.absoluteOffset[2]) or 0)
    end
end

---@param layout Barotrauma.GUILayoutGroup
---@param spec table
local function apply_layout_props(layout, spec)
    layout.Stretch = spec.stretch == true
    if spec.childAnchor ~= nil then
        layout.ChildAnchor = enum_value(GUI.Anchor, spec.childAnchor, GUI.Anchor.TopLeft)
    end
    if spec.relativeSpacing ~= nil then
        layout.RelativeSpacing = tonumber(spec.relativeSpacing) or 0
    end
    if spec.absoluteSpacing ~= nil then
        layout.AbsoluteSpacing = tonumber(spec.absoluteSpacing) or 0
    end
end

---@param spec table
---@param rect Barotrauma.RectTransform
---@param diagnostics table
---@param mod_path string|nil
---@return Barotrauma.GUIComponent
local function create_image(spec, rect, diagnostics, mod_path)
    if type(spec.path) ~= "string" or spec.path == "" then
        return GUI.Image(rect, nil, spec.scaleToFit ~= false)
    end

    local source = spec.sourceRect
    local ok, sprite = pcall(function()
        local full_path = resolve_asset_path(spec.path, mod_path)
        if type(source) == "table" then
            return Sprite(
                full_path,
                Rectangle(
                    tonumber(source[1]) or 0,
                    tonumber(source[2]) or 0,
                    tonumber(source[3]) or 0,
                    tonumber(source[4]) or 0
                ),
                Vector2(0.5, 0.5),
                0
            )
        end
        return Sprite(full_path, nil, Vector2(0.5, 0.5), 0)
    end)

    if not ok then
        table.insert(diagnostics.warnings, {
            id = spec.id,
            kind = "image_load_failed",
            message = tostring(sprite),
        })
        return GUI.Image(rect, nil, spec.scaleToFit ~= false)
    end

    return GUI.Image(rect, sprite, spec.scaleToFit ~= false)
end

local render_node

---@param spec table
---@param parent_transform Barotrauma.RectTransform
---@param parent_node ui_runtime.Node|nil
---@param path string
---@param diagnostics table
---@param mod_path string|nil
---@param indexable boolean
---@return ui_runtime.Node
-- selene: allow(high_cyclomatic_complexity)
function render_node(spec, parent_transform, parent_node, path, diagnostics, mod_path, indexable)
    local rect = make_rect(spec, parent_transform)
    local component
    local node_type = spec.type
    local style = spec.style

    if node_type == "Frame" then
        local color = make_color(spec.color)
        if color ~= nil then
            component = GUI.Frame(rect, style ~= nil and tostring(style) or nil, color)
        else
            component = style ~= nil and GUI.Frame(rect, tostring(style)) or GUI.Frame(rect)
        end
    elseif node_type == "LayoutGroup" then
        component = GUI.LayoutGroup(rect, spec.direction == "horizontal")
        apply_layout_props(component, spec)
    elseif node_type == "TextBlock" then
        component = GUI.TextBlock(
            rect,
            tostring(spec.text or ""),
            make_color(spec.textColor),
            nil,
            enum_value(GUI.Alignment, spec.alignment, GUI.Alignment.CenterLeft)
        )
        if spec.textScale ~= nil then
            component.TextScale = tonumber(spec.textScale) or 1
        end
    elseif node_type == "Button" then
        if style ~= nil then
            component = GUI.Button(rect, tostring(spec.text or ""), GUI.Alignment.Center, tostring(style))
        else
            component = GUI.Button(rect, tostring(spec.text or ""))
        end
    elseif node_type == "DropDown" then
        component = GUI.DropDown(rect, "", tonumber(spec.maxVisibleItems) or 1)
    elseif node_type == "ListBox" then
        component = GUI.ListBox(rect, spec.isHorizontal == true, nil, style ~= nil and tostring(style) or nil)
        if spec.spacing ~= nil then
            component.Spacing = tonumber(spec.spacing) or 0
        end
        if spec.autoHideScrollBar ~= nil then
            component.AutoHideScrollBar = spec.autoHideScrollBar == true
        end
        if spec.keepSpaceForScrollBar ~= nil then
            component.KeepSpaceForScrollBar = spec.keepSpaceForScrollBar == true
        end
    elseif node_type == "ScrollBar" then
        component = GUI.ScrollBar(rect, tonumber(spec.barSize) or 0.08, nil, style)
        if type(spec.range) == "table" then
            component.Range = Vector2(tonumber(spec.range[1]) or 0, tonumber(spec.range[2]) or 1)
        end
        if spec.step ~= nil then
            component.StepValue = tonumber(spec.step) or 0
        end
    elseif node_type == "TickBox" then
        component = GUI.TickBox(rect, tostring(spec.text or ""))
    elseif node_type == "Image" then
        component = create_image(spec, rect, diagnostics, mod_path)
    elseif node_type == "ScissorComponent" then
        component = GUI.ScissorComponent(rect)
    end

    local node = Node.new(component, node_type, spec.id, path, parent_node)
    apply_common(component, spec)

    if parent_node ~= nil then
        parent_node:add_child(node, indexable)
    end

    local child_parent = component.RectTransform
    if node_type == "ListBox" or node_type == "ScissorComponent" then
        local ok, content = pcall(function()
            return component.Content
        end)
        if ok and content ~= nil then
            child_parent = content.RectTransform
        end
    end

    if type(spec.children) == "table" then
        for _, child in ipairs(spec.children) do
            render_node(child, child_parent, node, path .. "." .. tostring(child.id), diagnostics, mod_path, true)
        end
    end

    return node
end

---@param layout table
---@param parent Barotrauma.RectTransform
---@param options table
---@return ui_runtime.Tree
function renderer.render(layout, parent, options)
    local diagnostics = { warnings = {} }
    local mod_path = options.mod_path or context.mod_path
    local root = render_node(layout.root, parent, nil, tostring(layout.root.id), diagnostics, mod_path, true)
    local tree = Tree.new(root, layout.templates or {}, diagnostics)

    tree.instantiate = function(template_name, parent_node)
        local template = tree.templates[template_name]
        if template == nil then
            error("ui template not found: " .. tostring(template_name), 0)
        end
        if parent_node == nil or parent_node.component == nil then
            error("ui template parent must be a ui_runtime.Node", 0)
        end

        local parent_transform = parent_node.component.RectTransform
        if parent_node.type == "ListBox" or parent_node.type == "ScissorComponent" then
            local ok, content = pcall(function()
                return parent_node.component.Content
            end)
            if ok and content ~= nil then
                parent_transform = content.RectTransform
            end
        end

        return render_node(
            template,
            parent_transform,
            parent_node,
            parent_node.path .. "." .. tostring(template.id),
            diagnostics,
            mod_path,
            false
        )
    end

    return tree
end

return renderer
