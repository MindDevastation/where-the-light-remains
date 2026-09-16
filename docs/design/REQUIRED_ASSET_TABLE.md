# REQUIRED_ASSET_TABLE — обязательные ассеты проекта

Источник: ASSET_MANIFEST v1.0 из PROJECT BIBLE v1.8.

**Всего строк в этой таблице:** 185 asset groups.

Классы:
- **MUST** — обязательный ассет/функция.
- **FALLBACK** — функция обязательна, но high-detail asset допускает упрощенную замену.

Декоративные `DECOR`-ассеты в эту таблицу намеренно не включены.

## GLOBAL / REUSABLE

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| ARCH-001 | MUST | 3D / Architecture | Экстерьер дома-обсерватории + купол | 0,15 | R-HUB | 1 master shell + night/dawn states | Custom modular shell; тот же mesh в прологе и эпилоге |
| ARCH-002 | MUST | 3D / Architecture | Главная входная дверь + арочный портал | 0,15 | R-HUB | 1 set, open/closed | Повторяется как композиционная рифма вход/выход |
| ARCH-003 | MUST | 3D / Architecture | Ротонда Центральной обсерватории | 1,10–15 | R-HUB | 1 modular room | Главный reuse-space финала |
| ARCH-004 | MUST | 3D / Module | Прямая стена 2–4 м | 1–8 | R-ARCHIVE | 2–3 размеров | Основной wall kit |
| ARCH-005 | MUST | 3D / Module | Арочная стена / doorway module | 1–9 | R-ARCHIVE | 2 варианта | Единый shape language |
| ARCH-006 | MUST | 3D / Module | Пол / плиточный модуль | 1–9 | R-ARCHIVE | 2–3 варианта | Можно tint/material-swap покрыльно |
| ARCH-007 | MUST | 3D / Module | Потолочная арка / ребро / vault segment | 1–8 | R-ARCHIVE | 2 варианта | Повторяемая верхняя структура |
| ARCH-008 | MUST | 3D / Module | Арочное окно + стекло | 0,1,7,8,15 | R-ARCHIVE | 1–2 размера | Night/dawn lighting reuse |
| ARCH-009 | MUST | 3D / Module | Колонна / пилястра | 1–8 | R-ARCHIVE | 2 высоты | В том числе cover/decor в памяти |
| ARCH-010 | MUST | 3D / Module | Пьедестал / pedestal family | 1–8,10–11 | R-ARCHIVE | 3 высоты | Для hero props, sigils, optics |
| ARCH-011 | MUST | 3D / Module | Короткая лестница / ступени | 1–9 | R-ARCHIVE | 2 ширины | Без сложного платформинга |
| ARCH-012 | MUST | 3D / Module | Балюстрада / railing | 0,1,9,15 | R-ARCHIVE | 1 straight + corner | Hub/exterior/bridge fallback |
| ARCH-013 | MUST | 3D / Module | Ниша / alcove / reveal recess | 1–8 | R-ARCHIVE | 1–2 варианта | Также под optional secrets |
| ARCH-014 | MUST | 3D / Module | Дверь/ворота крыла | 1–8 | R-ARCHIVE | 5 instances, shared mesh | Различаются светом/эмблемой, не геометрией |
| ARCH-015 | MUST | 3D / Module | Световой канал пола/стены | 1–15 | R-ARCHIVE | Spline/mesh system | Один reusable system с tint/state |
| ARCH-016 | MUST | 3D / Module | Коридорный переход / threshold | 1–9 | R-ARCHIVE | 1 modular set | Seamless transitions |
| ARCH-017 | MUST | 3D / Exterior | Окружающий terrain / distant mountains-water silhouette | 0,9,15 | R-HUB | 1 low-poly backdrop | Night/dawn material states |
| ARCH-018 | MUST | 3D / Exterior | Внешние ступени/дорожка к входу | 0,15 | R-HUB | 1 set | Reuse в эпилоге |
| PROP-001 | MUST | Hero Prop | Центральный механизм Архива / core orrery | 1,10–15 | R-HUB | base + awakened + final states | Самый важный reusable hero asset |
| PROP-002 | MUST | Hero Prop | Кольца/орбиты центрального механизма | 1,10–15 | R-HUB | 3–5 ring pieces | Анимация и финальная сборка |
| PROP-003 | MUST | Gameplay Prop | Стартовая линза + гнездо | 1 | R-ARCHIVE | 1 lens + socket | Линза может стать базой для других optics |
| PROP-004 | MUST | Gameplay Prop | Archive interaction console / универсальная панель | 1–8,10 | R-ARCHIVE | 1 base + skins | Switch/lever/dial variants через child parts |
| PROP-005 | MUST | Gameplay Prop | Универсальный rotary dial / knob | 1–8 | R-ARCHIVE | 1 master | Reuse в optics/resonators/moons |
| PROP-006 | MUST | Gameplay Prop | Универсальный lever/lock/stopper | 1–8 | R-ARCHIVE | 2 shapes | Reuse механик без создания нового lever каждый раз |
| PROP-007 | MUST | Narrative Prop | Фрагмент Архива — базовый носитель/stand | 2,3,5,7,8,10–13 | R-FINAL | 1 base + 10 glyph variants | Один shell, меняется сигил/эмиссия |
| SIG-001–010 | MUST | 2D/3D Sigil | 10 уникальных сигилов: Очаг, Звезда, Росток, Эхо, Колокольчик, Перо, Двойная луна, Блик, Кристалл, Созвездие | 2–14 | R-FINAL | 10 vector/SDF glyphs | Используются в world-space, UI и финальном столе |
| MAT-001 | MUST | Material | Aged Brass master | 0–15 | R-GLOBAL | 1 master + roughness params | Основная механическая семья |
| MAT-002 | MUST | Material | Polished Brass hero | 1–14 | R-GLOBAL | 1 master | Hero props/interactives |
| MAT-003 | MUST | Material | Dark Walnut / warm wood | 1–15 | R-GLOBAL | 1–2 tiling maps | Библиотека/мебель/панели |
| MAT-004 | MUST | Material | Warm Stone | 0–15 | R-GLOBAL | 1 tiling + variation | Архив, exterior, props |
| MAT-005 | MUST | Material | Cool/Dark Stone | 0,4,6,8,9 | R-GLOBAL | 1 tiling | Raid/night variants |
| MAT-006 | MUST | Material | Clear Glass | 1–9 | R-GLOBAL | 1 shader | Окна/линзы/призмы |
| MAT-007 | MUST | Material | Frosted / Memory Glass | 7,8,12–13 | R-GLOBAL | 1 shader | Memory glass + text substrate |
| MAT-008 | MUST | Material | Crystal fake-refraction | 8,10–11 | R-GLOBAL | 1 shader, quality tiers | Без true ray tracing |
| MAT-009 | MUST | Material | Parchment / paper | 1–15 | R-GLOBAL | 1 master + tint | Записки/poem/cards |
| MAT-010 | MUST | Material | Wine / plum textile | 1,5,7 | R-GLOBAL | 1 fabric tiling | Ковры/баннеры/акценты |
| MAT-011 | MUST | Material | Linen / neutral fabric | 1,5,7,9 | R-GLOBAL | 1 fabric tiling | Тихие бытовые детали |
| MAT-012 | MUST | Material | Leaf / ivy atlas | 0–9,15 | R-GLOBAL | 1 atlas | Акцентная растительность |
| MAT-013 | MUST | Material | Flower/petal atlas | 5,7,9 | R-GLOBAL | 1 atlas | DECOR может reuse тот же atlas |
| MAT-014 | MUST | Material | Archive emissive gold | 1–15 | R-GLOBAL | 1 shader | Основная feedback/emissive система |
| MAT-015 | MUST | Material | Resonance cyan/teal emissive | 3 | R-GLOBAL | parameter variant | Не отдельный shader |
| MAT-016 | MUST | Material | Reflection lilac/pink emissive | 7 | R-GLOBAL | parameter variant | Не отдельный shader |
| MAT-017 | MUST | Material | Poison green emissive/liquid | 6 | UNIQUE | 1 shader | Только Egg chase |
| TRIM-001 | MUST | Texture / Trim | Archive brass/wood trim sheet | 1–15 | R-GLOBAL | 1–2 2K trims | Главная экономия texturing |
| TRIM-002 | MUST | Texture / Trim | Stone/ornament trim sheet | 0–15 | R-GLOBAL | 1 2K trim | Арки/пьедесталы/бордюры |
| DECAL-001 | MUST | Decal kit | Scratches, edge wear, dust, subtle soot | 0–15 | R-GLOBAL | 1 atlas | Дозированно, не превращать в ruin |
| VFX-001 | MUST | VFX | Archive light beam / spline beam | 1–15 | R-GLOBAL | 1 system + color/intensity params | Навигация, optics, final |
| VFX-002 | MUST | VFX | Light path motes / shimmer | 0–15 | R-GLOBAL | 1 particle system | Primary reuse effect |
| VFX-003 | MUST | VFX | Correct interaction pulse/chime visual | 1–11 | R-GLOBAL | 1 system | Scale/tint variants |
| VFX-004 | MUST | VFX | Fragment materialize / dissolve | 2,3,5,7,8,10–13 | R-FINAL | 1 system | 10 sigils reuse same effect |
| VFX-005 | MUST | VFX | Memory transition dissolve | 3→4,5→6,8→9,9→10 | R-GLOBAL | 1 shader/VFX rig | Seamless memory transitions |
| VFX-006 | MUST | VFX | Dust motes / soft atmosphere | 0–15 | R-GLOBAL | 1 low-cost system | Quality-scalable |
| VFX-007 | MUST | VFX | Highlight / inspect glow | 1–11 | R-GLOBAL | 1 shader/outline strategy | Не cartoon outline; subtle emissive |
| UI-001 | MUST | UI | Minimal reticle / focus dot | 1–11 | R-GLOBAL | 1 asset | Can fade during cinematics/text |
| UI-002 | MUST | UI | Interaction prompt component [E]/[R] | 1–14 | R-GLOBAL | 1 widget | Dynamic verb string |
| UI-003 | MUST | UI | Hint/world-space text component | 1–11 | R-GLOBAL | 1 widget | System and semantic hints |
| UI-004 | MUST | UI | Fragment presentation card / world-space panel | 2,3,5,7,8 | R-FINAL | 1 layout | Sigil + couplet + feeling |
| UI-005 | MUST | UI | Main/Pause/Settings/Postgame screens | global | R-GLOBAL | 4 screen layouts | Same style system |
| UI-006 | MUST | UI | Collection screen/grid | postgame | R-GLOBAL | 1 screen | Supports secret slots; not required before completion |
| UI-007 | MUST | UI | Text reading / poem layout | 12–14 | R-FINAL | 1 responsive layout | Cyrillic-safe |
| FONT-001 | MUST | Font/License | System UI Cyrillic font family | global | R-GLOBAL | 1 family + fallback | License must allow redistribution; font file not embedded in documentation |
| FONT-002 | MUST | Font/License | Personal/handwritten Cyrillic accent font | 2–15 | R-GLOBAL | 1 family + fallback | Use sparingly; high readability |
| CAM-001 | MUST | Camera Rig | First-person camera rig | 1–14 | R-GLOBAL | 1 rig | FOV/headbob states |
| CAM-002 | MUST | Camera Rig | Cinematic rail/Path3D camera | 0,6,9,15 | R-GLOBAL | 1 reusable controller | Different paths per stage |
| SAVE-ART-001 | MUST | Presentation | World-space save/checkpoint feedback style | global | R-GLOBAL | 1 subtle icon/animation | Optional visual feedback; no noisy popup |

