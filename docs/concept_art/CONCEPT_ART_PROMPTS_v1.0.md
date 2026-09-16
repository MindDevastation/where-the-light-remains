# CONCEPT_ART_PROMPTS v1.0

Production prompt package for **Where the Light Remains**.

Prompts are intentionally written in English for image generation. Comments and production guidance remain in Russian.

## Как использовать

Рекомендуемый порядок:

1. Центральная обсерватория — закрепить стиль.
2. Все основные зоны.
3. Hero-ассеты.
4. UI.
5. Персонажи и memory scenes.

После появления удачных ключевых артов использовать их как image references для следующих генераций, особенно для центральной обсерватории, архитектуры, палитры, UI и сигилов.

---

# 0. Общий style-prefix

Добавлять в начало большинства промптов:

```text
Stylized realistic 3D game concept art for a romantic first-person puzzle adventure, designed for a playable PC game in Godot 4.x. Atmospheric, elegant, emotionally warm, readable and production-friendly. A magical observatory-archive aesthetic with clear silhouettes, believable architecture, gameplay-friendly layout, moderate ornament, unified visual language, soft volumetric lighting, moonlit blues, warm golds, pale ivory stone, subtle rose dawn accents, polished but not photorealistic, painterly concept art, highly coherent art direction, suitable as production concept art for environment and asset creation.
```

---

# 1. Зоны

Для каждой ключевой зоны желательно генерировать минимум:

- A — hero/key art;
- B — gameplay/functional view.

## 1.1 Пролог — «Последняя искра»

### 01A — Key art

```text
Stylized realistic 3D game concept art for a romantic first-person puzzle adventure. A lonely mountain observatory at night, seen from an exterior approach path under a star-filled sky. The building feels ancient, elegant, magical, and slightly melancholic. Only a few warm lights are still glowing inside, suggesting the place is fading but not abandoned. Stone stairs, wind-swept banners, old brass details, observatory dome, subtle magical glow, atmosphere of quiet anticipation and fragile hope. Emotional, cinematic, atmospheric environment key art.
```

### 01B — Gameplay view

```text
Stylized realistic 3D game environment concept art, first-person gameplay-oriented view. Exterior approach to an ancient observatory at night, with a clear path toward the main entrance. Readable composition, clear navigation, a few interactive lanterns or guiding lights, stone stairs, low clutter, playable scale, readable architecture, mild magical effects, moody blue night light and warm accents from inside the building. Designed as production concept art for level building.
```

## 1.2 Центральная обсерватория — «Пробуждение Архива»

### 02A — Key art

```text
Stylized realistic 3D game concept art of the central observatory hall, the emotional and architectural heart of the game. A circular star archive chamber with a glowing central mechanism, branching wing doors, celestial ceiling, brass rings, stone floor patterns, soft magical light, suspended star maps, elegant archive devices, and a sense of awakening. The room should feel mysterious, beautiful, romantic, and important, with a balance of warm gold light and cool moonlit blue shadows.
```

### 02B — Gameplay view

```text
Production-friendly 3D game environment concept art, first-person view inside the central observatory. Clear readable layout: central archive mechanism in the middle, visible entrances to multiple wings, clean navigation, interactive console or pedestal, gentle magical glow, large dome ceiling, modular architecture, elegant stone and brass materials, atmosphere of discovery and emotional wonder. Designed for gameplay readability and level production.
```

## 1.3 Крыло I — «Тепло / Свет»

### 03A — Key art

```text
Stylized realistic 3D game environment concept art of a warm and luminous wing devoted to warmth and light. A cozy magical chamber combining observatory elegance with gentle domestic comfort: lanterns, glowing glass, sunlike reflections, warm wood and pale stone, soft fabrics, light prisms, golden illumination, comforting atmosphere, emotional sense of safety and first warmth. Romantic, intimate, soft and radiant.
```

### 03B — Gameplay view

```text
First-person gameplay environment concept art for a warm-light puzzle wing. Readable room layout with a clear path, simple light-based puzzle elements, reflective surfaces, lantern mechanisms, soft golden light, cozy archive architecture, uncluttered floor space, clear interactables, gentle visual guidance, elegant stylized materials. Designed as production-ready concept art for a 3D puzzle game.
```

