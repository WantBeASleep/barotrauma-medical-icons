using System;
using System.IO;
using System.Reflection;
using System.Security;

using Barotrauma;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace MedicalIcons
{
    public sealed class AtlasComposerException : Exception
    {
        public string Code { get; private set; }

        public AtlasComposerException(string code, string message)
            : base(message)
        {
            Code = code;
        }

        public AtlasComposerException(string code, string message, Exception innerException)
            : base(message, innerException)
        {
            Code = code;
        }
    }

    public sealed class AtlasOverlayPackOperation
    {
        public string OverlayPackAtlasPath { get; set; } = string.Empty;
        public double OverlayOffsetWithinIconX { get; set; }
        public double OverlayOffsetWithinIconY { get; set; }
        public double OverlayScale { get; set; } = 1d;
        public AtlasOverlayApply[] Overlays { get; set; } = Array.Empty<AtlasOverlayApply>();

        public AtlasOverlayPackOperation() { }

        public AtlasOverlayPackOperation(
            string overlayPackAtlasPath,
            double overlayOffsetWithinIconX,
            double overlayOffsetWithinIconY,
            double overlayScale,
            AtlasOverlayApply[] overlays)
        {
            OverlayPackAtlasPath = overlayPackAtlasPath;
            OverlayOffsetWithinIconX = overlayOffsetWithinIconX;
            OverlayOffsetWithinIconY = overlayOffsetWithinIconY;
            OverlayScale = overlayScale;
            Overlays = overlays;
        }
    }

    // One overlay application from an overlaypack atlas to the output atlas.
    // OverlayAtlasSource* selects the rectangle inside the overlaypack atlas.
    // OutputAtlasIcon* selects the top-left corner of the item icon in the output atlas.
    public sealed class AtlasOverlayApply
    {
        public int OverlayAtlasSourceX { get; set; }
        public int OverlayAtlasSourceY { get; set; }
        public int OverlayAtlasSourceWidth { get; set; }
        public int OverlayAtlasSourceHeight { get; set; }
        public int OutputAtlasIconX { get; set; }
        public int OutputAtlasIconY { get; set; }

        public AtlasOverlayApply() { }

        public AtlasOverlayApply(
            int overlayAtlasSourceX,
            int overlayAtlasSourceY,
            int overlayAtlasSourceWidth,
            int overlayAtlasSourceHeight,
            int outputAtlasIconX,
            int outputAtlasIconY)
        {
            OverlayAtlasSourceX = overlayAtlasSourceX;
            OverlayAtlasSourceY = overlayAtlasSourceY;
            OverlayAtlasSourceWidth = overlayAtlasSourceWidth;
            OverlayAtlasSourceHeight = overlayAtlasSourceHeight;
            OutputAtlasIconX = outputAtlasIconX;
            OutputAtlasIconY = outputAtlasIconY;
        }
    }

    public static class AtlasComposer
    {
        private const int IconSize = 64;

        // Loads one input atlas PNG, applies rectangles from overlaypack atlas PNGs,
        // and saves the result into Storage. The output path is a Storage path,
        // for example "medical-icons/cache/icons.png".
        public static int Compose(
            string inputAtlasPath,
            string outputStoragePath,
            AtlasOverlayPackOperation[] operations)
        {
            try
            {
                return ComposeInner(inputAtlasPath, outputStoragePath, operations);
            }
            catch (AtlasComposerException)
            {
                throw;
            }
            catch (StorageException)
            {
                throw;
            }
            catch (Exception exception)
            {
                throw new AtlasComposerException("compose_failed", "Could not compose atlas overlays.", exception);
            }
        }

        private static int ComposeInner(
            string inputAtlasPath,
            string outputStoragePath,
            AtlasOverlayPackOperation[] operations)
        {
            if (operations == null)
            {
                throw new AtlasComposerException("null_operations", "Atlas overlay operations must not be null.");
            }

            string resolvedInputAtlasPath = ResolveInputFilePath(inputAtlasPath, "input atlas");

            Texture2D atlasTexture = null;
            try
            {
                atlasTexture = LoadTexture(resolvedInputAtlasPath, "input atlas");
                Color[] atlasPixels = new Color[atlasTexture.Width * atlasTexture.Height];
                atlasTexture.GetData(atlasPixels);

                int appliedCount = 0;
                foreach (AtlasOverlayPackOperation operation in operations)
                {
                    appliedCount += ApplyOperation(atlasPixels, atlasTexture.Width, atlasTexture.Height, operation);
                }

                SaveAtlas(outputStoragePath, atlasPixels, atlasTexture.Width, atlasTexture.Height);
                return appliedCount;
            }
            finally
            {
                if (atlasTexture != null)
                {
                    atlasTexture.Dispose();
                }
            }
        }

        // Loads one overlaypack atlas texture and applies every requested overlay
        // rectangle from that atlas. Loading once per operation keeps the Lua
        // contract simple while avoiding repeated reads of the same overlaypack.
        private static int ApplyOperation(
            Color[] atlasPixels,
            int atlasWidth,
            int atlasHeight,
            AtlasOverlayPackOperation operation)
        {
            if (operation == null)
            {
                throw new AtlasComposerException("null_operation", "Atlas overlay operation must not be null.");
            }

            if (operation.Overlays == null)
            {
                throw new AtlasComposerException("null_overlays", "Atlas overlay list must not be null.");
            }

            if (double.IsNaN(operation.OverlayScale) || double.IsInfinity(operation.OverlayScale))
            {
                throw new AtlasComposerException("invalid_overlay_scale", "Atlas overlay scale must be a finite number.");
            }

            if (operation.OverlayScale <= 0d)
            {
                return 0;
            }

            string overlayAtlasPath = ResolveInputFilePath(operation.OverlayPackAtlasPath, "overlaypack atlas");
            Texture2D overlayAtlasTexture = null;

            try
            {
                overlayAtlasTexture = LoadTexture(overlayAtlasPath, "overlaypack atlas");
                Color[] overlayAtlasPixels = new Color[overlayAtlasTexture.Width * overlayAtlasTexture.Height];
                overlayAtlasTexture.GetData(overlayAtlasPixels);

                int appliedCount = 0;
                foreach (AtlasOverlayApply overlay in operation.Overlays)
                {
                    ApplyOverlay(
                        atlasPixels,
                        atlasWidth,
                        atlasHeight,
                        overlayAtlasPixels,
                        overlayAtlasTexture.Width,
                        overlayAtlasTexture.Height,
                        operation,
                        overlay);
                    appliedCount++;
                }

                return appliedCount;
            }
            finally
            {
                if (overlayAtlasTexture != null)
                {
                    overlayAtlasTexture.Dispose();
                }
            }
        }

        // Reads a PNG file into a MonoGame Texture2D through Barotrauma's graphics device.
        private static Texture2D LoadTexture(string path, string label)
        {
            try
            {
                using (FileStream stream = File.OpenRead(path))
                {
                    return Texture2D.FromStream(GetGraphicsDevice(), stream);
                }
            }
            catch (AtlasComposerException)
            {
                throw;
            }
            catch (Exception exception) when (IsFileAccessException(exception))
            {
                throw new AtlasComposerException("texture_read_failed", "Could not read " + label + " texture.", exception);
            }
            catch (Exception exception)
            {
                throw new AtlasComposerException("texture_load_failed", "Could not load " + label + " texture.", exception);
            }
        }

        // Saves the final pixel buffer as a PNG through Storage, so composer does
        // not need to know how storage paths map to real filesystem paths.
        private static void SaveAtlas(string storagePath, Color[] pixels, int width, int height)
        {
            try
            {
                using (Texture2D outputTexture = new Texture2D(GetGraphicsDevice(), width, height))
                {
                    outputTexture.SetData(pixels);
                    Storage.SavePng(storagePath, outputTexture);
                }
            }
            catch (AtlasComposerException)
            {
                throw;
            }
            catch (StorageException)
            {
                throw;
            }
            catch (Exception exception) when (IsFileAccessException(exception))
            {
                throw new AtlasComposerException("atlas_write_failed", "Could not write composed atlas.", exception);
            }
            catch (Exception exception)
            {
                throw new AtlasComposerException("atlas_write_failed", "Could not write composed atlas.", exception);
            }
        }

        // Gets Barotrauma's active GraphicsDevice through reflection. The composer
        // needs it because Texture2D loading/saving is part of MonoGame.
        private static GraphicsDevice GetGraphicsDevice()
        {
            Type gameMainType = typeof(GameSettings).Assembly.GetType("Barotrauma.GameMain");
            if (gameMainType == null)
            {
                throw new AtlasComposerException("graphics_device_unavailable", "Barotrauma.GameMain type was not found.");
            }

            PropertyInfo instanceProperty = gameMainType.GetProperty(
                "Instance",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
            if (instanceProperty == null)
            {
                throw new AtlasComposerException(
                    "graphics_device_unavailable",
                    "Barotrauma.GameMain.Instance property was not found.");
            }

            object gameMainInstance = instanceProperty.GetValue(null);
            if (gameMainInstance == null)
            {
                throw new AtlasComposerException("graphics_device_unavailable", "Barotrauma.GameMain.Instance is null.");
            }

            PropertyInfo graphicsDeviceProperty = gameMainType.GetProperty(
                "GraphicsDevice",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            if (graphicsDeviceProperty == null)
            {
                throw new AtlasComposerException(
                    "graphics_device_unavailable",
                    "Barotrauma.GameMain.GraphicsDevice property was not found.");
            }

            GraphicsDevice graphicsDevice = graphicsDeviceProperty.GetValue(gameMainInstance) as GraphicsDevice;
            if (graphicsDevice == null)
            {
                throw new AtlasComposerException("graphics_device_unavailable", "Barotrauma.GameMain.GraphicsDevice is null.");
            }

            return graphicsDevice;
        }

        // Alpha-composites one source rectangle from an overlaypack atlas onto
        // the output atlas pixel buffer.
        private static void ApplyOverlay(
            Color[] atlasPixels,
            int atlasWidth,
            int atlasHeight,
            Color[] overlayAtlasPixels,
            int overlayAtlasWidth,
            int overlayAtlasHeight,
            AtlasOverlayPackOperation operation,
            AtlasOverlayApply overlay)
        {
            if (overlay == null)
            {
                throw new AtlasComposerException("null_overlay", "Atlas overlay must not be null.");
            }

            if (overlay.OverlayAtlasSourceWidth <= 0 || overlay.OverlayAtlasSourceHeight <= 0)
            {
                throw new AtlasComposerException("invalid_overlay_rect", "Atlas overlay source width and height must be positive.");
            }

            if (
                overlay.OverlayAtlasSourceX < 0
                || overlay.OverlayAtlasSourceY < 0
                || overlay.OverlayAtlasSourceX + overlay.OverlayAtlasSourceWidth > overlayAtlasWidth
                || overlay.OverlayAtlasSourceY + overlay.OverlayAtlasSourceHeight > overlayAtlasHeight)
            {
                throw new AtlasComposerException(
                    "overlay_source_out_of_bounds",
                    string.Format(
                        "Overlay source rectangle is outside overlay atlas bounds: sourceX={0}, sourceY={1}, width={2}, height={3}, overlayAtlasWidth={4}, overlayAtlasHeight={5}.",
                        overlay.OverlayAtlasSourceX,
                        overlay.OverlayAtlasSourceY,
                        overlay.OverlayAtlasSourceWidth,
                        overlay.OverlayAtlasSourceHeight,
                        overlayAtlasWidth,
                        overlayAtlasHeight));
            }

            OverlayPlacement placement = CreateOverlayPlacement(overlay, operation);

            if (
                placement.OutputAtlasTargetX < 0
                || placement.OutputAtlasTargetY < 0
                || placement.OutputAtlasTargetX + placement.OutputAtlasTargetWidth > atlasWidth
                || placement.OutputAtlasTargetY + placement.OutputAtlasTargetHeight > atlasHeight)
            {
                throw new AtlasComposerException(
                    "overlay_out_of_bounds",
                    string.Format(
                        "Overlay target rectangle is outside atlas bounds: x={0}, y={1}, width={2}, height={3}, atlasWidth={4}, atlasHeight={5}.",
                        placement.OutputAtlasTargetX,
                        placement.OutputAtlasTargetY,
                        placement.OutputAtlasTargetWidth,
                        placement.OutputAtlasTargetHeight,
                        atlasWidth,
                        atlasHeight));
            }

            for (int y = 0; y < placement.OutputAtlasTargetHeight; y += 1)
            {
                int sourceOffsetY = Math.Min(
                    placement.OverlayAtlasVisibleSourceHeight - 1,
                    (int)Math.Floor((double)y
                        * placement.OverlayAtlasVisibleSourceHeight
                        / placement.OutputAtlasTargetHeight));

                for (int x = 0; x < placement.OutputAtlasTargetWidth; x += 1)
                {
                    int sourceOffsetX = Math.Min(
                        placement.OverlayAtlasVisibleSourceWidth - 1,
                        (int)Math.Floor((double)x
                            * placement.OverlayAtlasVisibleSourceWidth
                            / placement.OutputAtlasTargetWidth));

                    int overlayAtlasIndex = (overlay.OverlayAtlasSourceY + sourceOffsetY) * overlayAtlasWidth
                        + overlay.OverlayAtlasSourceX
                        + sourceOffsetX;
                    Color source = overlayAtlasPixels[overlayAtlasIndex];
                    if (source.A == 0)
                    {
                        continue;
                    }

                    int atlasIndex = (placement.OutputAtlasTargetY + y) * atlasWidth + placement.OutputAtlasTargetX + x;
                    atlasPixels[atlasIndex] = AlphaComposite(source, atlasPixels[atlasIndex]);
                }
            }
        }

        // Mirrors Lua preview_renderer.lua overlay geometry: scale, crop from top-left
        // when larger than an icon, then clamp final in-icon position.
        private static OverlayPlacement CreateOverlayPlacement(AtlasOverlayApply overlay, AtlasOverlayPackOperation operation)
        {
            int scaledWidth = Math.Max(1, Round(overlay.OverlayAtlasSourceWidth * operation.OverlayScale));
            int scaledHeight = Math.Max(1, Round(overlay.OverlayAtlasSourceHeight * operation.OverlayScale));
            int targetWidth = Math.Min(IconSize, scaledWidth);
            int targetHeight = Math.Min(IconSize, scaledHeight);

            int sourceWidth = overlay.OverlayAtlasSourceWidth;
            int sourceHeight = overlay.OverlayAtlasSourceHeight;
            if (targetWidth < scaledWidth)
            {
                sourceWidth = Math.Max(
                    1,
                    Math.Min(overlay.OverlayAtlasSourceWidth, (int)Math.Floor(targetWidth / operation.OverlayScale)));
            }
            if (targetHeight < scaledHeight)
            {
                sourceHeight = Math.Max(
                    1,
                    Math.Min(overlay.OverlayAtlasSourceHeight, (int)Math.Floor(targetHeight / operation.OverlayScale)));
            }

            int overlayTargetWithinIconX = Round(Clamp(operation.OverlayOffsetWithinIconX, 0d, IconSize - targetWidth));
            int overlayTargetWithinIconY = Round(Clamp(operation.OverlayOffsetWithinIconY, 0d, IconSize - targetHeight));

            return new OverlayPlacement(
                sourceWidth,
                sourceHeight,
                overlay.OutputAtlasIconX + overlayTargetWithinIconX,
                overlay.OutputAtlasIconY + overlayTargetWithinIconY,
                targetWidth,
                targetHeight);
        }

        private sealed class OverlayPlacement
        {
            public int OverlayAtlasVisibleSourceWidth { get; private set; }
            public int OverlayAtlasVisibleSourceHeight { get; private set; }
            public int OutputAtlasTargetX { get; private set; }
            public int OutputAtlasTargetY { get; private set; }
            public int OutputAtlasTargetWidth { get; private set; }
            public int OutputAtlasTargetHeight { get; private set; }

            public OverlayPlacement(
                int overlayAtlasVisibleSourceWidth,
                int overlayAtlasVisibleSourceHeight,
                int outputAtlasTargetX,
                int outputAtlasTargetY,
                int outputAtlasTargetWidth,
                int outputAtlasTargetHeight)
            {
                OverlayAtlasVisibleSourceWidth = overlayAtlasVisibleSourceWidth;
                OverlayAtlasVisibleSourceHeight = overlayAtlasVisibleSourceHeight;
                OutputAtlasTargetX = outputAtlasTargetX;
                OutputAtlasTargetY = outputAtlasTargetY;
                OutputAtlasTargetWidth = outputAtlasTargetWidth;
                OutputAtlasTargetHeight = outputAtlasTargetHeight;
            }
        }

        // Standard source-over alpha composition for two RGBA pixels.
        private static Color AlphaComposite(Color source, Color destination)
        {
            float sourceAlpha = source.A / 255f;
            float destinationAlpha = destination.A / 255f;
            float outputAlpha = sourceAlpha + destinationAlpha * (1f - sourceAlpha);
            if (outputAlpha <= 0f)
            {
                return Color.Transparent;
            }

            byte r = ToByte(((source.R / 255f) * sourceAlpha + (destination.R / 255f) * destinationAlpha * (1f - sourceAlpha)) / outputAlpha);
            byte g = ToByte(((source.G / 255f) * sourceAlpha + (destination.G / 255f) * destinationAlpha * (1f - sourceAlpha)) / outputAlpha);
            byte b = ToByte(((source.B / 255f) * sourceAlpha + (destination.B / 255f) * destinationAlpha * (1f - sourceAlpha)) / outputAlpha);
            byte a = ToByte(outputAlpha);

            return new Color(r, g, b, a);
        }

        private static byte ToByte(float value)
        {
            return (byte)Math.Max(0, Math.Min(255, (int)Math.Round(value * 255f)));
        }

        private static double Clamp(double value, double minValue, double maxValue)
        {
            if (value < minValue)
            {
                return minValue;
            }
            if (value > maxValue)
            {
                return maxValue;
            }
            return value;
        }

        private static int Round(double value)
        {
            return (int)Math.Floor(value + 0.5d);
        }

        // Input atlas and overlaypack atlas paths must be absolute real files.
        // Output storage paths are handled separately by Storage.SavePng.
        private static string ResolveInputFilePath(string path, string label)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                throw new AtlasComposerException("empty_input_path", label + " path must not be empty.");
            }

            if (!Path.IsPathRooted(path))
            {
                throw new AtlasComposerException("input_path_must_be_absolute", label + " path must be absolute.");
            }

            string fullPath;
            try
            {
                fullPath = Path.GetFullPath(path);
            }
            catch (Exception exception) when (IsPathException(exception))
            {
                throw new AtlasComposerException("invalid_input_path", label + " path is invalid.", exception);
            }

            if (!File.Exists(fullPath))
            {
                throw new AtlasComposerException("input_file_not_found", label + " file was not found.");
            }

            return fullPath;
        }

        private static bool IsFileAccessException(Exception exception)
        {
            return IsPathException(exception)
                || exception is IOException
                || exception is UnauthorizedAccessException
                || exception is SecurityException;
        }

        private static bool IsPathException(Exception exception)
        {
            return exception is ArgumentException
                || exception is NotSupportedException
                || exception is PathTooLongException;
        }
    }
}
