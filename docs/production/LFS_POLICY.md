# Git LFS policy

Status: **ACTIVE — forward-only 3D LFS policy**.

## Purpose

Use Git LFS for future heavy 3D binary assets without rewriting the existing repository history.

The repository already contains a large ordinary-Git WAV history. Rewriting that history is destructive, changes commit SHAs across refs and is not required for the next production step. Existing audio therefore remains ordinary Git unless a later maintenance task explicitly migrates or removes historical audio blobs.

## Tracked through LFS

Current `.gitattributes` tracks these future file types with Git LFS:

```text
*.blend
*.glb
*.fbx
```

These extensions were not present in the repository tree when this policy was introduced, so the policy does not create "should have been pointer" inconsistencies for existing files.

## Not currently tracked through LFS

Existing source/runtime audio remains ordinary Git:

```text
*.wav
*.flac
*.mp3
*.ogg
```

Concept/reference images and source documents also remain ordinary Git unless a later measured need justifies changing the policy.

## Required client setup

Any environment that commits or checks out LFS-backed 3D files must have a working Git LFS client:

```bash
git lfs version
git lfs install
```

Before the first real 3D binary is merged, the producing environment must prove:

```bash
git lfs ls-files
git lfs fsck
```

and a fresh checkout must retrieve the binary payload successfully.

## First-binary gate

The first `.blend`, `.glb` or `.fbx` feature is not considered validated until all of the following are confirmed:

- the committed Git blob is an LFS pointer, not the raw binary;
- the corresponding LFS payload upload succeeds;
- a fresh clone/check-out downloads the payload;
- the downloaded file opens/imports correctly in Blender/Godot as applicable;
- ordinary repository smoke tests still pass.

If the environment can create a pointer but cannot upload or retrieve the LFS payload, stop with BLOCKER and do not merge that binary feature.

## Existing audio history

The old destructive `git lfs migrate import --everything` plan is no longer a prerequisite for 3D production.

A future audio-history cleanup may still be worthwhile because the repository is already large, but it is a separate maintenance optimization, not a production gate. Such a task must measure retained/obsolete audio history before any rewrite and must preserve a recoverable backup plus fresh-clone validation.

## Rationale

This policy minimizes current risk:

- no force-rewrite of public history;
- no invalidation of existing clones merely to start 3D work;
- no unnecessary LFS storage use for obsolete historical WAV revisions;
- all new heavy 3D production files are prevented from further bloating ordinary Git history.

## First-binary evidence — 2026-09-22

Feature `feature/03-art-foundation/blender-export`, draft PR #15,
sample commit `b6bda309cd2e0a26553bb675515d2609dfa253b9`:

| Gate | Actual result |
| --- | --- |
| `.blend` and `.glb` attributes and committed pointers | PASS; exact SHA-256/size match local files |
| Authenticated LFS batch upload negotiation | PASS; HTTP 200 for both objects |
| Real payload upload and feature push | PASS; 2/2 objects, 452 KB |
| Full producing-clone `git lfs fsck` | PASS after missing ordinary-Git objects were restored |
| Fresh remote clone with independent empty LFS cache | PASS; both files initially pointers |
| `git lfs pull origin` in fresh clone | PASS on authorized retry after restoring remaining ordinary-Git HEAD blobs |
| Retrieved binaries, source reopen and runtime import | PASS; exact SHA-256/size match, Blender 4.5.14 reopen and Godot 4.7.2 import |
| Fresh-clone `git lfs fsck` and `git fsck --full --strict` | PASS, both exit 0 |
| First-binary technical acceptance | PASS; integration tracked separately |

The producing copies passed Blender 4.5.14 source checks and Godot 4.7.2 clean
import/startup/safe exit. Those local results do not replace retrieved-copy
validation. See `BLENDER_PREFLIGHT.md` and
[evidence/lfs_transfer_2026-09-22.log](evidence/lfs_transfer_2026-09-22.log).
Credentials are not stored in project files. The forward-only LFS scope remains
`.blend/.glb/.fbx`; ordinary audio history is unchanged.

The successful retry is recorded in
[evidence/lfs_retry_2026-09-22.log](evidence/lfs_retry_2026-09-22.log).
Startup, eight autoloads, safe exit, InputMap and audio-bus regression also
passed on the retrieved checkout. The earlier canceled pull is historical
failure evidence, superseded by these real transfer and retrieved-copy checks.

### Partial-clone ordering

A shallow partial clone is sufficient for independent payload validation if it
uses its own Git/LFS stores and has no object alternates or reference caches.
Keep LFS smudging disabled during clone/checkout; verify pointers and an empty
payload cache. In this repository, hydrate ordinary-Git HEAD blobs before
running LFS scans or pull so they cannot trigger lengthy implicit Git fetches:

```sh
# Run from the independent checkout with gh authentication and the tools in PATH.
python tools/hydrate_head_blobs.py --repo . --scratch /absolute/temporary-directory --jobs 4
git lfs pull origin
git lfs fsck
git fsck --full --strict
```

Unset `GIT_LFS_SKIP_SMUDGE` before the pull. Verify both retrieved files against
`evidence/lfs_sample_manifest.json` (relative to this document's directory),
then run the Blender/Godot commands in `EXPORT_SAMPLE.md`. Ordinary Git hydration
is not LFS retrieval and cannot substitute for the pull or payload checks.