## 1.4 Крыло II — «Жизнь / Голос»

### 04A — Key art

```text
Stylized realistic 3D concept art of a magical wing themed around life and voice. The chamber should feel alive, resonant, and emotionally intimate. Include elegant sound-based devices, harmonic resonators, suspended chimes, subtle waveform motifs, glowing acoustic lines, soft vegetation or life-like magical growth, and a visual feeling of breath, vibration, and presence. Cool-to-warm lighting, lyrical atmosphere, graceful shapes, romantic and heartfelt.
```

### 04B — Gameplay view

```text
First-person gameplay-oriented concept art for a voice-and-life puzzle wing. Clear room structure with readable interactables: resonant devices, sound relays, tone-based puzzle elements, visible route, low clutter, elegant observatory-archive architecture, subtle glowing waveform details, soft volumetric lighting, emotionally warm but gameplay-readable. Designed for production concept art and level implementation.
```

## 1.5 Воспоминание I — «Первая встреча»

### 05A — Key art

```text
Stylized realistic 3D game memory-scene concept art. A fantasy raid setting where two player characters first notice each other for the first time. The environment should feel like a magical MMORPG raid chamber: grand architecture, combat aftermath atmosphere, party presence implied, but the emotional focus is on a quiet moment of first recognition between two characters. Romantic without being explicit, tender and memorable, slightly dreamlike, with fantasy raid aesthetics and warm emotional framing.
```

### 05B — Gameplay / memory space

```text
Stylized realistic 3D concept art for a playable memory scene inspired by a fantasy raid encounter. First-person friendly composition, readable path through a raid-like chamber, visual traces of allies and battle context, but the main focus is a calm memorable point where the first meeting is framed. Clean gameplay readability, gentle dreamlike treatment, magical fantasy architecture, emotionally warm atmosphere.
```

## 1.6 Крыло III — «Смех / Легкость»

### 06A — Key art

```text
Stylized realistic 3D environment concept art of a playful, airy magical wing themed around laughter and lightness. The room should feel brighter, more buoyant, and more whimsical than the previous areas. Include floating details, playful moving mechanisms, light fabrics, curved forms, soft sparkles, elegant but cheerful design language, and a sense of emotional release. Romantic, charming, uplifting, and graceful.
```

### 06B — Gameplay view

```text
First-person gameplay concept art for a playful puzzle wing themed around laughter and lightness. Readable path, simple playful traversal or interaction beats, floating or gently moving puzzle elements, clear focal points, open space, soft cheerful lighting, elegant observatory-archive style, minimal frustration, readable gameplay composition, and a light emotional tone.
```

## 1.7 Воспоминание II — «Яйцо»

### 07A — Key art

```text
Stylized realistic 3D concept art for a fantasy raid memory scene centered on the stolen egg moment. A magical nest chamber with an important egg, raid-like fantasy architecture, tension mixed with humor, serpentine or draconic thematic cues, stealthy mood before chaos, cinematic but playful. The scene should feel memorable, mischievous, and affectionate rather than dangerous.
```

### 07B — Escape gameplay view

```text
First-person gameplay concept art for the “Egg” memory sequence. A readable escape route through a collapsing fantasy raid chamber after taking the egg: broken platforms or debris, poison channels, snake-like minions, falling ceiling elements, but the layout remains clear and accessible. Exciting but not terrifying, playful tension, stylized magical raid environment, production-friendly readability.
```

## 1.8 Крыло IV — «Серьезность / Улыбка»

### 08A — Key art

```text
Stylized realistic 3D environment concept art of a reflective magical wing themed around seriousness and smile. The space should balance quiet depth and gentle warmth: solemn architecture, more focused composition, calmer palette, elegant reflective surfaces, subtle smile-like motifs in shape language, restrained magical light, intimate emotional tone, and a feeling of trust, depth, and tenderness.
```

### 08B — Gameplay view

```text
First-person gameplay-oriented concept art for a reflective puzzle wing themed around seriousness and smile. Clear route, calm spatial composition, readable puzzle station, mirror or alignment mechanics, subtle warm highlights within a more serious environment, elegant stone and brass architecture, emotionally gentle, readable and low-stress design.
```

