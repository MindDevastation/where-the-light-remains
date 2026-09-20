# Git LFS history migration

Status: **AUTHORIZED / NOT YET EXECUTED**.

Owner authorization has been granted to rewrite the repository history so large source audio and future 3D binaries are stored through Git LFS rather than ordinary Git blobs.

This is a destructive repository-history operation. It must be executed only from `feature/00-foundation/lfs-history-migration` after the reasoning escalation in `ASTRA_WORKFLOW.md` has been satisfied.

## Hard gate

Before Astra executes any history rewrite it must emit:

```text
REASONING ESCALATION REQUIRED
Task: Git LFS history migration
Why High is insufficient: destructive rewrite changes commit SHAs across repository refs and can break clones/branches if validation is incomplete
Requested level: Extra High / highest available
Blocked work: LFS migration and bulk 3D binary production
```

Do not proceed until the owner confirms the reasoning-level switch.

## Why migration is required

The repository already contains large WAV source masters in ordinary Git history. Merely adding `filter=lfs` rules to `.gitattributes` does **not** migrate those existing blobs and can create inconsistent expectations between current files and future checkouts.

Bulk `.blend/.glb/.gltf/.fbx` production must not begin until the migration is actually validated.

## Target LFS patterns

Baseline patterns:

```gitattributes
*.wav   filter=lfs diff=lfs merge=lfs -text
*.flac  filter=lfs diff=lfs merge=lfs -text
*.mp3   filter=lfs diff=lfs merge=lfs -text
*.ogg   filter=lfs diff=lfs merge=lfs -text
*.blend filter=lfs diff=lfs merge=lfs -text
*.glb   filter=lfs diff=lfs merge=lfs -text
*.gltf  filter=lfs diff=lfs merge=lfs -text
*.fbx   filter=lfs diff=lfs merge=lfs -text
```

Do not migrate PNG/JPG concept references merely because they are binary unless a later measured repository-size decision explicitly adds them.

## Required environment

Do not start unless all of the following are true:
- authenticated Git write access to the repository;
- `git` available;
- `git-lfs` installed and `git lfs version` succeeds;
- outbound access to GitHub Git and LFS endpoints;
- enough local disk for a full clone plus rewritten objects;
- no concurrent uncoordinated pushes during the rewrite window.

If any prerequisite is missing: BLOCKER, no rewrite.

## Migration procedure

1. Fetch the latest `main`, all production branches, analysis branches and tags. Enumerate refs explicitly; do not assume the current branch list is complete.
2. Create a recoverable backup/mirror of all refs before rewriting anything.
3. Freeze repository writes for the short migration window.
4. Run `git lfs install` and add the target patterns with `git lfs track` or an equivalent verified `.gitattributes` change.
5. Commit the tracking rules on the migration branch before the history rewrite when practical.
6. Rewrite the required history with `git lfs migrate import`, covering every ref that must remain reachable. A typical command is:

```bash
git lfs migrate import --everything --include="*.wav,*.flac,*.mp3,*.ogg,*.blend,*.glb,*.gltf,*.fbx"
```

7. Re-enumerate refs and verify that intended branches/tags were rewritten. If any retained ref still points to ordinary large source blobs, stop and correct the migration before pushing.
8. Validate locally:

```bash
git lfs ls-files
git lfs fsck
git fsck
```

9. Push all required LFS objects to the remote **before** or as part of updating rewritten refs. Verify object upload succeeds; do not assume pointer commits imply uploaded LFS payloads.
10. Force-update rewritten branches/tags using the safest available mechanism (`--force-with-lease` where applicable). Do not overwrite a ref that moved unexpectedly during the freeze window.
11. Perform a completely fresh clone into a new directory.
12. Run `git lfs pull` in the fresh clone and verify representative WAV files are real audio payloads rather than pointer text.
13. Open/import `game/` with the verified Godot 4.7.2 baseline and rerun startup/safe-exit smoke validation.
14. Verify source asset paths and `ASSET_INDEX.md` references still resolve.
15. Record old→new critical commit/ref mapping and the final migration evidence in this document.
16. Notify the owner that existing local clones should be re-cloned or explicitly reset to the rewritten history.

## Acceptance criteria

The feature is PASS only when:
- [ ] all target retained refs were intentionally handled;
- [ ] target heavy source files are LFS pointers in Git history;
- [ ] corresponding LFS payloads are uploaded and retrievable;
- [ ] `git lfs fsck` passes;
- [ ] ordinary `git fsck` has no migration-introduced corruption;
- [ ] fresh clone + `git lfs pull` succeeds;
- [ ] representative music WAVs open correctly after fresh pull;
- [ ] Godot 4.7.2 imports/starts the project after fresh clone;
- [ ] branch/tag rewrite mapping is recorded;
- [ ] owner is warned that old clones are obsolete;
- [ ] `.gitattributes` is committed with final LFS rules;
- [ ] `IMPLEMENTATION_PLAN.md` marks the LFS gate complete only after all of the above.

## Current blocker

The current ChatGPT/GitHub connector path can edit Git refs/files but does not expose Git LFS object upload, and the local execution container available in this session has no `git-lfs` installation or outbound GitHub network access. Therefore this session cannot truthfully complete or validate the LFS object migration.

This is exactly a stop-on-blocker condition. The migration feature branch has been prepared for Astra, which must execute the rewrite in its authenticated git-lfs-capable environment.
