---
name: luacs-barotrauma
description: Use for Barotrauma Lua modding through LuaCsForBarotrauma, including lua/Autorun scripts, Hook usage, client/server runtime logic, networking messages, timers, console commands, C# API access from Lua, and Lua code that depends on Barotrauma items, characters, afflictions, or XML identifiers.
---

# LuaCs Barotrauma

## Core Rule

Treat LuaCsForBarotrauma documentation, local Lua examples, and the project's existing scripts as the source of truth. Do not rely on memory for hook names, callback signatures, networking APIs, exposed C# members, or client/server behavior.

## Documentation Routes

Use `references/luacs-doc-routes.md` to choose the relevant official LuaCs docs before editing Lua runtime code. Read only the route needed for the current task.

When internet access is unavailable, search local cached docs, installed LuaCs workshop files, and existing project Lua scripts.

## Workflow

1. Identify the LuaCs concept involved: autorun loading, hook, item interaction, character or health logic, affliction logic, timer, console command, networking, client UI, server authority, or C# API access.
2. Open the matching route from `references/luacs-doc-routes.md`.
3. Inspect nearby project Lua files and, when useful, LuaCs example scripts for the same pattern.
4. Confirm whether the code belongs on server, client, or shared side before editing.
5. Edit Lua in the style already used by the project.
6. If Lua references XML identifiers, item identifiers, afflictions, or content package paths, also use the `barotrauma-modding` skill to verify the XML side.
7. Validate syntax where possible and report which docs or examples were used.

## Loading Notes

- Verify the mod's loading layout before adding files. Common LuaCs mods use `lua/Autorun`, but follow the current project's structure and confirm new files are reachable by the loader/package.
- Prefer the project's existing loading pattern before introducing `require`, `dofile`, or custom path-based loading.
- Before using `require` or `dofile`, check LuaCs docs and local examples for path resolution, caching, and execution behavior.
- Do not assume standard desktop Lua package paths behave the same inside Barotrauma/LuaCs.
- Keep client-only, server-only, and shared files separated according to the mod's current convention.

## LuaCs Checks

- Verify hook names and callback parameters before adding or changing `Hook.Add` logic.
- Keep hook identifiers stable and unique enough to avoid collisions.
- Do not place authoritative gameplay state changes only on the client.
- Use LuaCs networking docs for any client/server message, serialization, or sync behavior.
- Avoid expensive per-frame scans unless the task requires them; prefer event hooks, timers, filtering, or cached lookup patterns used by the project.
- Be careful with Barotrauma C# collections, nullable values, and object lifetime; check that entities and characters still exist before mutating them.
- Preserve existing public identifiers and network message names unless renaming is requested.
