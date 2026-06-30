# barotrauma-ui-layout/v1

Top level:

```json
{
  "schema": "barotrauma-ui-layout/v1",
  "root": {},
  "templates": {}
}
```

Every node requires:

```json
{
  "type": "Frame",
  "id": "localId"
}
```

Common node fields:

```json
{
  "size": [1, 1],
  "fixedSize": [120, 40],
  "anchor": "TopLeft",
  "pivot": "TopLeft",
  "absoluteOffset": [0, 0],
  "style": "InnerFrameDark",
  "color": [255, 255, 255, 255],
  "hoverColor": [255, 255, 255, 255],
  "selectedColor": [255, 255, 255, 255],
  "canBeFocused": false,
  "children": []
}
```

Use `size` or `fixedSize`, not both.

Supported node types:

- `Frame`
- `LayoutGroup`
- `TextBlock`
- `Button`
- `DropDown`
- `ListBox`
- `ScrollBar`
- `TickBox`
- `Image`
- `ScissorComponent`

Dynamic fields are forbidden:

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

## Type Fields

`LayoutGroup`:

```json
{
  "direction": "vertical",
  "childAnchor": "TopLeft",
  "stretch": true,
  "relativeSpacing": 0.02,
  "absoluteSpacing": 8
}
```

`TextBlock`:

```json
{
  "text": "",
  "alignment": "CenterLeft",
  "textScale": 1,
  "textColor": [255, 255, 255, 255]
}
```

`Button`:

```json
{
  "text": "Apply"
}
```

`DropDown`:

```json
{
  "maxVisibleItems": 8
}
```

`ListBox`:

```json
{
  "isHorizontal": false,
  "spacing": 8,
  "autoHideScrollBar": true,
  "keepSpaceForScrollBar": true
}
```

`ScrollBar`:

```json
{
  "barSize": 0.08,
  "range": [0, 3],
  "step": 0.1
}
```

`TickBox`:

```json
{
  "text": ""
}
```

`Image`:

```json
{
  "path": "assets/ui/static.png",
  "sourceRect": [0, 0, 64, 64],
  "scaleToFit": true
}
```

For dynamic images, omit `path` and set the sprite from Lua.
