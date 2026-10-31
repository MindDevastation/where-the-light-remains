# Bundled Cyrillic UI font v1 - integration checkpoint

FONT-001 previously relied on the engine default and system fallback. The candidate now uses Open Sans variable at weight600/width100, with explicit Noto Sans Symbols and Noto Sans Symbols2 fallbacks. All three unmodified TTFs, original SIL Open Font License1.1 notices and metadata come from pinned google/fonts commit `6c1dbe27dcf7d817d4b62cec033ba77fa8e2a5ec`. No font authorship is claimed.

The native FontVariation is assigned through the project custom-font setting. Each imported font disables host system fallback. Complete notices are also stored in resource metadata to retain attribution in resource packs; this does not claim a platform export or legal release audit. The offline assembly source is `tools/create_archive_ui_font.gd`.

`tools/build_ui_font_corpus.py` records105 quoted current Cyrillic source strings, including the development overlay, plus the complete Russian alphabet and basic Latin/digits/punctuation:165 unique codepoints. Source cmap coverage passes. The U+2192 arrow is absent from Open Sans and Symbols2; measured probes selected Symbols1 rather than altering source text. Unused Noto Sans/Math candidates remain scratch diagnostics and are not installed. Native glyph/shaping and UI layout validation are still pending.

A preliminary native graphical capability frame proved custom-font binding and Cyrillic/symbol rasterization with the initial two-file fallback candidate. It is not final three-file UI acceptance. A stale private import cache initially retained a font's prior system-fallback option; a cache-free private import and native assembly pass. The original diagnostic and successful assembly logs are retained.

Russian copy, UI font sizes/layouts, controls, routes, save ownership, lights and global quality remain unchanged. The only existing runtime file changed is the project font assignment. The font-local attributes mark TTFs as ordinary Git binaries and preserve the upstream trailing space on line21 of the two Noto licenses. No upstream license bytes are edited.

Status: NATIVE_RESOURCE_WIP. Current controls at supported resolutions, effective font fallback shaping, full current corpus rendering and independent pack notice/readback checks remain pending. FONT-001 stays PARTIAL; FONT-002 unchanged. GATE-VS1 OPEN; S03 blocked. Earlier art/gameplay suites are not replayed. The central-mechanism binary upload refusal is not retried or converted.
