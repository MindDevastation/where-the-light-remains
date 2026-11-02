# Fragment sigil materialize/dissolve v1 - source brief

VFX-004 is currently missing. This bounded continuation starts with the existing Star and Hearth glyphs in FragmentPresenter. A small native CanvasItem shader will reveal the glyph over0.35s and dissolve one noninteractive glyph copy over0.28s after normal dismissal. Shared source, per-instance material state, no shader TIME or new light/particle system.

Present, Continue/Escape dismissal, closed signal, input restoration, score duck release and physical checkpoint behavior stay synchronous. Text and buttons remain available immediately. Quiet restore/free never replay an effect. Effects-off keeps the original glyph instantly and creates no ghost. Pause freezes the owned animation; resize, rebinding, new presentation, foreign material/reparent and scene exit cancel safely. Unsupported transformed layouts use the static fallback.

Existing glyph textures, font bundle, Russian copy, layout, puzzle clocks, routes, save schema and ArchiveMain remain authoritative. The precise candidate contract is fragment_sigil_dissolve_v1.json. Tests must include native intermediate reveal/dissolve, exact settled glyph raster, actual modal lifecycle/ownership and affected audio behavior. No source or native validation is claimed yet.

This is BRIEF_ONLY_WIP. VFX-004 remains MISSING until measured bounded acceptance; full world carrier, later sigils/stages, final UI/VFX style, owner art and target GPU remain separate. GATE-VS1 OPEN/S03 blocked. The central-mechanism binary upload refusal is not retried or converted.
