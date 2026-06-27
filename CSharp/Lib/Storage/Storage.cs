using System;
using System.IO;
using System.Reflection;
using System.Security;

using Barotrauma;
using Microsoft.Xna.Framework.Graphics;

namespace MedicalIcons
{
    public sealed class StorageException : Exception
    {
        public string Code { get; private set; }

        public StorageException(string code, string message)
            : base(message)
        {
            Code = code;
        }

        public StorageException(string code, string message, Exception innerException)
            : base(message, innerException)
        {
            Code = code;
        }
    }

    public static class Storage
    {
        private const string StorageDirectoryName = "ModConfigs";

        // Checks whether a file exists inside Barotrauma's storage folder.
        // The input path is a Lua-facing relative path such as
        // "medical-icons/settings.json"; it is resolved under ModConfigs first,
        // so Lua never needs to know the real save-folder location.
        public static bool Exists(string path)
        {
            return File.Exists(ResolvePath(path));
        }

        // Reads a text file from Barotrauma's storage folder.
        // Missing files are treated as an empty string because this is convenient
        // for optional config/cache files: Lua can parse defaults without first
        // checking Exists().
        public static string LoadString(string path)
        {
            string fullPath = ResolvePath(path);
            if (!File.Exists(fullPath))
            {
                return string.Empty;
            }

            try
            {
                return File.ReadAllText(fullPath);
            }
            catch (Exception exception) when (IsFileAccessException(exception))
            {
                throw new StorageException("read_failed", "Could not read storage file.", exception);
            }
        }

        // Writes text to a file inside Barotrauma's storage folder.
        // Before writing, it creates the parent directory chain. For example,
        // saving "medical-icons/cache/file.json" creates both "medical-icons"
        // and "cache" if they do not already exist.
        public static void SaveString(string path, string content)
        {
            if (content == null)
            {
                throw new StorageException("null_content", "Storage content must not be null.");
            }

            string fullPath = ResolvePath(path);
            string directoryPath = Path.GetDirectoryName(fullPath) ?? string.Empty;

            try
            {
                if (!string.IsNullOrWhiteSpace(directoryPath))
                {
                    Directory.CreateDirectory(directoryPath);
                }

                File.WriteAllText(fullPath, content);
            }
            catch (Exception exception) when (IsFileAccessException(exception))
            {
                throw new StorageException("write_failed", "Could not write storage file.", exception);
            }
        }

        // C#-only helper for writing Texture2D PNG files through the same Storage
        // path rules as SaveString. This is intentionally not exposed in Lua annotations.
        public static void SavePng(string path, Texture2D texture)
        {
            if (texture == null)
            {
                throw new StorageException("null_texture", "Storage PNG texture must not be null.");
            }

            string fullPath = ResolvePath(path);
            string directoryPath = Path.GetDirectoryName(fullPath) ?? string.Empty;

            try
            {
                if (!string.IsNullOrWhiteSpace(directoryPath))
                {
                    Directory.CreateDirectory(directoryPath);
                }

                using (FileStream outputStream = File.Create(fullPath))
                {
                    texture.SaveAsPng(outputStream, texture.Width, texture.Height);
                }
            }
            catch (Exception exception) when (IsFileAccessException(exception))
            {
                throw new StorageException("write_png_failed", "Could not write storage PNG file.", exception);
            }
        }

        // Deletes a file from Barotrauma's storage folder.
        // Returns true when a file was actually deleted and false when the file
        // did not exist. Invalid paths and IO failures are still thrown as
        // StorageException so Lua can handle them through pcall().
        public static bool Delete(string path)
        {
            string fullPath = ResolvePath(path);

            try
            {
                if (!File.Exists(fullPath))
                {
                    return false;
                }

                File.Delete(fullPath);
                return true;
            }
            catch (Exception exception) when (IsFileAccessException(exception))
            {
                throw new StorageException("delete_failed", "Could not delete storage file.", exception);
            }
        }