## 1.9 Крыло V — «Искренность / Восхищение»

### 09A — Key art

```text
Stylized realistic 3D concept art for the most intimate and emotionally honest wing of the game. The environment should feel sincere, elegant, and quietly beautiful. Include refined forms, luminous details, graceful materials, carefully framed focal points, romantic lighting, subtle celestial motifs, and a sense of admiration without excess. The room should feel deeply personal and emotionally truthful.
```

### 09B — Gameplay view

```text
First-person gameplay environment concept art for an intimate puzzle wing centered on sincerity and admiration. Clear navigation, elegant central interactable, soft and flattering light, refined architecture, magical but grounded materials, uncluttered gameplay space, emotionally calm and beautiful. Production-oriented layout with strong readability and atmospheric cohesion.
```

## 1.10 Воспоминание III — «То, чего еще нет»

### 10A — Key art

```text
Stylized realistic 3D concept art for a dreamlike future-memory scene, representing something that has not happened yet: a future meeting, a promise, a shared possibility. The image should feel hopeful, gentle, and emotionally open. Two characters may be present or implied. Use a poetic environment such as a bridge, dawn-lit terrace, celestial promenade, or quiet magical overlook. Romantic, tender, symbolic, never forceful.
```

### 10B — Gameplay / memory view

```text
Stylized realistic 3D environment concept art for a playable future-memory scene. The location should feel slightly unreal and symbolic, but still readable as a playable space. Clear path, low complexity, soft dawn or starlight, elegant fantasy architecture, emotional sense of possibility and calm anticipation. Designed for a short reflective interactive scene.
```

## 1.11 Возвращение в обсерваторию

### 11A — Key art

```text
Stylized realistic 3D concept art of the central observatory after multiple wings have been restored. The archive hall is brighter, more complete, and emotionally fuller than before. More lights are active, suspended constellations glow stronger, the central mechanism is partially awakened, and the room carries a sense of nearing revelation. Romantic magical atmosphere, elegant coherence, emotional buildup before the finale.
```

### 11B — Gameplay view

```text
First-person gameplay concept art of the restored central observatory. Clear navigation, more active visual systems, readable access to final puzzle area, visible progress through lighting and architecture, central mechanism more alive, still uncluttered and easy to read. Production-friendly environment art with emotional anticipation.
```

## 1.12 Финальная головоломка — «Порядок света»

### 12A — Key art

```text
Stylized realistic 3D concept art of the final puzzle chamber focused on order, symbols, and light. A graceful central structure where collected symbols must be arranged in the correct sequence. Constellation lines, luminous sigils, elegant stone-and-brass puzzle table, suspended magical geometry, emotionally charged but calm, beautiful final logic space, romantic and meaningful rather than mechanical.
```

### 12B — Gameplay view

```text
First-person gameplay-oriented concept art of the final symbol-order puzzle. Clear puzzle board, visible slots for symbols, readable clue locations, low clutter, strong focus on interaction clarity, elegant magical lighting, and a sense of importance. The puzzle space should feel special, final, and emotionally resonant while remaining easy to parse.
```

## 1.13 Финальная последовательность

### 13A — Poem assembly

```text
Stylized realistic 3D concept art of a poetic assembly space where collected couplets are brought together into one complete poem. A serene magical table or archive interface with floating text fragments represented as glowing cards, ribbons of light, or elegant paper-like panels. Intimate, beautiful, calm, and emotionally focused, with a sense of nearing personal revelation.
```

### 13B — Acrostic reveal

```text
Stylized realistic 3D concept art of the acrostic reveal moment. Hidden symbols align into a meaningful final order, and light begins to resolve them into a confession. The scene should feel magical, elegant, emotionally strong, and visually clear. Symbolic light, luminous glyphs, celestial motion, and a restrained but deeply romantic atmosphere.
```

### 13C — Confession

```text
Stylized realistic 3D concept art of the confession scene in a magical observatory at the threshold of dawn. The atmosphere is deeply sincere, tender, and calm, never overwhelming or forceful. Warm light begins to replace night, the space feels intimate and open, and the emotional tone is honest, gentle, and human. Romantic final scene concept art.
```

