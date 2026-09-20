# Git LFS history migration

Status: **AUTHORIZED / ESCALATION CONFIRMED / BLOCKED ON GIT AUTHENTICATION**.

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

## Earlier authentication preflight (2026-09-20)

The following evidence is preserved from commit `c94d585`. The follow-up below
records the subsequent full-mirror preparation and current tool availability.

Rechecked on **2026-09-20**. Git and Git LFS are installed, and outbound GitHub Git/LFS access works. The remaining execution blocker is **local Git/LFS authentication for write access**. The earlier statement that Git LFS and outbound GitHub access were unavailable is superseded by the checks below.

The owner already confirmed the requested reasoning escalation in the preceding session. Do not request that confirmation again solely because the execution environment was restarted. This confirmation does not supply Git/LFS credentials.

### Checks actually performed

| Check | Observed result |
| --- | --- |
| `git --version` | `git version 2.51.1` |
| `git lfs version` | `git-lfs/3.4.1 (GitHub; linux amd64; go 1.22.2)` |
| `git ls-remote` against the repository | Succeeded; 15 branch refs, no tags; GitHub-managed PR refs were also advertised |
| Partial clone with `--filter=blob:none --no-checkout` | Succeeded; migration branch checked out with a sparse documentation worktree |
| Git push authentication, with terminal prompts disabled | `git push --dry-run` failed: `fatal: could not read Username for 'https://github.com': terminal prompts disabled` |
| LFS batch endpoint, empty upload negotiation | HTTP `401`, `Requires authentication`; no payload uploaded |
| Local credential configuration | No configured credential helper, `GIT_ASKPASS`, `GH_TOKEN`, `GITHUB_TOKEN`, or standard Git/GitHub CLI credential files found |
| Available disk at initial check | Approximately 26.46 GiB; full backup/rewrite disk requirement has not been validated |
| Godot availability in this session | `godot`/`godot4` absent from PATH; no matching binary found within the searched `/tmp`, `/opt`, and workspace paths (depth 4) |
| PR #10 | Open, draft; migration feature targets `epic/00-foundation` |

The push dry-run used the existing migration commit as its source and the existing migration branch as its destination. It did not update any ref. The empty LFS batch request tested reachability/authentication only; it is not an upload or retrieval acceptance test. GitHub connector access can preserve documentation changes, but its available operations do not provide a local Git credential or an LFS object-upload operation.

### Ref snapshot before this documentation update

These values were read from GitHub and the Git remote. This is a metadata snapshot, **not a recoverable backup** and not an old-to-new migration map.

| Branch | SHA |
| --- | --- |
| `main` | `06a83c7ff4b19a1af2765576b3286dfbfbc2cfa6` |
| `epic/00-foundation` | `d47c569e5e0735cec5e4879818d949520c04c172` |
| `epic/03-art-foundation` | `8636f7f847cecec7b7456e0b8a6c834c32a5de18` |
| `feature/00-foundation/lfs-history-migration` | `20a1cc5afb72d59851b2740696b8978d37a41ffe` |
| `feature/00-foundation/engine-preflight` | `c09ccedb406c9720194a810853c17a859cb0b0b2` |
| `feature/00-foundation/input-map` | `51834c47878e16d9ef8332c3bac1d3c8ae3576c9` |
| `feature/00-foundation/audio-buses` | `b1ccc5cd1d8efaf2b9459dc9a5aabfb5e3b2d70e` |
| `feature/03-art-foundation/pipeline-spec` | `ccc0e2153a3661b778c907adf27b88ab71e5b5f2` |
| `analysis/audio-audit` | `9b24bed118d59c22ca78f74edbf09c5cf16d69a3` |
| `analysis/audio-audit2` | `922ba3cf17515d246f4c28a9bd4f00e36be376ec` |
| `analysis/audio-audit3` | `922ba3cf17515d246f4c28a9bd4f00e36be376ec` |
| `analysis/audio-audit4` | `922ba3cf17515d246f4c28a9bd4f00e36be376ec` |
| `analysis/audio-reaudit` | `0eca934b28881e3cceb83fe0d9f76a889c1af37a` |
| `audio/curation-2026-09-19` | `66236f12c90f85dc8ddcb4c06592b26b07d21124` |
| `audio/final-pool-structure` | `57f86c20a5a81f107a1e0a7536e127b51f76ce1b` |

### Required to resume

1. Provide an execution environment with authenticated Git push and Git LFS upload access to this repository. Configure credentials through the environment's secure authentication mechanism; do not paste credentials into repository files or the conversation.
2. Make the approved Godot 4.7.2 executable available for mandatory post-migration import/startup/safe-exit validation. Previous engine-preflight evidence does not substitute for this fresh-clone check.
3. Fetch and compare all refs again, coordinate the write-freeze window, measure disk requirements, and create/verify a full recoverable backup before any history rewrite. This session's partial clone is not such a backup.
4. Resume the migration procedure above on the existing feature branch and PR #10.