        // Deletes files with one extension inside a storage directory and all its subdirectories.
        // The path must point to a directory, not a file. The extension must look like ".png".
        // Returns how many files were deleted. If the directory does not exist, returns 0.
        public static int DeleteRecursiveExtension(string path, string extension)
        {
            string fullPath = ResolvePath(path);
            ValidateExtension(extension);

            try
            {
                if (File.Exists(fullPath))
                {
                    throw new StorageException("path_must_be_directory", "Storage path must be a directory.");
                }

                if (!Directory.Exists(fullPath))
                {
                    return 0;
                }

                int deletedCount = 0;
                foreach (string filePath in Directory.EnumerateFiles(fullPath, "*", SearchOption.AllDirectories))
                {
                    if (!Path.GetExtension(filePath).Equals(extension, StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }

                    File.Delete(filePath);
                    deletedCount++;
                }

                return deletedCount;
            }
            catch (StorageException)
            {
                throw;
            }
            catch (Exception exception) when (IsFileAccessException(exception))
            {
                throw new StorageException(
                    "delete_recursive_extension_failed",
                    "Could not delete storage files by extension.",
                    exception);
            }
        }

        // Returns the real full path for a Lua-facing relative storage path.
        // The returned string uses forward slashes to make it easier to consume
        // from Lua and from Barotrauma APIs that usually accept slash-separated
        // paths. File IO methods in this class still use native system paths.
        public static string GetFullPath(string path)
        {
            return NormalizePath(ResolvePath(path));
        }

        // Converts a Lua-facing relative path into a real absolute filesystem path.
        // Lua is only allowed to pass simple paths like "medical-icons/cache/file.json".
        // Complicated paths with "..", ".", "//", "\", or absolute roots are rejected.
        private static string ResolvePath(string path)
        {
            ValidateRelativePath(path);

            string storageRoot = GetStorageRoot();

            try
            {
                return Path.GetFullPath(Path.Combine(storageRoot, path));
            }
            catch (Exception exception) when (IsPathException(exception))
            {
                throw new StorageException("invalid_path", "Storage path is invalid.", exception);
            }
        }

        // Rejects anything except a plain relative path made of normal file-name parts.
        // Good: "medical-icons/settings.json", "medical-icons/cache/file.json".
        // Bad: "../file.json", "folder//file.json", "./file.json", "C:/file.json".
        private static void ValidateRelativePath(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                throw new StorageException("empty_path", "Storage path must not be empty.");
            }

            if (Path.IsPathRooted(path))
            {
                throw new StorageException("absolute_path_not_allowed", "Storage path must be relative.");
            }

            if (path.IndexOf('\\') >= 0)
            {
                throw new StorageException("invalid_path", "Storage path must use '/' separators.");
            }

            string[] parts = path.Split('/');
            foreach (string part in parts)
            {
                if (string.IsNullOrWhiteSpace(part))
                {
                    throw new StorageException("invalid_path", "Storage path must not contain empty parts.");
                }

                if (part == "." || part == "..")
                {
                    throw new StorageException("invalid_path", "Storage path must not contain '.' or '..'.");
                }

                if (part.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0)
                {
                    throw new StorageException("invalid_path", "Storage path contains invalid file-name characters.");
                }
            }
        }

        // Accepts only simple file extensions like ".json" or ".png".
        // This keeps the recursive delete method from receiving wildcard patterns
        // or path-like strings.
        private static void ValidateExtension(string extension)
        {
            if (string.IsNullOrWhiteSpace(extension))
            {
                throw new StorageException("empty_extension", "Storage extension must not be empty.");
            }

            if (!extension.StartsWith(".", StringComparison.Ordinal) || extension == ".")
            {
                throw new StorageException("invalid_extension", "Storage extension must start with '.'.");
            }

            if (extension.IndexOf('/') >= 0
                || extension.IndexOf('\\') >= 0
                || extension.IndexOf('*') >= 0
                || extension.IndexOf('?') >= 0
                || extension.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0)
            {
                throw new StorageException("invalid_extension", "Storage extension contains invalid characters.");
            }
        }

        // Builds the root directory used by this storage helper.
        // The root is Barotrauma's default save folder plus "ModConfigs".
        // C# owns this location detail so Lua only has to pass paths relative
        // to the storage root.
        private static string GetStorageRoot()
        {
            string saveFolder = GetDefaultSaveFolder();

            try
            {
                return Path.GetFullPath(Path.Combine(saveFolder, StorageDirectoryName));
            }
            catch (Exception exception) when (IsPathException(exception))
            {
                throw new StorageException("storage_root_invalid", "Storage root path is invalid.", exception);
            }
        }

        // Reads Barotrauma.SaveUtil.DefaultSaveFolder through reflection.
        // SaveUtil is not referenced directly because this script is loaded by
        // LuaCs as loose C# source, and reflection keeps the dependency simple.
        private static string GetDefaultSaveFolder()
        {
            Type saveUtilType = typeof(GameSettings).Assembly.GetType("Barotrauma.SaveUtil");
            if (saveUtilType == null)
            {
                throw new StorageException("save_folder_unavailable", "Barotrauma.SaveUtil type was not found.");
            }

            FieldInfo defaultSaveFolderField = saveUtilType.GetField(
                "DefaultSaveFolder",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
            if (defaultSaveFolderField == null)
            {
                throw new StorageException(
                    "save_folder_unavailable",
                    "Barotrauma.SaveUtil.DefaultSaveFolder field was not found.");
            }

            string saveFolder = defaultSaveFolderField.GetValue(null) as string ?? string.Empty;
            if (string.IsNullOrWhiteSpace(saveFolder))
            {
                throw new StorageException("save_folder_unavailable", "Barotrauma.SaveUtil.DefaultSaveFolder is empty.");
            }

            return saveFolder;
        }

        // Converts Windows backslashes to forward slashes for values returned to Lua.
        // This is only used for display/API-facing strings, not for File.* calls.
        private static string NormalizePath(string path)
        {
            return path.Replace('\\', '/');
        }

        // Groups exceptions that can happen while touching files or directories.
        // These are wrapped into StorageException with a stable Code for Lua.
        private static bool IsFileAccessException(Exception exception)
        {
            return IsPathException(exception)
                || exception is IOException
                || exception is UnauthorizedAccessException
                || exception is SecurityException;
        }

        // Groups exceptions that mean a path string could not be used by .NET.
        // Keeping this separate lets ResolvePath report "invalid_path" while
        // read/write/delete can report operation-specific failures.
        private static bool IsPathException(Exception exception)
        {
            return exception is ArgumentException
                || exception is NotSupportedException
                || exception is PathTooLongException;
        }
    }
}
