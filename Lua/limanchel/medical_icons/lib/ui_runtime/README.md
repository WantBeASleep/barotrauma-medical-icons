# Barotrauma UI Runtime

Strict JSON-to-Barotrauma-GUI runtime.

The JSON layout is only a static blueprint: geometry, immutable labels,
styles, containers, and templates. Runtime data and behavior belong in Lua.

## Loading

The library has one public entry point: `init.lua`.

For this project:

```lua
local ui_runtime = assert(loadfile(LUA_PATH .. "/lib/ui_runtime/init.lua"))({
    mod_path = MOD_PATH,
    lua_path = LUA_PATH,
})
```

For a copied/vendor path:

```lua
local UI_RUNTIME_PATH = LUA_PATH .. "/vendor/ui_runtime"

local ui_runtime = assert(loadfile(UI_RUNTIME_PATH .. "/init.lua"))({
    mod_path = MOD_PATH,
    runtime_path = UI_RUNTIME_PATH,
})
```

All internal files are loaded relative to `runtime_path`, so moving the library
only requires changing the entry path.

## Lifecycle

Runtime UI code usually follows this shape:

```lua
local layout = ui_runtime.load_layout(MOD_PATH .. "/ui/layouts/menu.json")

local ui = ui_runtime.render(layout, GUI.PauseMenu.RectTransform, {
    mod_path = MOD_PATH,
})
```

Recommended lifecycle:

- Load or cache the parsed JSON once if the layout is stable.
- Render a fresh UI tree each time the Barotrauma menu/window is opened.
- Bind runtime data and callbacks from Lua after rendering.
- Rebuild dynamic containers from templates when list structure changes.

`ui_runtime.render(...)` validates the layout before creating GUI components.

## Static Lookup

Static elements are found by dot path.

Given JSON:

```json
{
  "type": "Frame",
  "id": "window",
  "children": [
    {
      "type": "Frame",
      "id": "overlay",
      "children": [
        { "type": "TextBlock", "id": "count", "text": "" },
        { "type": "Button", "id": "add", "text": "+ ADD" },
        { "type": "ListBox", "id": "list" }
      ]
    }
  ]
}
```

Lua:

```lua
local count = ui:get("window.overlay.count")
local add = ui:get("window.overlay.add")
local list = ui:get("window.overlay.list")
```

`get(path)` is strict and throws if the element is missing. Use `maybe(path)`
for optional elements:

```lua
local debug_panel = ui:maybe("window.debug")
```

## Nodes

`ui:get(...)` returns a `ui_runtime.Node`. A node is a wrapper around one
created Barotrauma GUI component. Node methods do not search for other
components unless the method is named `get` or `maybe`.

Common node methods:

```lua
node:component()
node:remove()
node:clear()
node:set_enabled(true)
node:set_visible(false)
node:set_color(Color(255, 255, 255, 255))
```

Use typed adapters for type-specific behavior:

```lua
node:as_text():set_text("2 active")
node:as_button():on_click(function()
    return true
end)
node:as_dropdown():set_items({ "default", "vanilla" })
node:as_dropdown():set_selected("default")
node:as_dropdown():on_selected(function(value)
end)
node:as_slider():set_value(1)
node:as_slider():on_changed(function(value)
end)
node:as_image():set_sprite(path, { x = 0, y = 0, width = 64, height = 64 })
node:as_container():clear()
```

Adapters check the JSON type. Calling `as_dropdown()` on a `TextBlock` is an
error.

## Templates

Templates describe repeatable UI pieces. They are not rendered automatically.
Lua creates template instances when needed.

JSON:

```json
{
  "templates": {
    "overlayRow": {
      "type": "Frame",
      "id": "row",
      "fixedSize": [520, 112],
      "children": [
        { "type": "DropDown", "id": "name", "maxVisibleItems": 8 },
        { "type": "Button", "id": "remove", "text": "X" },
        { "type": "ScrollBar", "id": "scale", "range": [0, 3], "step": 0.1 }
      ]
    }
  }
}
```

Lua:

```lua
local list = ui:get("window.overlay.list")
list:clear()

for index, setting in ipairs(draft.overlaypacks) do
    local row = ui:create("overlayRow", list)

    row:get("name"):as_dropdown():set_items(available_names)
    row:get("name"):as_dropdown():set_selected(setting.name)
    row:get("scale"):as_slider():set_value(setting.scale)

    row:get("remove"):as_button():on_click(function()
        table.remove(draft.overlaypacks, index)
        redraw_overlay_rows()
        return true
    end)
end
```

Each template instance has its own local lookup scope. `row:get("scale")`
searches only inside that one row.

## Binder Example

The runtime renderer does not know project state. A project-specific binder
connects the rendered UI to registry/settings/callbacks.

```lua
local function bind_menu(ui, registry, draft, on_apply)
    local count = ui:get("window.overlay.count"):as_text()
    local add = ui:get("window.overlay.add"):as_button()
    local list = ui:get("window.overlay.list")

    local function redraw_overlay_rows()
        list:clear()
        count:set_text(tostring(#draft.overlaypacks) .. " active")

        for index, setting in ipairs(draft.overlaypacks) do
            local row = ui:create("overlayRow", list)

            local name = row:get("name"):as_dropdown()
            name:set_items(registry.overlaypack_names)
            name:set_selected(setting.name)
            name:on_selected(function(value)
                setting.name = tostring(value)
                redraw_overlay_rows()
            end)

            row:get("scale"):as_slider():set_value(setting.scale)
            row:get("scale"):as_slider():on_changed(function(value)
                setting.scale = value
            end)

            row:get("remove"):as_button():on_click(function()
                table.remove(draft.overlaypacks, index)
                redraw_overlay_rows()
                return true
            end)
        end
    end

    add:on_click(function()
        table.insert(draft.overlaypacks, {
            name = registry.overlaypack_names[1],
            x = 0,
            y = 0,
            scale = 1,
        })
        redraw_overlay_rows()
        return true
    end)

    ui:get("window.actions.apply"):as_button():on_click(function()
        on_apply(draft)
        return true
    end)

    redraw_overlay_rows()
end
```

## Forbidden In JSON

Dynamic fields are rejected by the validator:

- `items`
- `selected`
- `value`
- `placeholder`
- `enabled`
- `visible`
- `onClick`
- `binding`
- `action`
- `openUrl`

Lua owns all runtime state, callbacks, list contents, selected values, and
preview rendering.