## CHARACTERS / ANIMATION

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| CHAR-001 | MUST | Character / Rig / Animation | Stylized heroine avatar / silhouette rig | 4,9 | R-CHAR | 1 rig + silhouette material | Не нужен facial rig; видимость тела ограниченная |
| CHAR-002 | MUST | Character / Rig / Animation | Stylized author dracthyr-like original avatar | 4,6,9 | R-CHAR | 1 rig | Оригинальная интерпретация, не извлеченный игровой asset |
| CHAR-003 | FALLBACK | Character / Rig / Animation | Background raid participant rig | 4,6 | R-RAID | 1 rig × 3–5 material variants | Можно заменить полупрозрачными echo-силуэтами |
| CHAR-004 | MUST | Character / Rig / Animation | Egg memory boss creature | 6 | UNIQUE | 1 partial/full rig | Достаточно readable head/upper body + roar/wake; full combat rig не нужен |
| CHAR-005 | MUST | Character / Rig / Animation | Snake hazard | 6 | UNIQUE | 1 rig × instances | Один mesh/animation reused for all lunges |
| CHAR-006 | MUST | Character / Rig / Animation | First-person hand/held-object rig | 6; optional 1/9 | R-CHAR | 1 simple rig | Для яйца; fallback — object-only edge-of-screen |
| ANIM-001 | MUST | Character / Rig / Animation | Dracthyr idle/walk/neutral head turn | 4,9 | R-CHAR | 3 clips | Reuse across memories |
| ANIM-002 | MUST | Character / Rig / Animation | Dracthyr stabilize rune interaction | 4 | UNIQUE | 1 clip | Short scripted interaction |
| ANIM-003 | MUST | Character / Rig / Animation | Dracthyr rescue: rise/reach/grab/flight/land | 6 | UNIQUE | 4–5 clips or one sequence | No ragdoll/physics carry |
| ANIM-004 | MUST | Character / Rig / Animation | Heroine/echo simple walk/idle/silhouette | 4,9 | R-CHAR | 2 clips | No face |
| ANIM-005 | MUST | Character / Rig / Animation | Raid participant idle/look-away/turn | 4,6 | R-RAID | 3 clips | State machine simple |
| ANIM-006 | MUST | Character / Rig / Animation | Boss wake/eyes/roar/recoil | 6 | UNIQUE | 2–3 clips | No full combat set |
| ANIM-007 | MUST | Character / Rig / Animation | Snake warning/lunge/return | 6 | UNIQUE | 3 clips | Same clips instanced |
| ANIM-008 | MUST | Character / Rig / Animation | Central Archive rings awaken/slow/final unfold | 1,10–15 | R-HUB | 3–4 sequences | Core hero animation reused |
| ANIM-009 | MUST | Character / Rig / Animation | Fragment reveal / float / settle | 2,3,5,7,8,10–13 | R-FINAL | 1 generic sequence | Applied to all sigils |
| ANIM-010 | MUST | Character / Rig / Animation | Door/gate open/close | 0–8,15 | R-ARCHIVE | 1 generic + timing variants | Shared hinges/rails |

