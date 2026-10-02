# Approved visual baseline v2 — Hybrid Warcraft Observatory

Owner visual migration instruction, 2026-10-02 UTC / 2026-10-03 Moscow.
Incoming pack commit: `cabe792717828dfe54009219a7f6cc4e0fb5e5e6`.

**Current visual authority:** named `*_v2_angle_a/b/c.png` sets, with the
adaptations in [VISUAL_REBASELINE_V2.md](../../docs/production/VISUAL_REBASELINE_V2.md).
A is establishing/hero, B alternate/opposite 3/4, C functional/production.
Each triplet is one design. Do not treat view drift as three permitted variants.
There are 45 named slots / 134 images: Secrets-Achievements has A/B, **C missing**.
The new S04 and S06 `zone_environment_a/b/c.png` are two additional three-view
shell designs, constrained by their respective gameplay briefs.

Visual language: strong original Warcraft-inspired craft, celestial archive,
worn pale/warm stone, aged/carved timber, dark iron, aged brass, leather,
restrained crimson/deep navy textile, cobalt moonlight, amber practicals and
restrained arcane gold/teal. Warm lived-in workspaces, books and furniture;
no dominant Christmas/holiday garlands, candle rows, flowers, greenery or banquet.

Canonical mechanics, narrative, Russian copy, accessibility and technical budgets
outrank concept images. Generic orreries do not replace wing puzzles. Literal
faction marks/proprietary armor/textures are never copied into shipping assets.
Sigil imagery supplies craft only: exactly ten named project sigils retain their
identity. UI placeholder counts, text and dates are not canonical.

## Additional candidates

Actual directory: `additional_concepts/`. All nine reviewed individually in
[ADDITIONAL_CONCEPTS_REVIEW.md](../../docs/production/ADDITIONAL_CONCEPTS_REVIEW.md).
No promotion: 2/3/4 are exact copies of `wi_001` A/B/C, supporting references only.
1/5/6/7/8/9 are **UNMATCHED**, excluded from production decisions until exact
slot assignment. Folder location does not make a candidate canonical.

## Characters and memory single images

Updated `characters/char_d.png`, new `char_e/f/g/j.png`, updated Egg action
images and Future `pair_keyframe.png` are candidates/supporting art, not
implicit approved casting, animation or gameplay architecture. Old a/b/c and
pair sheets are legacy supporting references. Canonical author/heroine roles
are unchanged; final rig/casting inputs remain open.

S09's seated couple pose is **NONCANONICAL narrative staging**: the future is
possible/unresolved, not a promised meeting or reciprocal ending. It may inform
costume/material mood only. `_secondary/noncanonical_final_pair_scene.png`
remains **NONCANONICAL — never use as the ending outcome**.

## Legacy retention — SUPERSEDED / LEGACY

The 62 old payloads at `75f3a04b24fb0b350090d4f9cb49949b0c037b31` are fully
mapped in [visual_rebaseline_v2.json](../../docs/production/visual_rebaseline_v2.json)
and the Markdown matrix. Forty-eight upstream-deleted PNGs were restored at
original paths so historical production/evidence links still work; four
upstream-overwritten versions are under `_legacy/v1/`. Ten unchanged old images
are retained as legacy supporting/secondary references at existing paths.
Every `retained_at` payload in the old mapping is **SUPERSEDED / LEGACY**,
except where the same path now holds an explicitly identified updated single
reference; its old payload is under `_legacy/v1/`. Never infer current authority
from a folder-wide CANONICAL label or from absence of a suffix.

Examples: old `Material sheet.png`, `Architectural shape language sheet.png`,
`Generic modular observatory kit.png`, old environments and UI are historical;
use their v2 sets for new production. `ca_001` consolidates into `ca_002` v2;
`ca_003` consolidates into `ca_004` v2 after subject/function review. The old
S09 environment images lack new A/B/C replacements; they remain supporting,
subject to canon, and cannot define new world/casting without its asset brief.

No historical source or evidence was deleted by this migration. Recheck payload
integrity and unchanged runtime contracts with `python tools/audit_visual_baseline.py`.
