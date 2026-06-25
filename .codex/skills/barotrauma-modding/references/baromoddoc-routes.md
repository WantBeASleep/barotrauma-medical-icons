# BaroModDoc Routes

Official documentation root:
https://regalis11.github.io/BaroModDoc/

Use this file as a routing index. Open the relevant page before changing Barotrauma XML or packaging files.

## General XML

- XML basics and Barotrauma-specific XML rules:
  https://regalis11.github.io/BaroModDoc/Intro/XML.html
- Content packages:
  https://regalis11.github.io/BaroModDoc/Intro/ContentPackages.html
- Content types index:
  https://regalis11.github.io/BaroModDoc/Intro/ContentTypes.html
- Overrides:
  https://regalis11.github.io/BaroModDoc/Intro/Overrides.html
- Performance:
  https://regalis11.github.io/BaroModDoc/Intro/Performance.html

## Common XML Building Blocks

- StatusEffect:
  https://regalis11.github.io/BaroModDoc/Misc/StatusEffect.html
- Conditionals:
  https://regalis11.github.io/BaroModDoc/Misc/Conditionals.html
- Stat types:
  https://regalis11.github.io/BaroModDoc/Misc/StatTypes.html
- RelatedItem:
  https://regalis11.github.io/BaroModDoc/Misc/RelatedItem.html
- Attack:
  https://regalis11.github.io/BaroModDoc/Misc/Attack.html
- Explosion:
  https://regalis11.github.io/BaroModDoc/Misc/Explosion.html
- Scripted events:
  https://regalis11.github.io/BaroModDoc/Misc/ScriptedEvent.html

## Content Types

Start from the content types index, then open the specific generated page for the content being edited:

- Item: use for `Item` definitions, components, sprites, inventory icons, tags, conditions, variants, and item overrides.
- Afflictions: use for affliction definitions, effects, thresholds, status icons, and treatment interactions.
- Text: use for localization and translated display strings.
- Sounds, Particles, Jobs, Talents, Missions, Orders, UIStyle, and other generated content types: use only when the task touches that content.

## Local Example Search

When docs explain a property but not enough surrounding context, search local XML examples:

- Existing project XML under `Items/Medical`.
- Development scripts or generated XML under `internal`.
- Vanilla Barotrauma XML under the game install, if accessible.

Prefer examples matching the same content type and component. Use examples to confirm structure and style, but use BaroModDoc for property meaning and constraints.