## Stage 0 — Пролог «Последняя искра»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S00-001 | MUST | Hero | Экстерьер дома/купола в ночном состоянии | 0 | R-HUB | ARCH-001/002/017/018 reuse |  |
| S00-002 | MUST | VFX | Последняя искра / guided light particle | 0 | R-GLOBAL | VFX-002 variant + scripted path |  |
| S00-003 | MUST | Lighting | Night exterior lighting state | 0 | R-HUB | Moon fill + one warm practical source |  |
| S00-004 | MUST | Camera | Prologue cinematic path | 0 | R-GLOBAL | CAM-002, unique path data |  |
| S00-005 | MUST | Prop | Door lock/activation detail | 0 | R-ARCHIVE | generic mechanism child parts |  |

## Stage 1 — Центральная обсерватория «Пробуждение Архива»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S01-001 | MUST | Hero | Central Archive mechanism complete | 1 | R-HUB | PROP-001/002 |  |
| S01-002 | MUST | Puzzle | Pickup lens | 1 | R-ARCHIVE | PROP-003 |  |
| S01-003 | MUST | Puzzle | Lens socket / missing part indicator | 1 | R-ARCHIVE | PROP-003 |  |
| S01-004 | MUST | World | Five wing gates + dormant/active states | 1 | R-ARCHIVE | ARCH-014 ×5 |  |
| S01-005 | MUST | VFX | Five hub light channels + one active route | 1 | R-ARCHIVE | ARCH-015/VFX-001 |  |
| S01-006 | MUST | Lighting | Hub sleeping/awakened lighting states | 1 | R-HUB | same room, two states |  |