### 13D — Dawn epilogue

```text
Stylized realistic 3D concept art of the epilogue at dawn. The observatory and surrounding world are peaceful, softly illuminated by sunrise. The mood is quiet, relieved, hopeful, and warm. Elegant architecture, soft sky colors, emotional closure, gentle beauty, and a sense that something precious has been said and safely received.
```

---

# 2. Hero-ассеты

## 2.1 Центральный механизм Архива

```text
Production concept art of the central Archive mechanism for a romantic fantasy observatory game. A large hero prop combining brass rings, celestial geometry, glowing crystal or light core, elegant stone base, magical archival design language, and refined mechanical details. It should feel ancient, beautiful, mysterious, and emotionally important. Show it as a hero asset with clean readable silhouette, material clarity, and production-friendly structure.
```

## 2.2 Устройство «Тепло / Свет»

```text
Production prop concept art for a hero puzzle device themed around warmth and light. The object should combine lantern, prism, and observatory design language. Warm glow, elegant brass and pale stone materials, soft golden light, readable interactable components, and a comforting visual identity. Designed as a hero prop for a 3D puzzle game.
```

## 2.3 Устройство «Жизнь / Голос»

```text
Production prop concept art for a hero puzzle device themed around life and voice. A magical resonator with elegant acoustic forms, harmonic rings, glowing waveform motifs, and observatory-archive aesthetics. The object should feel alive, resonant, intimate, and readable as an interactable gameplay prop.
```

## 2.4 Устройство «Смех / Легкость»

```text
Production prop concept art for a hero puzzle device themed around laughter and lightness. Airy, playful, elegant shapes, suspended moving elements, soft glow, a sense of buoyancy and delight, clean silhouette, and clear functional parts. Designed as a stylized 3D game asset.
```

## 2.5 Устройство «Серьезность / Улыбка»

```text
Production prop concept art for a hero puzzle device themed around seriousness and smile. Balanced design with calm symmetry, reflective surfaces, subtle warm accents, and elegant mechanical logic. The object should feel thoughtful, intimate, and readable, with a restrained but emotionally meaningful silhouette.
```

## 2.6 Устройство «Искренность / Восхищение»

```text
Production prop concept art for a hero puzzle device themed around sincerity and admiration. Refined, luminous, elegant, emotionally open design with graceful forms, crystal or celestial motifs, flattering light response, and clear interactive structure. A hero prop for a romantic magical 3D puzzle game.
```

## 2.7 Яйцо

```text
Production prop concept art of a magical egg artifact from a fantasy raid memory. The egg should feel important, slightly mischievous, and visually memorable. Elegant fantasy ornament, subtle magical glow, readable silhouette, and enough material detail to support a 3D model. It should look special but not grotesque or dark.
```

## 2.8 Финальный стол / puzzle board

```text
Production concept art of the final puzzle table for arranging symbols and revealing the hidden message. Elegant stone and brass design, glowing slots for symbols, celestial logic motifs, graceful proportions, readable interaction points, and a strong central silhouette. The object should feel like the climax of the entire game.
```

## 2.9 Future-record / promise object

```text
Production prop concept art of a symbolic object representing a future meeting or shared promise. The design should feel poetic, hopeful, and emotionally open, using elegant observatory-fantasy materials and subtle magical light. It should function as a memorable story prop rather than a generic decoration.
```

## 2.10 Sheet of all sigils

```text
Concept sheet of 10 magical sigils for a romantic observatory puzzle game. Each sigil should be distinct, elegant, readable, and thematically linked to the game’s emotional progression. The set should feel coherent, celestial, refined, and suitable for use in puzzles and UI. Clean presentation on a neutral concept sheet, clear separation between symbols, production-friendly readability.
```

## 2.11 Sigil close-up style test

```text
Close-up prop concept sheet exploring the visual language of the game’s magical sigils: elegant geometry, soft glow, celestial line work, refined symbolic structure, romantic magical atmosphere, readable at gameplay size, suitable both for environment use and UI presentation.
```

## 2.12 Generic modular observatory kit

