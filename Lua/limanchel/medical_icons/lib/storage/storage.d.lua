---@meta

---@alias MedicalIcons.StorageErrorCode
---| '"empty_path"'
---| '"absolute_path_not_allowed"'
---| '"invalid_path"'
---| '"null_content"'
---| '"read_failed"'
---| '"write_failed"'
---| '"delete_failed"'
---| '"empty_extension"'
---| '"invalid_extension"'
---| '"path_must_be_directory"'
---| '"delete_recursive_extension_failed"'
---| '"storage_root_invalid"'
---| '"save_folder_unavailable"'

---@alias MedicalIcons.StorageException { Code: MedicalIcons.StorageErrorCode, Message: string, InnerException: any }

---@class MedicalIcons.Storage
local Storage = {}

---Checks whether a file exists inside Barotrauma's storage folder.
---The path must be a plain relative path, for example "medical-icons/settings.json".
---@param path string
---@return boolean
function Storage.Exists(path) end

---Reads a text file from Barotrauma's storage folder.
---Returns nil when the file does not exist.
---@param path string
---@return string|nil
---@throws MedicalIcons.StorageException
function Storage.LoadString(path) end

---Writes a text file inside Barotrauma's storage folder.
---Creates missing parent directories before writing.
---@param path string
---@param content string
---@throws MedicalIcons.StorageException
function Storage.SaveString(path, content) end

---Deletes a file from Barotrauma's storage folder.
---Returns true when a file was deleted and false when the file did not exist.
---@param path string
---@return boolean
---@throws MedicalIcons.StorageException
function Storage.Delete(path) end

---Deletes files with one extension inside a storage directory and all its subdirectories.
---The path must point to a directory. The extension must include the leading dot, for example ".png".
---@param path string
---@param extension string
---@return integer deleted_count
---@throws MedicalIcons.StorageException
function Storage.DeleteRecursiveExtension(path, extension) end

---Returns the real full path for a relative storage path.
---The returned path uses forward slashes.
---@param path string
---@return string
---@throws MedicalIcons.StorageException
function Storage.GetFullPath(path) end