## Stage 2 — Крыло I «Тепло / Свет»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S02-001 | MUST | Puzzle | Three concentric optical rings | 2 | UNIQUE | 1 hero mechanism; ring parts can reuse central ring trim |  |
| S02-002 | MUST | Puzzle | Light source/emitter and star target | 2 | R-ARCHIVE | shared beam system + unique star target |  |
| S02-003 | MUST | Puzzle | Focus wheel with 5 discrete positions | 2 | UNIQUE | 1 wheel; uses generic dial hardware |  |
| S02-004 | MUST | Hero | Hearth mechanism / bowl | 2 | UNIQUE | 1 asset, warm activation state |  |
| S02-005 | MUST | Narrative | Star fragment presentation | 2 | R-FINAL | SIG Star + shared fragment stand |  |
| S02-006 | MUST | Narrative | Hearth fragment presentation | 2 | R-FINAL | SIG Hearth + shared fragment stand |  |
| S02-007 | MUST | Lighting/VFX | Cold-to-warm room state | 2 | R-GLOBAL | light/material parameter shift |  |

## Stage 3 — Крыло II «Жизнь / Голос»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S03-001 | MUST | Puzzle | Central resonator / waveform projector | 3 | UNIQUE | 1 hero prop |  |
| S03-002 | MUST | Puzzle | Three local resonators, 3 states each | 3 | R-ARCHIVE | 1 mesh instanced ×3 |  |
| S03-003 | MUST | UI/VFX | Visual wave sample: short/medium/long | 3 | R-GLOBAL | 3 curve presets, not separate meshes |  |
| S03-004 | MUST | Puzzle | Three concentric impulse rings | 3 | UNIQUE | 1 ring set |  |
| S03-005 | MUST | Hero | Sprout/living node | 3 | UNIQUE | mesh + 3 growth states/animation |  |
| S03-006 | MUST | Narrative | Echo and Sprout fragment presentations | 3 | R-FINAL | 2 sigils + shared fragment rig |  |
| S03-007 | MUST | Transition | Archive room → raid memory dissolve rig | 3 | R-GLOBAL | VFX-005 |  |

