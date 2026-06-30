---@class PreviewLayer
---@field atlas_path string
---@field source_x integer
---@field source_y integer
---@field source_width integer
---@field source_height integer
---@field target_x integer
---@field target_y integer
---@field target_width integer
---@field target_height integer

---@class PreviewRenderPlan
---@field item string
---@field width integer
---@field height integer
---@field base PreviewLayer
---@field overlays PreviewLayer[]

---@class PreviewRenderer
---@field render fun(registry: Registry, draft_settings: settings, item_name: string): PreviewRenderPlan|nil

---@type PreviewRenderer
local preview_renderer = {}

local ICON_SIZE = 64

---@param value number
---@param min_value number
---@param max_value number
---@return number
---Keeps computed overlay placement inside icon-space bounds.
local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

---@param value number
---@return integer
---Converts fractional scale/position math back into whole pixels.
local function round(value)
    return math.floor(value + 0.5)
end

---@param texturepack TexturepackAssets
---@param item_name string
---@return item_atlas_item|nil
---Finds the base icon entry for one item in the active texturepack atlas.
local function find_item(texturepack, item_name)
    for _, item in ipairs(texturepack.item_atlas) do
        if item.item == item_name then
            return item
        end
    end
end

---@param overlaypack OverlaypackAssets
---@param texturepack_name string
---@param item_name string
---@return string|nil
---Resolves which overlay image, if any, applies to this texturepack item.
local function find_item_overlay_name(overlaypack, texturepack_name, item_name)
    local item_overlays = overlaypack.item_overlays[texturepack_name]
    if item_overlays == nil then
        return nil
    end

    for _, item_overlay in ipairs(item_overlays) do
        if item_overlay.item == item_name then
            return item_overlay.overlay
        end
    end
end

---@param overlaypack OverlaypackAssets
---@param overlay_name string
---@return overlay_atlas_item|nil
---Finds the overlay's source rectangle in its overlaypack atlas.
local function find_overlay_atlas_item(overlaypack, overlay_name)
    for _, overlay in ipairs(overlaypack.overlay_atlas) do
        if overlay.overlay == overlay_name then
            return overlay
        end
    end
end

---@param overlay overlay_atlas_item
---@param setting overlaypack_setting
---@param overlaypack OverlaypackAssets
---@return PreviewLayer|nil
---Turns an overlay atlas entry plus UI settings into a drawable preview layer.
local function create_overlay_layer(overlay, setting, overlaypack)
    if setting.scale <= 0 then
        return nil
    end

    local scaled_width = math.max(1, round(overlay.width * setting.scale))
    local scaled_height = math.max(1, round(overlay.height * setting.scale))
    local target_width = math.min(ICON_SIZE, scaled_width)
    local target_height = math.min(ICON_SIZE, scaled_height)

    -- When scale makes an overlay larger than the icon, crop from the scaled
    -- overlay's top-left before clamping its final in-icon position.
    local source_width = overlay.width
    local source_height = overlay.height
    if target_width < scaled_width then
        source_width = math.max(1, math.min(overlay.width, math.floor(target_width / setting.scale)))
    end
    if target_height < scaled_height then
        source_height = math.max(1, math.min(overlay.height, math.floor(target_height / setting.scale)))
    end

    return {
        atlas_path = overlaypack.atlas_path,
        source_x = overlay.x,
        source_y = overlay.y,
        source_width = source_width,
        source_height = source_height,
        target_x = round(clamp(setting.x, 0, ICON_SIZE - target_width)),
        target_y = round(clamp(setting.y, 0, ICON_SIZE - target_height)),
        target_width = target_width,
        target_height = target_height,
    }
end

---@param registry Registry
---@param draft_settings settings
---@param item_name string
---@return PreviewRenderPlan|nil
---Builds a declarative render plan for the preview UI without creating GUI objects.
function preview_renderer.render(registry, draft_settings, item_name)
    local texturepack = registry.texturepacks[draft_settings.texturepack]
    if texturepack == nil then
        return nil
    end

    local item = find_item(texturepack, item_name)
    if item == nil then
        return nil
    end

    ---@type PreviewLayer[]
    local overlays = {}

    -- Overlaypacks are applied in draft_settings order, matching the editable
    -- layer list and preserving the user's chosen visual stacking.
    for _, setting in ipairs(draft_settings.overlaypacks) do
        local overlaypack = registry.overlaypacks[setting.name]
        if overlaypack ~= nil then
            local overlay_name = find_item_overlay_name(overlaypack, draft_settings.texturepack, item_name)
            local overlay = overlay_name ~= nil and find_overlay_atlas_item(overlaypack, overlay_name) or nil
            if overlay ~= nil then
                local layer = create_overlay_layer(overlay, setting, overlaypack)
                if layer ~= nil then
                    table.insert(overlays, layer)
                end
            end
        end
    end

    return {
        item = item.item,
        width = ICON_SIZE,
        height = ICON_SIZE,
        base = {
            atlas_path = texturepack.icons_path,
            source_x = item.icon_x,
            source_y = item.icon_y,
            source_width = item.icon_width,
            source_height = item.icon_height,
            target_x = 0,
            target_y = 0,
            target_width = ICON_SIZE,
            target_height = ICON_SIZE,
        },
        overlays = overlays,
    }
end

return preview_renderer
