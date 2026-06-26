# Runtime Item Body And HoldAngle

Краткая выжимка по LuaCs-подмене Barotrauma item sprite/body/holdangle.

## Модель

- `ItemPrefab` - загруженный чертеж предмета.
- `Item` - живой предмет в мире/раунде.
- XML element (`<Holdable>`, `<Body>`) - исходные данные, которые Barotrauma читает при создании prefab/item.
- Component (`Holdable`) - runtime-объект поведения внутри `Item`.
- `PhysicsBody` - обертка Barotrauma над физическим телом.
- `FarseerBody` - реальное тело физического движка: collision, floor contact, falling, mass, fixtures.

## HoldAngle

Сработало через live component:

```lua
local holdable = live_item.GetComponentString("Holdable")
holdable.HoldAngle = 10
```

Почему:

- `HoldAngle` - обычное property компонента `Holdable`.
- Setter сразу меняет runtime-поле `holdAngle`.
- Компонент использует это значение в update/hold logic.
- Менять `prefab.ConfigElement.<Holdable holdangle>` после загрузки поздно: созданный component сам XML заново не перечитывает.

Итог: для уже созданных предметов `HoldAngle` надо менять на live `Holdable`, не только в XML.

## Body

Не сработало:

- править `prefab.ConfigElement.<Body width/height>` после загрузки;
- менять `Item.RectWidth/RectHeight`;
- менять `PhysicsBody.SetSize(...)`;
- создавать `PhysicsBody` из XML overload.

Почему:

- `<Body>` читается при создании `Item`: `new PhysicsBody(bodyElement, position, scale, ...)`.
- После этого изменение XML не пересоздает physics body.
- `RectWidth/RectHeight` влияют на rect/cache/selection/visibility/save bounds, но dynamic item рисуется через `body.Draw(...)`.
- `PhysicsBody.SetSize(...)` меняет только wrapper-поля `Width/Height/Radius`; он не вызывает `CreateBody(...)` и не пересоздает Farseer fixture.
- XML constructor из LuaCs попадал в неправильный overload: игра получала `width=0 height=0 radius=0`.

Сработало:

```lua
local new_body = PhysicsBody.__new(
    target_size.X,
    target_size.Y,
    0,
    density,
    old_body_type,
    old_collision_categories,
    old_collides_with,
    true
)
```

Почему:

- Числовой constructor однозначнее для LuaCs overload resolution.
- Он вызывает `CreateBody(...)`.
- `CreateBody(...)` создает новый реальный `FarseerBody`.
- После успешного создания новый body присваивается в `live_item.body`, старый удаляется.

## Runtime Replacement Checklist

- Посчитать target size в sim units: `ConvertUnits.ToSimUnits(Vector2(px_width * item.Scale, px_height * item.Scale))`.
- Взять со старого body: position, rotation, velocity, body type, collision categories, collidesWith, density, dir, enabled flags, submarine.
- Создать новый body numeric constructor.
- Перенести состояние.
- `live_item.body = new_body`.
- Обновить `Holdable.originalBody`, если доступно через `LuaUserData.MakeFieldAccessible`.
- Удалить старый body только после успешного присваивания.
- Повторные delayed-проходы пропускать, если размер уже совпадает.

## Риски

- Это client-side runtime physics replacement; серверная физика может отличаться в multiplayer.
- Для предметов с `radius`, capsule/circle или нестандартной формой текущий numeric path делает rectangle.
- Не все XML-параметры переносятся: `friction`, `restitution`, `gravityscale`, `angulardamping`, `lineardamping`.
- `Holdable.originalBody` приватный; если доступ не открылся, attach/detach может вернуть старый body.
- Предметы в руках, контейнерах, attached-state или с нестандартными компонентами требуют отдельной проверки.

## Практический Вывод

- `HoldAngle`: менять live component.
- `Body`: менять XML до создания item или пересоздавать live `PhysicsBody` через numeric constructor.
- Для чисто визуальной задачи иногда безопаснее оставить vanilla body и править sprite canvas/origin/padding.