## Stage 4 — Воспоминание I «Первая встреча»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S04-001 | MUST | Environment | Compact raid arena shell | 4 | R-RAID | modular raid wall/floor/column kit |  |
| S04-002 | MUST | Gameplay | Two resonance runes / marked positions | 4 | R-RAID | 1 rune mesh/material instanced ×2 |  |
| S04-003 | MUST | Character | Author avatar | 4 | R-CHAR | CHAR-002 |  |
| S04-004 | MUST | Character | Heroine avatar/shadow/silhouette support | 4 | R-CHAR | CHAR-001 |  |
| S04-005 | FALLBACK | Character | Background raid participants | 4 | R-RAID | CHAR-003 instances |  |
| S04-006 | MUST | VFX | Two rune waves converge | 4 | R-GLOBAL | beam/pulse variant |  |
| S04-007 | MUST | Animation | Rune stabilization + neutral head-turn | 4 | R-CHAR | ANIM-001/002 |  |

## Stage 5 — Крыло III «Смех / Легкость»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S05-001 | MUST | Hero | Central kinetic mobile | 5 | UNIQUE | 1 assembly |  |
| S05-002 | MUST | Puzzle | Three counterweights with 3 fixed positions | 5 | UNIQUE | 1 base instanced ×3 |  |
| S05-003 | MUST | Puzzle | Environmental clue set for 3 sections | 5 | UNIQUE | 3 simple clue meshes/decals |  |
| S05-004 | MUST | Puzzle | Main brake + three stoppers | 5 | R-ARCHIVE | generic lever/stopper hardware |  |
| S05-005 | MUST | Hero | Feather release prop | 5 | UNIQUE | 1 mesh, animated |  |
| S05-006 | MUST | Hero | Bell cascade set | 5 | UNIQUE | 3–5 bell meshes; shared material |  |
| S05-007 | MUST | Narrative | Feather and Bell fragment presentations | 5 | R-FINAL | 2 sigils |  |
| S05-008 | MUST | Transition | Egg-shaped transition component | 5 | UNIQUE | simple oval shell; becomes memory egg cue |  |

## Stage 6 — Воспоминание II «Яйцо»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S06-001 | MUST | Hero | Egg hero prop + first-person held variant | 6 | UNIQUE | 1 mesh, 2 attachment states |  |
| S06-002 | MUST | Environment | Nest / egg pedestal | 6 | UNIQUE | 1 mesh |  |
| S06-003 | MUST | Environment | Raid stealth corridor/arena extensions | 6 | R-RAID | reuse S04 kit + collapse pieces |  |
| S06-004 | MUST | Gameplay | 3–4 cover props | 6 | R-RAID | columns/mechanisms/statue debris from shared kit |  |
| S06-005 | MUST | Character | Raid watchers | 6 | R-RAID | CHAR-003 instanced |  |
| S06-006 | MUST | Character | Boss wake asset | 6 | UNIQUE | CHAR-004 |  |
| S06-007 | MUST | Hazard | Collapsing ceiling segments | 6 | UNIQUE | 2–3 chunks + dust; scripted |  |
| S06-008 | MUST | Hazard | Poison river/strip shader planes | 6 | UNIQUE | MAT-017 + simple plane meshes |  |
| S06-009 | MUST | Hazard | Snake hazard instances | 6 | UNIQUE | CHAR-005 reused instances |  |
| S06-010 | MUST | Environment | Broken edge / rescue ledge | 6 | R-RAID | modular stone pieces |  |
| S06-011 | MUST | Character/Anim | Dracthyr rescue sequence | 6 | R-CHAR | CHAR-002 + ANIM-003 |  |
| S06-012 | MUST | VFX | Rewind-to-checkpoint memory effect | 6 | R-GLOBAL | screen/light distortion; reusable fail feedback |  |

