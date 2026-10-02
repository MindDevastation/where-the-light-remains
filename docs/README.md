# Documentation index

Implementation-facing documentation for **Where the Light Remains**.

## Canonical design

- `design/PROJECT_BIBLE_INDEX.md` — document precedence and canonical split map.
- `design/PROJECT_SUMMARY.md` — compact project/stage overview.
- `design/NARRATIVE_CANON.md` — narrative constraints and Stage 0–15 canonical beats.
- `design/TECHNICAL_BASELINE.md` — Godot architecture, saves, settings and performance rules.
- `design/AUDIO_BASELINE.md` — audio-system constraints derived from Audio Direction v1.2 / AUDIO_PLAN v1.0.
- `design/REQUIRED_ASSET_TABLE.md` — 185 required/fallback asset groups from ASSET_MANIFEST v1.0.

## Concept art

- `concept_art/CONCEPT_ART_PROMPTS_v1.1.md` — canonical mechanics correction; visual palette superseded by v2 owner rebaseline.
- `concept_art/CONCEPT_ART_PROMPTS_v1.0.md` — historical prompt pack; do not use where it conflicts with v1.1/master.

Selected reference images live under `assets/concept_art/`; its README explicitly identifies v2 authority and LEGACY/supporting exclusions.

- `production/VISUAL_REBASELINE_V2.md` — complete concept mapping, existing implementation audit, current visual rules and migration status.
- `production/ADDITIONAL_CONCEPTS_REVIEW.md` — every additional candidate and exact promotion/support/unmatched decision.

## Production

- `production/ASSET_INDEX.md` — mapping from selected assets to stages/roles.
- `production/CONTENT_STATUS.md` — readiness and open inputs.
- `production/QA_CHECKLIST.md` — release/acceptance baseline.
- `production/AUDIO_PROVENANCE.md` — source/license metadata status.

## Source-of-truth rule

When repository summaries disagree with the long-form Project Bible v1.8, the master document wins unless a later repository decision is explicitly marked **APPROVED OVERRIDE**. Current approved override: runtime music selection uses `GroupSharedPool + StageUniqueCue` while preserving master silence, transition and adaptive-state rules.
