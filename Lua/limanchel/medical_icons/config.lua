---@class ConfigDefaults
---@field icon_origin Microsoft.Xna.Framework.Vector2
---@field sprite_origin Microsoft.Xna.Framework.Vector2
---@field sprite_rotation number
---@field sprite_depth number

---@class HoldableData
---@field hold_angle number|nil
---@field handle1 Microsoft.Xna.Framework.Vector2|nil
---@field handle2 Microsoft.Xna.Framework.Vector2|nil

---@class TextureData
---@field holdable HoldableData|nil

---@class ItemData
---@field holdable HoldableData|nil

---@class Config
---@field defaults ConfigDefaults
---@field textures table<string, TextureData>
---@field items table<string, ItemData>

---@type Config
local config = {
    defaults = {
        icon_origin = Vector2(0.5, 0.5),
        sprite_origin = Vector2(0.5, 0.5),
        sprite_rotation = 0,
        sprite_depth = 0.6,
    },

    textures = {
        ampoule = {
            holdable = {
                hold_angle = 7,
                handle1 = Vector2(-3, -7),
                handle2 = Vector2(-3, -7),
            },
        },

        pocket_injector = {
            holdable = {
                hold_angle = 7,
                handle1 = Vector2(-2, -8),
                handle2 = Vector2(-2, -8),
            },
        },

        vial = {
            holdable = {
                hold_angle = 7,
                handle1 = Vector2(-2, -9),
                handle2 = Vector2(-2, -9),
            },
        },
    },

    items = {},
}

return config