## Stage 7 — Крыло IV «Серьезность / Улыбка»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S07-001 | MUST | Hero | Frosted memory glass / optical plate | 7 | UNIQUE | 1 panel + afterimage layer |  |
| S07-002 | MUST | Puzzle | Replay shutter/button | 7 | R-ARCHIVE | generic console/shutter child part |  |
| S07-003 | MUST | Puzzle | Four symbol discs, 3 states each | 7 | UNIQUE | 1 disc mesh instanced ×4 + symbol atlas |  |
| S07-004 | MUST | Content | Four imprint symbols / pattern textures | 7 | UNIQUE | small 2D atlas |  |
| S07-005 | MUST | Puzzle | Double Moon left/right discs, 4 orientations | 7 | UNIQUE | 2 mirrored hero parts |  |
| S07-006 | MUST | Narrative | Sun Glint and Double Moon fragments | 7 | R-FINAL | 2 sigils |  |
| S07-007 | MUST | VFX | Faint memory afterimage + smile-like warm arc | 7 | R-GLOBAL | shader/curve effect |  |

## Stage 8 — Крыло V «Искренность / Восхищение»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S08-001 | MUST | Hero | Constellation table / star map mechanism | 8 | UNIQUE | 1 hero assembly |  |
| S08-002 | MUST | Puzzle | Four observers / optical viewers | 8 | R-ARCHIVE | 1 mesh instanced ×4 |  |
| S08-003 | MUST | Puzzle | 8 star nodes / connectable points | 8 | R-GLOBAL | 1 node mesh instanced |  |
| S08-004 | MUST | Puzzle | Constellation line renderer | 8 | R-GLOBAL | Line3D/mesh system |  |
| S08-005 | MUST | Hero | Crystal assembly / main crystal | 8 | UNIQUE | 1 crystal + base |  |
| S08-006 | MUST | Puzzle | Three filter frames, 3 states each | 8 | R-ARCHIVE | 1 frame instanced ×3 |  |
| S08-007 | MUST | Puzzle | Projection screen / frosted target | 8 | R-GLOBAL | frosted glass panel |  |
| S08-008 | MUST | Narrative | Constellation and Crystal fragments | 8 | R-FINAL | 2 sigils |  |
| S08-009 | MUST | Narrative | Future Record panel «Не создана» | 8 | UNIQUE | 1 system panel + world-space text |  |

## Stage 9 — Воспоминание III «То, чего еще нет»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S09-001 | MUST | Environment | Fantasy path / archive bridge modules | 9 | R-ARCHIVE | reuse stone/rail modules, new layout |  |
| S09-002 | MUST | Environment | Neutral real-world path/bridge/park segment | 9 | UNIQUE | small modular set, no specific city identity |  |
| S09-003 | MUST | Environment | Water plane / reflective surface | 9 | R-GLOBAL | simple shader plane |  |
| S09-004 | MUST | Character | Author avatar on parallel path | 9 | R-CHAR | CHAR-002 |  |
| S09-005 | MUST | Character | Heroine shadow/reflection/silhouette support | 9 | R-CHAR | CHAR-001 |  |
| S09-006 | MUST | VFX | Fantasy → real dissolve | 9 | R-GLOBAL | VFX-005 variant |  |
| S09-007 | MUST | VFX | Final single light point | 9 | R-GLOBAL | small emissive particle/node |  |
| S09-008 | MUST | Camera/Path | Author Path3D synchronized to player progress | 9 | R-GLOBAL | data/controller, no new mesh |  |

