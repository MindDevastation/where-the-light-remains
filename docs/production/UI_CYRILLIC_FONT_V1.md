# Bundled Cyrillic UI font v1 - source checkpoint

FONT-001 currently relies on the engine default and system fallback. This bounded continuation bundles the unmodified Open Sans variable font and Noto Sans Symbols 2 Regular, with their original SIL Open Font License 1.1 notices and metadata from pinned google/fonts commit `6c1dbe27dcf7d817d4b62cec033ba77fa8e2a5ec`.

The planned default is Open Sans weight 600 and width 100, keeping the existing semibold UI intent. A native FontVariation will name the bundled symbol fallback explicitly. The full notices will also travel as resource metadata with the project font so a future resource export does not silently drop attribution. No platform export or legal release audit is claimed at this checkpoint.

Integration will use the project custom-font setting. Existing Russian text, UI font sizes, layouts, controls, save ownership, routes, lights and quality settings remain authoritative. Native checks must confirm Cyrillic including Yo, all current source text codepoints, effective font binding, explicit fallback glyph shaping, and clipping/visibility across current menus, fragments and notices at supported resolutions. Source/native evidence and actual originals will be recorded separately.

This is SOURCE_ONLY_WIP. FONT-001 remains PARTIAL and FONT-002 stays unchanged. No old channel, art, gameplay or full owner-gallery suite is replayed. GATE-VS1 OPEN; S03 blocked. The previous central-mechanism LFS upload refusal is not retried or converted into another format.
