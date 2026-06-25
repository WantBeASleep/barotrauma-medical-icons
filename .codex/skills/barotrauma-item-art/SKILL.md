---
name: barotrauma-item-art
description: "Generate, refine, and validate Barotrauma-style item artwork. Use when Codex needs to create or edit Barotrauma item inventory icons, sprites, large source images, transparent PNG item art, vanilla-style object artwork, or validate generated Barotrauma item art."
---

# Barotrauma Item Art

## Output Contract

Produce or update this five-file asset set unless the user explicitly asks for a different artifact:

```text
origin.png
icon_source.png
icon.png
sprite_source.png
sprite.png
```

Read the nearest project instructions and use the user-requested target folder to decide where the five files belong.

## References

Use bundled vanilla Barotrauma atlas images under `references` as the default visual source of truth.

## Workflow

1. Read the nearest `AGENTS.md` or equivalent project instruction file for the target folder.
2. Review bundled vanilla atlas references.
3. Preserve or create `origin.png` for the non-vanilla source/reference/prompt image.
4. Create or preserve a large `icon_source.png` in high-resolution before producing `icon.png`.
5. Create or preserve a large `sprite_source.png` in high-resolution before producing `sprite.png`.
6. Validate resullt via QA check list 
7. Report changed files and any visual caveats.

Make visual changes to icons, sprites, and source images by regenerating the visual asset, not by manually editing or patching the bitmap.

## Boundaries

This skill prepares the five-file art set only. It does not decide project atlas packing, XML `sourcerect`, `filelist.xml`, item identifiers, mod build workflows, or Steam Workshop packaging.

## Barotrauma Item Art Style

Use bundled vanilla atlases as the primary style reference.

### Inventory Icons

- Render a clear object silhouette readable at `64x64`.
- Use a transparent background.
- Rotate most inventory items about 45 degrees clockwise unless the object shape or vanilla atlas references clearly require another pose.
- Favor muted, utilitarian Barotrauma colors over glossy app-icon colors.
- Keep edges readable with controlled contrast and dark outlining.
- Use worn, practical object rendering rather than clean toy-like plastic.
- Avoid emoji-like shapes, large UI-symbol simplification, or generic flat icons.
- Avoid text labels unless the physical object plausibly has a label and it remains readable in the vanilla style.

### Sprites

- Treat `sprite.png` as the object seen in the world.
- Match the more physical, side/top object look found in vanilla item sprite atlases.
- Keep scale believable relative to comparable vanilla item sprites.
- Preserve object-specific orientation instead of forcing the inventory icon pose.
- Keep alpha edges clean; avoid halos from non-transparent backgrounds.

## Barotrauma Item Art Sizing

### Inventory Icons

- Final `icon.png` must be exactly `64x64`.
- Target the visible alpha bounds to about `60x60` or smaller.
- Center the object after scaling and rotation.
- Use `icon_source.png` as the large source; do not upscale from `icon.png`.

### Sprites

- Final `sprite.png` has no fixed canvas size.
- Choose size, orientation, and padding by comparing the object's silhouette to bundled vanilla atlas references.
- Tall narrow items usually read well as vertical sprites.
- Flat, wide, pack-like, strip-like, or bag-like objects should remain horizontal.
- Crop to the object with only enough transparent padding for readability and atlas packing.
- Use `sprite_source.png` as the large source; do not upscale from `sprite.png`.

## QA list

- `origin.png` exists when there was a non-vanilla source/reference/prompt image.
- `icon_source.png` exists and is larger than the final icon.
- `icon.png` exists and is exactly `64x64`.
- `icon.png` has a transparent background and visible artwork about `60x60` or smaller.
- `sprite_source.png` exists and is larger than, the final sprite.
- `sprite.png` exists and is not just a copied inventory icon.
- `sprite.png` has transparent background and clean alpha edges.
- The icon and sprite are visually related, but each follows its own Barotrauma use case.
- The output location follows the target project's instructions.