## Stage 10 — Возвращение в обсерваторию

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S10-001 | MUST | Environment | Fully restored hub state | 10 | R-HUB | reuse stage 1 room, new light/state |  |
| S10-002 | MUST | Hero | Final table unfold variant integrated into central mechanism | 10 | R-HUB | PROP-001 alternate state |  |
| S10-003 | MUST | Gameplay | 10 empty sigil sockets | 10 | R-FINAL | 1 socket mesh instanced ×10 |  |
| S10-004 | MUST | Presentation | 10 sigil instances in found/free arrangement | 10 | R-FINAL | SIG-001–010 |  |
| S10-005 | MUST | VFX | Five wing channels converge into center | 10 | R-HUB | VFX-001 reused |  |

## Stage 11 — Финальная головоломка «Порядок света»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S11-001 | MUST | Puzzle | Five pair nodes / frames | 11 | R-FINAL | 1 pair-node assembly instanced ×5 |  |
| S11-002 | MUST | Puzzle | 10 placement sockets + swap state | 11 | R-FINAL | reuse S10 sockets |  |
| S11-003 | MUST | VFX | Wrong / right-pair-wrong-order / solved visual states | 11 | R-FINAL | 3 light state presets |  |
| S11-004 | MUST | VFX | Continuous final light path through 10 sigils | 11 | R-FINAL | Line/VFX system |  |
| S11-005 | MUST | UI | Context hint labels for 5 nodes | 11 | R-GLOBAL | UI-003 reused |  |

## Stage 12 — Сборка стихотворения

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S12-001 | MUST | UI/World-space | 10 poem block rigs | 12 | R-FINAL | 1 template instanced ×10 |  |
| S12-002 | MUST | UI/World-space | Full poem final layout | 12 | R-FINAL | responsive single-column layout |  |
| S12-003 | MUST | VFX | Poem fragment appear + blocks merge | 12 | R-FINAL | text fade/position animation |  |
| S12-004 | MUST | Typography | Cyrillic poem font/render style | 12 | R-GLOBAL | FONT-002 or approved readable family |  |

## Stage 13 — Раскрытие акростиха

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S13-001 | MUST | UI/VFX | 10 initial-letter overlay nodes aligned to poem | 13 | R-FINAL | 1 component ×10 |  |
| S13-002 | MUST | VFX | Poem text dissolve leaving initials | 13 | R-FINAL | shared text dissolve shader/animation |  |
| S13-003 | MUST | UI/VFX | Vertical → horizontal letter rearrangement | 13 | R-FINAL | animation data only |  |
| S13-004 | MUST | UI | Final phrase rig «Я люблю тебя» | 13 | R-FINAL | same glyphs/typography, no new font |  |

## Stage 14 — Признание

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S14-001 | MUST | UI | Main confession phrase state | 14 | R-FINAL | reuse S13 phrase rig |  |
| S14-002 | MUST | UI | Short author message panel/text style | 14 | R-FINAL | reuse poem typography system |  |
| S14-003 | MUST | Lighting | Archive calm/released lighting state | 14 | R-HUB | existing lights, new animation curve |  |
| S14-004 | MUST | Camera | Confession limited-look/cinematic lock state | 14 | R-GLOBAL | CAM-001 state |  |

## Stage 15 — Эпилог «Рассвет»

| ID | Класс | Категория / тип | Ассет / функция | Этапы | Reuse | Реализация / варианты | Примечание |
|---|---|---|---|---|---|---|---|
| S15-001 | MUST | Environment | Same hub/exterior in dawn state | 15 | R-HUB | reuse ARCH-001/003, no new set |  |
| S15-002 | MUST | Lighting | NIGHT_FINAL → PRE_DAWN → DAWN → MORNING states | 15 | R-HUB | 4 lighting/world presets |  |
| S15-003 | MUST | Sky | Dawn sky material / gradient | 15 | R-GLOBAL | 1 material with animated parameters |  |
| S15-004 | MUST | Camera | Epilogue interior-to-exterior cinematic path | 15 | R-GLOBAL | CAM-002, unique path data |  |
| S15-005 | MUST | UI | Credits layout + skip prompt | 15 | R-GLOBAL | same menu typography |  |
| S15-006 | MUST | VFX | Final archive spark in window / soft trace | 15 | R-GLOBAL | VFX-002 variant |  |
