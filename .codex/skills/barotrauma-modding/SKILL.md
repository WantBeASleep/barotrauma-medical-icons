---
name: barotrauma-modding
description: Use for Barotrauma modding tasks involving XML content packages, item or affliction definitions, StatusEffects, conditionals, overrides, sprites/icons referenced from XML, filelist.xml, Steam Workshop packaging, or validation against official Barotrauma modding documentation and local vanilla examples.
---

# Barotrauma Modding

## Core Rule

Treat official Barotrauma docs and local game/mod XML as the source of truth. Do not rely on memory for XML attribute names, content type properties, StatusEffect types/targets, package structure, `%ModDir%` paths, or override behavior.

## Documentation Routes

Use `references/baromoddoc-routes.md` to choose the relevant official BaroModDoc page before editing XML. Read only the route needed for the current task.

When internet access is unavailable, search for a local cached copy or inspect vanilla XML examples from the installed Barotrauma files and existing project XML.

## Workflow

1. Identify the Barotrauma concept involved: content package, item, affliction, StatusEffect, conditional, attack, explosion, related item, sprite/icon atlas, localization text, or Workshop packaging.
2. Open the matching BaroModDoc route from `references/baromoddoc-routes.md`.
3. Inspect nearby project XML and, when useful, vanilla XML examples for the same content type or component.
4. Edit XML in the style already used by the project.
5. Validate XML well-formedness and check that referenced files exist.
6. If runtime-facing outputs are affected, follow the project `AGENTS.md` build workflow.
7. Report which docs or examples were used.

## XML Checks

- Keep one root element per XML file.
- Keep attributes unique on each element.
- Use `%ModDir%` for mod-local file references.
- Preserve existing identifiers unless the task explicitly requires renaming.
- Keep generated/runtime files in the mod-facing locations defined by project `AGENTS.md`.
- Keep development-only references, sources, and scratch assets under `internal`.

## StatusEffect Checks

- Verify `type` is valid for the entity or component where the StatusEffect is declared.
- Verify `target` matches the intended entity: item, character, contained item, nearby entity, limb, hull, or linked entity.
- Use `setvalue` only when replacing a value instead of incrementing/decrementing it.
- Use `disabledeltatime` only for intentional one-shot or per-trigger effects.
- Prefer `interval` for repeated effects when BaroModDoc recommends it for performance.
- Confirm child elements such as `affliction`, `requireditem`, `explosion`, or `fire` are valid for the intended effect.