No history rewrite, full backup verification, LFS payload upload, post-migration `fsck`, fresh-clone LFS retrieval, or Godot validation was performed in this recheck. All migration acceptance boxes remain unchecked. Under `ASTRA_WORKFLOW.md` and the owner's Phase A ordering, dependent Foundation/debug-tools work and bulk 3D production remain paused until LFS passes.

## Current blocker and full-mirror follow-up


The remaining execution blocker is **Git CLI authentication**. A non-mutating
push dry run to the existing migration branch fails because Git cannot obtain a
GitHub username/credential. The connected GitHub application can update ordinary
files and refs, but it does not provide an LFS payload-upload operation or export
its credentials to local Git.

The earlier tool/network blocker is partially resolved: Git 2.51.1 and Git LFS
3.4.1 run successfully, a complete unfiltered mirror was downloaded from GitHub,
and the LFS batch endpoint responds. An empty download batch returns HTTP 422
(`No objects specified`); this proves endpoint reachability only, not upload or
payload-download permission. GitHub CLI 2.101.0 was installed from its official
release with the release SHA-256 checked, to support interactive device login.

Read-only preparation is recorded in
[`evidence/lfs_preflight_2026-09-20.json`](evidence/lfs_preflight_2026-09-20.json):

- the mirror contains all 26 advertised refs (15 branches, 11 GitHub PR refs),
  68 reachable commits, no tags, no shallow boundary, no promisor packs, and no
  object alternates;
- `git fsck --full --strict` on the mirror returned 0 with no diagnostics;
- a separate sparse working checkout was restored from that mirror; its
  connectivity check passed. This working checkout shares objects with the
  mirror and must not be mistaken for a second independent backup;
- all 139 distinct target WAV Git blobs were streamed, SHA-256 hashed, and
  checked for RIFF/WAVE signatures: 5,021,937,862 bytes in total;
- the inventory found no existing LFS pointer blobs. Signature checks are not
  audio-quality/listening validation;
- the checksummed manifest stores original Git blob IDs, expected LFS SHA-256
  IDs, byte lengths, and representative historical paths. A path is an example
  for an object, not an exhaustive list of its renamed paths;
- the local mirror is a recovery copy for this workspace session. A durable
  independent copy and a fresh remote-ref snapshot are still required before
  updating any rewritten remote refs;
- no history rewrite, LFS payload upload, post-migration fresh clone, or
  post-migration Godot validation has occurred. The acceptance checklist remains
  unchecked, and PR #10 remains a draft.

## Execution details to preserve after authentication

1. Finish all preparation commits, refresh the mirror and ref snapshot, and
   coordinate a write freeze with the owner and other writers. An unchanged
   `ls-remote` observation alone is not a write freeze. Any unexpected ref
   movement requires another review before proceeding.
2. Keep the backup immutable and recoverable outside the rewrite directory.
   Recheck disk space for old Git objects, LFS payloads, and an independent fresh
   clone; the current unique source payload is about 4.68 GiB.
3. Materialize every retained production, feature, analysis and audio branch as
   a local branch in the migration workspace. `git lfs migrate --everything`
   scans remote-tracking refs but does not update those refs. Checking out only
   the migration branch is therefore insufficient to migrate every branch tip.
4. Preserve the exact eight target patterns above. Save the commit mapping with
   `git lfs migrate import --object-map=<evidence-path>` and compare each retained
   ref to the frozen snapshot. Verify all reachable target paths, not just the
   current worktree. Keep non-target file contents and modes unchanged.
5. Include GitHub-owned `refs/pull/*` in backup evidence, but never try to publish
   changes to that read-only namespace or use `git push --mirror`. These service
   refs can retain historical commits; migration does not guarantee immediate
   server-side repository-size reduction. Reassess PR #10 against the rewritten
   base and head before merging or replacing it.
6. Verify all required LFS payloads are present on GitHub before publishing
   pointer refs. Compare payload sizes and SHA-256 IDs against the original
   manifest. Publish only the explicitly enumerated branch/tag refs using
   explicit old-SHA leases and an atomic push; stop if the server cannot honor
   those protections.
7. Validate from a genuinely fresh clone of GitHub with no object alternates
   or borrowed LFS cache. Retrieve every required LFS object, validate all
   retained refs and real WAV payloads, then run the Godot 4.7.2 checks and
   asset-path checks from the procedure above. Do not mark PASS based on local
   pointers or a push exit code alone.

Git LFS reference for the installed version:
[git-lfs-migrate(1), v3.4.1](https://github.com/git-lfs/git-lfs/blob/v3.4.1/docs/man/git-lfs-migrate.adoc).
