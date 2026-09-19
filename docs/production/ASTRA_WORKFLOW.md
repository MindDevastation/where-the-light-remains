# Astra implementation workflow

Status: **mandatory execution policy** for implementation work performed through Astra or any equivalent coding agent.

## 1. Product language

The shipping game language is **Russian**.

Mandatory rules:
- all player-facing UI, prompts, hints, settings labels, narrative text, achievement text and credits baseline are Russian;
- Cyrillic rendering must be validated in every UI system;
- internal code identifiers, file names and technical comments may remain English where this improves consistency with the Godot/code naming convention;
- do not silently replace approved Russian narrative copy with translated or newly invented wording;
- English localization is not part of the baseline scope unless explicitly added later.

## 2. Branch hierarchy

Implementation uses three levels:

```text
main
└── epic/<epic-id>-<epic-name>
    └── feature/<epic-id>-<epic-name>/<feature-name>
```

Examples:

```text
epic/00-foundation
feature/00-foundation/engine-preflight
feature/00-foundation/input-map
feature/00-foundation/audio-buses

epic/01-shell
feature/01-shell/main-menu
feature/01-shell/settings
feature/01-shell/player-controller
```

Rules:
- every epic has its own long-lived epic branch based on the latest stable `main`;
- every independently reviewable feature gets a dedicated feature branch based on its epic branch;
- feature branches merge into their parent epic branch only after validation for that feature;
- epic branches are synchronized with `main` before risky integration work when necessary;
- do not develop unrelated features directly on `main`;
- direct emergency fixes to `main` are allowed only when explicitly justified and documented.

## 3. Regular commits

Commits are required during work, not only at the end.

A commit should represent one coherent, reviewable state such as:
- scaffold added;
- one service implemented;
- one UI state completed;
- one bug fixed;
- one validation/test adjustment;
- documentation synchronized with an implementation change.

Avoid giant end-of-epic commits. Avoid placeholder commits that do not leave the branch in a comprehensible state.

Recommended commit style:

```text
feat: add Russian main menu shell
feat: implement input capture state handling
fix: restore mouse capture after focus return
test: add save corruption fallback checks
docs: update milestone status after engine validation
```

## 4. Regular integration into main

The owner must be able to observe meaningful progress from `main`.

Therefore:
- do not wait for an entire large epic to finish before updating `main`;
- merge/push stable, validated slices from the epic into `main` regularly;
- a main integration point must be runnable or at minimum preserve the previously runnable state;
- unfinished code may remain on feature/epic branches, but `main` must not knowingly receive broken intermediate work;
- after every main integration, update the relevant implementation/status document when project state materially changed.

Suggested cadence: integrate after each meaningful stable feature cluster or milestone checkpoint, not by elapsed clock time.

## 5. Validation before merge

Before feature → epic merge:
- inspect changed files;
- run the relevant Godot/editor/CLI validation that is available;
- verify no obvious parse/import errors;
- verify the feature's acceptance criteria;
- update documentation if behavior or architecture changed.

Before epic → main integration:
- run project smoke test;
- verify startup and the previously completed baseline path still works;
- confirm no canonical design constraint was changed;
- confirm player-facing new text is Russian;
- confirm no debug-only behavior is unintentionally exposed as release behavior.

If the environment cannot perform a required validation, the work is **not considered validated**. Record the blocker and pause the dependent merge.

## 6. No invention / stop-on-blocker rule

When required information, assets, permissions, tools, runtime capabilities or canonical decisions are missing, Astra must **pause the dependent task** instead of guessing.

Mandatory behavior:
1. identify exactly what is missing;
2. state which task/acceptance criterion is blocked;
3. preserve completed valid work;
4. do not fabricate substitute requirements, assets, narrative copy, licenses, measurements or successful test results;
5. resume only after the missing dependency is supplied or the owner explicitly approves an alternative.

Examples of pause conditions:
- exact Godot minor cannot be verified on the development environment;
- required executable/tool is unavailable;
- canonical text for a scene is absent or conflicting;
- a referenced asset is missing/corrupt;
- a licensing/provenance decision is required for shipping;
- profiling is requested but target hardware/runtime is unavailable;
- a merge would require claiming a test passed when it could not be run.

## 7. Source-of-truth precedence

When sources disagree, use this order:

1. latest explicit owner instruction;
2. master document v1.8 / approved later master revision;
3. repository canonical split docs referenced by `docs/design/PROJECT_BIBLE_INDEX.md`;
4. `docs/design/REQUIRED_ASSET_TABLE.md` and `docs/production/ASSET_INDEX.md`;
5. approved runtime policies and implementation plan;
6. concept art and visual references;
7. older historical documents.

Do not silently reconcile contradictions. If the higher-priority source does not resolve the issue, pause and request a decision.

## 8. Main branch visibility

Progress tracking must remain understandable from GitHub without needing the local Astra session.

For every stable integration into `main`, the repository should make it possible to determine:
- what was completed;
- what remains blocked/in progress;
- what was actually validated;
- which epic/feature produced the change;
- whether canonical scope changed (normally: no).

`docs/production/IMPLEMENTATION_PLAN.md` is the current high-level progress tracker.
