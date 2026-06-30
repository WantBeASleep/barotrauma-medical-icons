# Почему

Я рот ебал стандартных медицинских шприцов, невъебенное решение сделать 30 одинаковых иконок, что бы в критической ситуации с умирающем тиммейтом на руках судорожно перебирать глазами эту размазню.

# О моде

~~Мод SERVER-SIDE, требуется подписка хоста.~~ Мод **CLIENT SIDE ONLY**, нахуй xml \<override\> **Lua powered**.

Мод меняет все ванильные медицинские шприцы на собственные иконки. В игре 5 классов медицины: Medicine, Basic Chemicals, Toxins, Antidotes, Stimulants. Классы в моде соответствуют оф. вики: [Medical Items](https://barotraumagame.com/wiki/Medical_Items)

У каждого класса медицины своя икона, которая уже внутри класса различается по цветам/значкам статусов.

# Совместимость

Мод работает на базе Lua, подменяя спрайты существующих мед префабов, не делая полный XML override самих префабов. Должен быть совместим с любыми модами. 

Особенности:
- Перезапишет мед иконки других XML модов **ВНЕ ЗАВИСИМОСТИ ОТ ПРИОРИТЕТА**
- Иконки могут быть переопределены другим Lua модом, если у него выше приоритет(выше в списке модов barotrauma)

# Редактирование мода

В steam workshop только необходимые файлы для работы мода. Ставьте себе локально(в `Barotrauma/LocalMods`) полную версию с [GitHub](https://github.com/WantBeASleep/MedicalIcons). Мод описан в Agents.md

# Как создавался

Я вообще не умею рисовать, да и с чувством вкуса было так себе. Весь мод написан и нарисован нейронкой Codex 5.5 (да, я генерил картинки на Кодексе).

Благодарность создателю мода https://steamcommunity.com/sharedfiles/filedetails/?id=3539579595 за вдохновение и творческий ориентир.

Буду рад любому фидбеку!

--------------------------------------------------------



--------------------------------------------------------

# English Version

# Why

Fuck the standard medical syringes. What a fucking brilliant decision to make 30 identical icons, so that in a critical situation, with a dying teammate in your hands, you have to frantically scan this smear with your eyes.

# About the Mod

**This is a SERVER-SIDE mod; the host must be subscribed.**

The mod replaces all vanilla medical syringes with custom icons. The game has 5 medical classes: Medicine, Basic Chemicals, Toxins, Antidotes, Stimulants. The classes in the mod match the official wiki: [Medical Items](https://barotraumagame.com/wiki/Medical_Items)

Each medical class has its own icon, and items inside the class are already distinguished by colors and status symbols.

# Compatibility

- The texture pack works correctly with all mods that do not change the vanilla items listed above.
- If you use mods that change vanilla content, move this texture pack to the end of the list. In that case, its texture priority will be lower, so some textures may not appear.
- You can manually rewrite other mods so they reference textures from here. More on that point below.

# Editing the Mod

You can copy this mod into your local mods and fuck with it there however you want. The mod structure is described in the `AGENTS.md` files.

Other mods can reference textures from this mod. In local versions of those mods, replace the texture path in `.xml` files from `Content` to `QoL - Medical icons`.

# How It Was Made

I cannot fucking draw at all, and my sense of taste was pretty damn questionable too. The whole mod was written and drawn by the Codex 5.5 neural network (yes, I generated the images in Codex). The mod is available on [GitHub](https://github.com/WantBeASleep/MedicalIcons). Ideas and contributions are welcome.

Thanks to the creator of https://steamcommunity.com/sharedfiles/filedetails/?id=3539579595 for the inspiration and creative direction.

--------------------------------------------------------

# Item table

| Identifier | Icon | Sprite |
|---|---|---|
| `adrenaline` | ![adrenaline icon](source/texturepacks/default/ampoule/items/adrenaline/icon.png) | ![adrenaline sprite](source/texturepacks/default/ampoule/items/adrenaline/sprite.png) |
| `antibiotics` | ![antibiotics icon](source/texturepacks/default/ampoule/items/antibiotics/icon.png) | ![antibiotics sprite](source/texturepacks/default/ampoule/items/antibiotics/sprite.png) |
| `opium` | ![opium icon](source/texturepacks/default/ampoule/items/opium/icon.png) | ![opium sprite](source/texturepacks/default/ampoule/items/opium/sprite.png) |
| `stabilozine` | ![stabilozine icon](source/texturepacks/default/ampoule/items/stabilozine/icon.png) | ![stabilozine sprite](source/texturepacks/default/ampoule/items/stabilozine/sprite.png) |
| `chloralhydrate` | ![chloralhydrate icon](source/texturepacks/default/dart_syringe/items/chloralhydrate/icon.png) | ![chloralhydrate sprite](source/texturepacks/default/dart_syringe/items/chloralhydrate/sprite.png) |
| `cyanide` | ![cyanide icon](source/texturepacks/default/dart_syringe/items/cyanide/icon.png) | ![cyanide sprite](source/texturepacks/default/dart_syringe/items/cyanide/sprite.png) |
| `deliriumine` | ![deliriumine icon](source/texturepacks/default/dart_syringe/items/deliriumine/icon.png) | ![deliriumine sprite](source/texturepacks/default/dart_syringe/items/deliriumine/sprite.png) |
| `europabrew` | ![europabrew icon](source/texturepacks/default/dart_syringe/items/europabrew/icon.png) | ![europabrew sprite](source/texturepacks/default/dart_syringe/items/europabrew/sprite.png) |
| `huskeggs` | ![huskeggs icon](source/texturepacks/default/dart_syringe/items/huskeggs/icon.png) | ![huskeggs sprite](source/texturepacks/default/dart_syringe/items/huskeggs/sprite.png) |
| `morbusine` | ![morbusine icon](source/texturepacks/default/dart_syringe/items/morbusine/icon.png) | ![morbusine sprite](source/texturepacks/default/dart_syringe/items/morbusine/sprite.png) |
| `paralyzant` | ![paralyzant icon](source/texturepacks/default/dart_syringe/items/paralyzant/icon.png) | ![paralyzant sprite](source/texturepacks/default/dart_syringe/items/paralyzant/sprite.png) |
| `radiotoxin` | ![radiotoxin icon](source/texturepacks/default/dart_syringe/items/radiotoxin/icon.png) | ![radiotoxin sprite](source/texturepacks/default/dart_syringe/items/radiotoxin/sprite.png) |
| `raptorbaneextract` | ![raptorbaneextract icon](source/texturepacks/default/dart_syringe/items/raptorbaneextract/icon.png) | ![raptorbaneextract sprite](source/texturepacks/default/dart_syringe/items/raptorbaneextract/sprite.png) |
| `sufforin` | ![sufforin icon](source/texturepacks/default/dart_syringe/items/sufforin/icon.png) | ![sufforin sprite](source/texturepacks/default/dart_syringe/items/sufforin/sprite.png) |
| `sulphuricacidsyringe` | ![sulphuricacidsyringe icon](source/texturepacks/default/dart_syringe/items/sulphuricacidsyringe/icon.png) | ![sulphuricacidsyringe sprite](source/texturepacks/default/dart_syringe/items/sulphuricacidsyringe/sprite.png) |
| `antidama1` | ![antidama1 icon](source/texturepacks/default/insulin_syringe/items/antidama1/icon.png) | ![antidama1 sprite](source/texturepacks/default/insulin_syringe/items/antidama1/sprite.png) |
| `antidama2` | ![antidama2 icon](source/texturepacks/default/insulin_syringe/items/antidama2/icon.png) | ![antidama2 sprite](source/texturepacks/default/insulin_syringe/items/antidama2/sprite.png) |
| `deusizine` | ![deusizine icon](source/texturepacks/default/insulin_syringe/items/deusizine/icon.png) | ![deusizine sprite](source/texturepacks/default/insulin_syringe/items/deusizine/sprite.png) |
| `liquidoxygenite` | ![liquidoxygenite icon](source/texturepacks/default/insulin_syringe/items/liquidoxygenite/icon.png) | ![liquidoxygenite sprite](source/texturepacks/default/insulin_syringe/items/liquidoxygenite/sprite.png) |
| `pomegrenadeextract` | ![pomegrenadeextract icon](source/texturepacks/default/insulin_syringe/items/pomegrenadeextract/icon.png) | ![pomegrenadeextract sprite](source/texturepacks/default/insulin_syringe/items/pomegrenadeextract/sprite.png) |
| `combatstimulantsyringe` | ![combatstimulantsyringe icon](source/texturepacks/default/pocket_injector/items/combatstimulantsyringe/icon.png) | ![combatstimulantsyringe sprite](source/texturepacks/default/pocket_injector/items/combatstimulantsyringe/sprite.png) |
| `hyperzine` | ![hyperzine icon](source/texturepacks/default/pocket_injector/items/hyperzine/icon.png) | ![hyperzine sprite](source/texturepacks/default/pocket_injector/items/hyperzine/sprite.png) |
| `meth` | ![meth icon](source/texturepacks/default/pocket_injector/items/meth/icon.png) | ![meth sprite](source/texturepacks/default/pocket_injector/items/meth/sprite.png) |
| `pressurestabilizer` | ![pressurestabilizer icon](source/texturepacks/default/pocket_injector/items/pressurestabilizer/icon.png) | ![pressurestabilizer sprite](source/texturepacks/default/pocket_injector/items/pressurestabilizer/sprite.png) |
| `steroids` | ![steroids icon](source/texturepacks/default/pocket_injector/items/steroids/icon.png) | ![steroids sprite](source/texturepacks/default/pocket_injector/items/steroids/sprite.png) |
| `antinarc` | ![antinarc icon](source/texturepacks/default/vial/items/antinarc/icon.png) | ![antinarc sprite](source/texturepacks/default/vial/items/antinarc/sprite.png) |
| `antiparalysis` | ![antiparalysis icon](source/texturepacks/default/vial/items/antiparalysis/icon.png) | ![antiparalysis sprite](source/texturepacks/default/vial/items/antiparalysis/sprite.png) |
| `antipsychosis` | ![antipsychosis icon](source/texturepacks/default/vial/items/antipsychosis/icon.png) | ![antipsychosis sprite](source/texturepacks/default/vial/items/antipsychosis/sprite.png) |
| `antirad` | ![antirad icon](source/texturepacks/default/vial/items/antirad/icon.png) | ![antirad sprite](source/texturepacks/default/vial/items/antirad/sprite.png) |
| `calyxanide` | ![calyxanide icon](source/texturepacks/default/vial/items/calyxanide/icon.png) | ![calyxanide sprite](source/texturepacks/default/vial/items/calyxanide/sprite.png) |
| `cyanideantidote` | ![cyanideantidote icon](source/texturepacks/default/vial/items/cyanideantidote/icon.png) | ![cyanideantidote sprite](source/texturepacks/default/vial/items/cyanideantidote/sprite.png) |
| `deliriumineantidote` | ![deliriumineantidote icon](source/texturepacks/default/vial/items/deliriumineantidote/icon.png) | ![deliriumineantidote sprite](source/texturepacks/default/vial/items/deliriumineantidote/sprite.png) |
| `morbusineantidote` | ![morbusineantidote icon](source/texturepacks/default/vial/items/morbusineantidote/icon.png) | ![morbusineantidote sprite](source/texturepacks/default/vial/items/morbusineantidote/sprite.png) |
| `sufforinantidote` | ![sufforinantidote icon](source/texturepacks/default/vial/items/sufforinantidote/icon.png) | ![sufforinantidote sprite](source/texturepacks/default/vial/items/sufforinantidote/sprite.png) |
