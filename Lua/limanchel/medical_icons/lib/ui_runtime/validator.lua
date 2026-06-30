---@class ui_runtime.Validator
---@field validate fun(layout: table)

---@type ui_runtime.Validator
local validator = {}

local SCHEMA = "barotrauma-ui-layout/v1"

local NODE_TYPES = {
    Button = true,
    DropDown = true,
    Frame = true,
    Image = true,
    LayoutGroup = true,
    ListBox = true,
    ScissorComponent = true,
    ScrollBar = true,
    TextBlock = true,
    TickBox = true,
}

local COMMON_FIELDS = {
    absoluteOffset = true,
    anchor = true,
    canBeFocused = true,
    children = true,
    color = true,
    fixedSize = true,
    hoverColor = true,
    id = true,
    pivot = true,
    selectedColor = true,
    size = true,
    style = true,
    type = true,
}

local TYPE_FIELDS = {
    Button = {
        text = true,
    },
    DropDown = {
        maxVisibleItems = true,
    },
    Frame = {},
    Image = {
        path = true,
        scaleToFit = true,
        sourceRect = true,
    },
    LayoutGroup = {
        absoluteSpacing = true,
        childAnchor = true,
        direction = true,
        relativeSpacing = true,
        stretch = true,
    },
    ListBox = {
        autoHideScrollBar = true,
        isHorizontal = true,
        keepSpaceForScrollBar = true,
        spacing = true,
    },
    ScissorComponent = {},
    ScrollBar = {
        barSize = true,
        range = true,
        step = true,
    },
    TextBlock = {
        alignment = true,
        text = true,
        textColor = true,
        textScale = true,
    },
    TickBox = {
        text = true,
    },
}

local BANNED_FIELDS = {
    action = true,
    binding = true,
    enabled = true,
    items = true,
    onClick = true,
    openUrl = true,
    placeholder = true,
    selected = true,
    value = true,
    visible = true,
}

---@param value any
---@return boolean
local function is_non_empty_string(value)
    return type(value) == "string" and value ~= ""
end

---@param value any
---@return boolean
local function is_array(value)
    if type(value) ~= "table" then
        return false
    end

    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or math.floor(key) ~= key or key < 1 then
            return false
        end
        count = count + 1
    end

    return count == #value
end

---@param value any
---@return boolean
local function is_number_pair(value)
    return is_array(value) and #value == 2 and type(value[1]) == "number" and type(value[2]) == "number"
end

---@param value any
---@return boolean
local function is_color(value)
    return is_array(value)
        and #value == 4
        and type(value[1]) == "number"
        and type(value[2]) == "number"
        and type(value[3]) == "number"
        and type(value[4]) == "number"
end

---@param path string
---@param message string
local function fail(path, message)
    error(string.format("ui layout invalid at %s: %s", path, message), 0)
end

---@param node table
---@param path string
local function validate_node(node, path)
    if type(node) ~= "table" then
        fail(path, "node must be an object")
    end

    if not is_non_empty_string(node.type) or NODE_TYPES[node.type] ~= true then
        fail(path, "unknown or missing type")
    end

    if not is_non_empty_string(node.id) then
        fail(path, "missing id")
    end

    local type_fields = TYPE_FIELDS[node.type] or {}
    for key in pairs(node) do
        if BANNED_FIELDS[key] == true then
            fail(path, "dynamic field is not allowed: " .. tostring(key))
        end
        if COMMON_FIELDS[key] ~= true and type_fields[key] ~= true then
            fail(path, "unknown field: " .. tostring(key))
        end
    end

    if node.size ~= nil and node.fixedSize ~= nil then
        fail(path, "use size or fixedSize, not both")
    end
    if node.size ~= nil and not is_number_pair(node.size) then
        fail(path, "size must be [number, number]")
    end
    if node.fixedSize ~= nil and not is_number_pair(node.fixedSize) then
        fail(path, "fixedSize must be [number, number]")
    end
    if node.absoluteOffset ~= nil and not is_number_pair(node.absoluteOffset) then
        fail(path, "absoluteOffset must be [number, number]")
    end
    if node.color ~= nil and not is_color(node.color) then
        fail(path, "color must be [r, g, b, a]")
    end
    if node.hoverColor ~= nil and not is_color(node.hoverColor) then
        fail(path, "hoverColor must be [r, g, b, a]")
    end
    if node.selectedColor ~= nil and not is_color(node.selectedColor) then
        fail(path, "selectedColor must be [r, g, b, a]")
    end
    if node.textColor ~= nil and not is_color(node.textColor) then
        fail(path, "textColor must be [r, g, b, a]")
    end
    if node.range ~= nil and not is_number_pair(node.range) then
        fail(path, "range must be [number, number]")
    end
    if node.children ~= nil and not is_array(node.children) then
        fail(path, "children must be an array")
    end

    local child_ids = {}
    if type(node.children) == "table" then
        for index, child in ipairs(node.children) do
            if type(child) ~= "table" then
                fail(path .. ".children[" .. tostring(index) .. "]", "child must be an object")
            end
            if child.id ~= nil then
                local child_id = tostring(child.id)
                if child_ids[child_id] == true then
                    fail(path, "duplicate child id: " .. child_id)
                end
                child_ids[child_id] = true
            end
            validate_node(child, path .. "." .. tostring(child.id or index))
        end
    end
end

---@param layout table
function validator.validate(layout)
    if type(layout) ~= "table" then
        fail("$", "layout must be an object")
    end
    if layout.schema ~= SCHEMA then
        fail("$", "schema must be " .. SCHEMA)
    end
    for key in pairs(layout) do
        if key ~= "schema" and key ~= "root" and key ~= "templates" then
            fail("$", "unknown top-level field: " .. tostring(key))
        end
    end
    validate_node(layout.root, "$.root")

    if layout.templates ~= nil and type(layout.templates) ~= "table" then
        fail("$.templates", "templates must be an object")
    end
    if type(layout.templates) == "table" then
        for name, template in pairs(layout.templates) do
            if not is_non_empty_string(name) then
                fail("$.templates", "template name must be a non-empty string")
            end
            validate_node(template, "$.templates." .. tostring(name))
        end
    end
end

return validator