```text
Production concept sheet for a modular observatory-archive environment kit. Include walls, arches, floors, stairs, railings, columns, door frames, ceiling trims, and puzzle pedestals. Stylized realistic, elegant, magical observatory style, gameplay-friendly scale, clean silhouettes, unified materials, and production-ready modular logic for a 3D game.
```

---

# 3. UI / меню

## 3.1 Главное меню

```text
UI concept art for the main menu of a romantic first-person puzzle game set in a magical observatory. Elegant, atmospheric, and readable. The menu should feel integrated with the world: celestial motifs, refined frames, gentle glow, understated magical ornament, calm background scene, and emotionally warm presentation. Stylized fantasy UI, clean hierarchy, production-ready concept.
```

## 3.2 Пауза / настройки

```text
UI concept art for pause and settings screens of a romantic fantasy puzzle game. Clear, readable layout with elegant observatory-inspired framing, gentle magical accents, soft gold and blue palette, modern usability, and a stylized in-world visual identity. Include audio, graphics, controls, and accessibility sections in a clean and production-friendly structure.
```

## 3.3 Экран коллекции двустиший

```text
UI concept art for a poem-fragment collection screen. The player gathers couplets during the game and later assembles them. The screen should feel intimate, elegant, and readable, like a magical archive of personal fragments. Graceful cards or pages, soft light, gentle ornament, clear categorization, and a calm romantic tone.
```

## 3.4 Экран финальной сборки

```text
UI concept art for the final poem/symbol assembly screen in a romantic observatory puzzle game. The interface should feel special, ritual-like, elegant, and readable. Clearly visible slots, draggable pieces or symbols, subtle clue support, celestial decorative framing, and emotionally meaningful presentation.
```

## 3.5 Экран секретов / достижений

```text
UI concept art for an optional secrets and achievements screen in a romantic fantasy puzzle game. Clean and elegant layout, subtle magical archive framing, readable icons, low clutter, warm and inviting presentation, and a sense of hidden personal discoveries rather than competitive progression.
```

## 3.6 Финальный end screen / epilogue card

```text
UI concept art for the game’s final end screen after the dawn epilogue. Minimal, emotionally warm, elegant, and quietly beautiful. Soft dawn-inspired palette, refined observatory motifs, simple typography area, and a feeling of tenderness and closure.
```

---

# 4. Персонажи

Для character-generation прикладывать screenshot игровой модели как primary reference. Для парных сцен — оба референса.

## 4.1 Персонаж 1 — concept sheet

```text
Use Image A as the primary visual reference for the character. Create a polished concept sheet for this game character in the art style of a stylized realistic 3D romantic fantasy puzzle game. Preserve the key silhouette, outfit logic, class/species identity, and recognizable visual traits from the reference, but refine them into a cohesive concept-art presentation. Show front view, three-quarter view, and one expressive portrait close-up. Elegant observatory-fantasy styling, production-friendly readability, clean materials, and gentle romantic tone.
```

## 4.2 Персонаж 2 — concept sheet

```text
Use Image A as the primary visual reference for the character. Create a polished concept sheet for this character, preserving the recognizable silhouette, colors, clothing logic, and overall identity from the model reference. Present the character in a stylized realistic 3D fantasy game concept-art style suitable for a romantic story-driven puzzle game. Include front view, three-quarter view, and one emotional portrait close-up.
```

## 4.3 Парный character mood sheet

```text
Use Image A and Image B as the primary references for the two characters. Create a paired concept-art sheet showing how both characters fit together visually in the same game world. Preserve their recognizable silhouettes and identities from the references, while refining them into a cohesive stylized realistic 3D game art style. Show them side by side, with one or two small interaction poses that suggest warmth, trust, and familiarity without overt melodrama.
```

## 4.4 Первая встреча — key frame

```text
Use Image A and Image B as visual references for the two characters. Create a key-frame concept art image of their first meeting in a fantasy raid environment. Preserve their recognizable appearance from the references, but render them in a polished, emotionally warm, stylized realistic 3D game concept-art style. The focus is on the feeling of first recognition: not a dramatic romance scene, but a memorable first moment. Fantasy raid architecture, subtle party context, soft emotional framing.
```

