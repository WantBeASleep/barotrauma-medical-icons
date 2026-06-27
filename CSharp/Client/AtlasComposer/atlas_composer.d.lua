---@meta

---@alias MedicalIcons.AtlasComposerErrorCode
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
---| '"overlay_source_out_of_bounds"'
---| '"overlay_out_of_bounds"'
---| '"empty_input_path"'
---| '"input_path_must_be_absolute"'
---| '"invalid_input_path"'
---| '"input_file_not_found"'

---@alias MedicalIcons.AtlasComposerException { Code: MedicalIcons.AtlasComposerErrorCode, Message: string, InnerException: any }

---@class MedicalIcons.AtlasOverlayPackOperation
---@field OverlayPackAtlasPath string
---@field Overlays MedicalIcons.AtlasOverlayApply[]

---@class MedicalIcons.AtlasOverlayApply
---@field SourceX integer
---@field SourceY integer
---@field SourceWidth integer
---@field SourceHeight integer
---@field TargetX integer
---@field TargetY integer

---@class MedicalIcons.AtlasComposer
local AtlasComposer = {}

---Loads one atlas PNG, applies rectangles from overlaypack atlas PNGs, and saves the result into Storage.
---The input atlas and overlaypack atlas paths must be absolute filesystem paths.
---The output path must be a Storage relative path, for example "medical-icons/cache/icons.png".
---@param inputAtlasPath string
---@param outputStoragePath string
---@param operations MedicalIcons.AtlasOverlayPackOperation[]
---@return integer applied_count
---@throws MedicalIcons.AtlasComposerException
---@throws MedicalIcons.StorageException
function AtlasComposer.Compose(inputAtlasPath, outputStoragePath, operations) end
