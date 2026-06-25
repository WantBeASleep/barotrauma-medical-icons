# LuaCsForBarotrauma Documentation Routes

Official repository:
https://github.com/evilfactory/LuaCsForBarotrauma

Official Lua docs root:
https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/index.html

Use this file as a routing index. Open the relevant page before changing LuaCs runtime code.

## Manual

- Getting started:
  https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/getting-started/
- How to use hooks:
  https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/how-to-use-hooks/
- Lua examples:
  https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/lua-examples/
- Networking:
  https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/networking/
- Common questions:
  https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/common-questions/
- Manual installation:
  https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/installing-luacs-for-barotrauma-manually/

## Code API Index

Start from the docs root and search the generated Code section for the class, function, or field being used.

Common routes to check by task:

- Hooks and lifecycle: manual `How to use hooks`, plus any existing project `Hook.Add` usage.
- Networking and sync: manual `Networking`.
- Characters and health: `Character`, `CharacterHealth`, `Affliction`, `AfflictionPrefab`, `Limb`, `Attack`.
- Items and inventories: `Item`, `ItemPrefab`, `ItemComponent`, `Inventory`, `ItemContainer`.
- World/entity access: `Entity`, `MapEntity`, `Submarine`, `Hull`, `Level`.
- Timing and repeated work: `Timer` or LuaCs timer-related APIs listed in the Code index.
- UI/client behavior: GUI-related classes in the Code index and client-side examples.
- Commands/debugging: console command examples in manual pages or local LuaCs examples.

## Local Example Search

When docs are too narrow, search local examples:

- Existing project scripts under `lua`.
- LuaCs workshop or installed mod files, if accessible.
- Other local Barotrauma Lua mods, if the user points to them.
- XML files under `Items/Medical` when Lua depends on identifiers, afflictions, or item definitions.

Prefer examples matching the same side and lifecycle: server autorun, client autorun, shared code, network handler, hook callback, timer, or item interaction.

Use examples to confirm idioms and loading structure, but use official docs for API names, arguments, and behavior.