## 4.5 Сцена «Яйцо» — кража

```text
Use Image A and Image B as visual references for the characters. Create a stylized realistic 3D concept-art scene inspired by a fantasy raid memory where the female character has just taken the egg. The moment should feel playful and tense, with fantasy raid architecture and a memorable egg prop. Preserve both characters’ recognizable appearances. Emotional tone: mischievous, affectionate, exciting.
```

## 4.6 Сцена «Яйцо» — спасение

```text
Use Image A and Image B as visual references for the characters. Create a stylized realistic 3D game concept-art key frame in which the male dracthyr character catches and carries the female character away to safety after the egg sequence. Preserve both characters’ recognizable appearances and silhouettes from the references. The moment should feel dynamic, heroic, affectionate, and cinematic, but still grounded in the game’s romantic, gentle tone.
```

## 4.7 Сцена «То, чего еще нет»

```text
Use Image A and Image B as visual references for the characters. Create a dreamlike future-memory concept art scene showing the two characters in a symbolic, hopeful shared future setting. Preserve the recognizable identities from the references. The emotional tone should be tender, calm, and open, suggesting a promise or future meeting without pressure. Stylized realistic 3D fantasy-romantic key frame.
```

## 4.8 Финальная парная сцена

```text
Use Image A and Image B as visual references for the characters. Create a final emotionally sincere concept-art image set at dawn inside or near the observatory. Preserve both characters’ recognizable appearances while refining them into a beautiful, cohesive stylized realistic 3D game art style. The scene should feel warm, intimate, honest, and calm, with no excessive melodrama.
```

---

# 5. Production reference sheets

## 5.1 Material sheet

```text
Production concept sheet for the core material language of a romantic magical observatory game. Show the main materials used across the project: pale observatory stone, aged brass, polished dark wood, warm fabric, frosted glass, glowing crystal, etched celestial metal, subtle magical light surfaces. Present them clearly and coherently as a material reference sheet for 3D asset production.
```

## 5.2 Architectural shape language sheet

```text
Production concept sheet exploring the architectural shape language of a romantic observatory-archive game. Show recurring silhouettes, arches, domes, railings, pedestal shapes, trims, doors, and puzzle-station forms. Emphasize a unified visual language that is elegant, readable, and modular for 3D production.
```

## 5.3 Lighting guide sheet

```text
Concept sheet showing the lighting language of the game’s main zones. Include examples of moonlit blue ambience, warm golden puzzle light, intimate dawn rose accents, reflective brass highlights, soft volumetric haze, and magical glow behavior. The goal is a production-friendly lighting reference for environment art consistency.
```

---

# 6. Полезные модификаторы

### Более прикладной арт

```text
Focus on production-friendly clarity, readable forms, practical layout, and usable details for 3D modeling.
```

### Более эмоциональный key art

```text
Emphasize mood, emotional atmosphere, cinematic composition, and a strong romantic-fantasy visual identity.
```

### Игровой ракурс

```text
Use a first-person gameplay-friendly viewpoint with clear navigation, readable interactables, and low-clutter composition.
```

### Sheet / turnaround

```text
Present the object as a clean concept sheet with front, three-quarter, and detail callout views.
```

---

# 7. Рекомендуемый порядок генерации

## Пачка 1 — база стиля

1. 02A — Central Observatory key art
2. 02B — Central Observatory gameplay view
3. 03A — Wing I
4. 04A — Wing II
5. 12A — Final Puzzle
6. 13D — Dawn Epilogue

## Пачка 2 — остальные зоны

Все остальные environment prompts.

## Пачка 3 — Hero assets

Промпты 2.1–2.12.

## Пачка 4 — UI

Промпты 3.1–3.6.

## Пачка 5 — персонажи

Промпты 4.1–4.8 с приложенными screenshot references.

---

# 8. Требования к character references

Для лучшего результата желательно приложить:

- полный рост;
- 3/4 ракурс;
- по возможности крупный вид лица / шлема / прически;
- кадры без перегруженного фона;
- для парных сцен — отдельные четкие референсы обоих персонажей.

Generated character concepts are references for an original/stylized game interpretation, not instructions to extract third-party game assets.
