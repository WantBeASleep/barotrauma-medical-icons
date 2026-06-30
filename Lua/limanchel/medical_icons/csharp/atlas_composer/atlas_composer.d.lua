---@meta

---@alias AtlasComposerErrorCode
---| '"compose_failed"'
---| '"null_operations"'
---| '"null_operation"'
---| '"null_overlays"'
---| '"null_overlay"'
---| '"texture_read_failed"'
---| '"texture_load_failed"'
---| '"atlas_write_failed"'
---| '"graphics_device_unavailable"'
---| '"invalid_overlay_rect"'
---| '"invalid_overlay_scale"'
---| '"overlay_source_out_of_bounds"'
---| '"overlay_out_of_bounds"'
---| '"empty_input_path"'
---| '"input_path_must_be_absolute"'
---| '"invalid_input_path"'
---| '"input_file_not_found"'

---@alias AtlasComposerException { Code: AtlasComposerErrorCode, Message: string, InnerException: any }

---@class AtlasOverlayPackOperation
---@field OverlayPackAtlasPath string
---@field OverlayOffsetWithinIconX number
---@field OverlayOffsetWithinIconY number
---@field OverlayScale number
---@field Overlays AtlasOverlayApply[]

---@class AtlasOverlayApply
---@field OverlayAtlasSourceX integer
---@field OverlayAtlasSourceY integer
---@field OverlayAtlasSourceWidth integer
---@field OverlayAtlasSourceHeight integer
---@field OutputAtlasIconX integer
---@field OutputAtlasIconY integer

---@class AtlasComposerUserData
local AtlasComposer = {}

---Loads one atlas PNG, applies scaled overlay rectangles from overlaypack atlas PNGs, and saves the result into Storage.
---The input atlas and overlaypack atlas paths must be absolute filesystem paths.
---The output path must be a Storage relative path, for example "medical-icons/cache/icons.png".
---@param inputAtlasPath string
---@param outputStoragePath string
---@param operations AtlasOverlayPackOperation[]
---@return integer applied_count
---@throws AtlasComposerException
---@throws StorageException
function AtlasComposer.Compose(inputAtlasPath, outputStoragePath, operations) end
