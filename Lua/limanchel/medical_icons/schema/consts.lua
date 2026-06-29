---@alias overlay_availability_slot
---| '"top-left"'
---| '"top-right"'
---| '"bottom-left"'
---| '"bottom-right"'

---@alias schemas_error
---| '"invalid_json"'
---| '"invalid_schema"'
---| '"version_mismatch"'

---@class SchemaConsts
---@field ERROR_INVALID_JSON string
---@field ERROR_INVALID_SCHEMA string

---@type SchemaConsts
return {
    ERROR_INVALID_JSON = "invalid_json",
    ERROR_INVALID_SCHEMA = "invalid_schema",
}
