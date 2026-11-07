# Bundled Cyrillic UI font v1 - bounded acceptance

The project now ships Open Sans at native variable axes weight600/width100, with Noto Sans Symbols then Noto Sans Symbols2 as explicit fallbacks. All three TTFs are unmodified third-party font files from google/fonts commit `6c1dbe27dcf7d817d4b62cec033ba77fa8e2a5ec`; original full SIL Open Font License1.1 notices, copyrights and metadata accompany them. `game/art/fonts/provenance.json` records URLs, sizes, SHA256 and native Git blob hashes. No font authorship is claimed. Three font files total2,138,448 bytes.

The existing semibold UI intent, Russian copy, sizes, margins and colors remain. Each imported FontFile disables host system fallback. Native shaping resolves the complete measured165-codepoint corpus and fallback specimens only to the three bundled families. The corpus covers105 current quoted Cyrillic source strings, basic Latin/digits/punctuation and the complete Russian alphabet including Yo; the development overlay is included. U+2192 required the first Symbols fallback. Unused Noto Sans and Math probes are not installed.

A font-free project Theme loads safely on a cache-free editor run. App._enter_tree assigns the font to that Theme before UI nodes enter. Direct custom_font loading initially failed before the imported caches existed; native attempt1 is retained as FAIL. This is an ordinary startup fix, not a renderer or import pipeline redesign.

During individual image inspection, attempt2 revealed that opening Settings could scroll the first row42px above the view after immediate focus. Settings now defers initial focus until visible layout and resets scroll to zero. Native checks cover first-row label/field visibility, focus, close-before-deferred-focus and reopening. The two scroll diagnostics are preserved, including the probe's initially incorrect Node --script entry point. No failure is deleted or counted as a pass. Attempt2 remains capture-only and is superseded by attempt3.

## Current evidence

`evidence/ui_fonts/native-20261031-3/results.json` is the final bounded receipt: cache-free Godot4.7.2 import, native font pack creation, independent pack load in an empty project, and three actual Forward+ runs. Each resolution has627 assertion executions and12 original images:1280x720,1600x900,1920x1080. All36 originals were individually opened. Do not aggregate earlier617-check runs, old channel checks or unrelated accepted suites into this count.

Nine upstream source/license/metadata files remain byte-exact inside the isolated3,439,256-byte PCK. All three full notices also match the font resource metadata after independent load. Cyrillic and both fallback families shape from that pack with source fonts absent before mounting. This is a bounded native resource-pack test, not a Windows/platform game export or legal release audit.

The images show existing main/confirmation/settings/pause/fragment/retry/exit widgets, a clearly synthetic alphabet/symbol specimen and two supplemental Label3D caption specimens per size. The caption uses current gate font_size38, pixel_size0.005 and billboard properties. Inherited and explicitly assigned bundled fonts rasterize identically at every size. It is not a new gate/world art acceptance. Settings boundary rows may be clipped by the intentional scroll view; the first setting is fully visible on open.

The main-menu corrupt-save notice comes from two isolated synthetic protected fixtures, not user data. Existing UI APIs and quiet visual poses are used; no destructive choice, Apply, real input, persistence failure, gameplay sequence, route or save-reload is claimed. DTO/dirty and both protected primary/backup hashes stay unchanged. The existing guard permits only the documented empty Godot recovery marker.

The first attempt independently read all47 existing GLBs by committed OID/size. Later attempts reused those verified payloads with fresh private copies and cache-free import; the final attempt has zero fresh payload reads and zero new LFS uploads. Software Vulkan uses llvmpipe, not target hardware. Main/base/draft stay unchanged.

## Acceptance boundary

FONT-001 is ACCEPTED for its bundled Cyrillic family, explicit fallback, attributable source bytes and current native readability. FONT-002 remains PARTIAL: no personal/handwritten accent family is supplied. UI-004/005 still need their complete style pass. Full owner style, platform/release testing, target GPU and VS1 remain open; S03 blocked. The prior central-mechanism binary upload refusal is not retried.

Only three of the601 pre-existing game files changed: project Theme configuration, the bounded App font bootstrap and Settings initial focus/scroll. The other598 match baseline `2de7f9018e77a61551ababc51966353a161a77ec` exactly. Geometry, materials, routes, narrative and save schema remain unchanged.

Inventory is185 canonical rows,77 VS1 groups:27 ACCEPTED /43 PARTIAL /7 MISSING. This one row delta is not a full-game completion percentage. Final source/publication SHAs resolve from the working branch and `evidence/checkpoints/continuation_fonts_20261031.jsonl` after acknowledgement.
