# Blender and toolchain preflight

Date: 2026-09-21. Feature: `feature/03-art-foundation/blender-export`.
Base: `349dd3a6755ce8d6e12513181223013e9d585700` (main and Art Foundation).

**Local tools, full local LFS fsck and first payload upload: PASS. Fresh-clone retrieval: BLOCKED (2026-09-22).**

## Installed and actually exercised

| Tool | Verified version | Result |
| --- | --- | --- |
| Godot standard | 4.7.2.stable.official.ed1daf0bf | Version, clean import and eight-autoload/startup/safe-exit smoke PASS |
| Blender | 4.5.14 LTS, build 62c1db4208e8 | Background CLI, embedded Python, source save and built-in GLB exporter PASS |
| GitHub CLI | 2.101.0 | Authentication and repository push permission PASS; see follow-up below |
| Git LFS | 3.4.1 | Client works; `git lfs install --local` succeeded |

Executables on this validation environment:

```text
/workspace/scratch/4f0b36b4bb0e/toolchain/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
/workspace/scratch/4f0b36b4bb0e/toolchain/blender-4.5.14-linux-x64/blender
/workspace/scratch/4f0b36b4bb0e/toolchain/gh_2.101.0_linux_amd64/bin/gh
/usr/bin/git-lfs
```

Local links live under `/workspace/scratch/4f0b36b4bb0e/toolchain/bin/`.
The working environment is transient; these installation paths are not a
claim that tools survive environment recreation.

## Recreate the tools

Use a writable local prefix, outside the Git worktree. The bootstrap requires
Linux x86_64, Python 3.12+, curl, Git and Git LFS. It downloads pinned official
archives, verifies SHA-256, extracts regular tar members via size-checked atomic
replacement, and runs each executable's version command. It does not install
system packages or configure credentials.

```sh
python tools/setup_linux_toolchain.py --prefix /absolute/writable/toolchain
export PATH="/absolute/writable/toolchain/bin:$PATH"
git lfs install --local
```

Official download/checksum sources:

- [Blender 4.5 releases](https://download.blender.org/release/Blender4.5/),
  [4.5.14 checksums](https://download.blender.org/release/Blender4.5/blender-4.5.14.sha256).
- [Godot 4.7.2 release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable).
- [GitHub CLI 2.101.0 checksums](https://github.com/cli/cli/releases/download/v2.101.0/gh_2.101.0_checksums.txt).

| Archive | SHA-256 |
| --- | --- |
| Godot_v4.7.2-stable_linux.x86_64.zip | cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4 |
| blender-4.5.14-linux-x64.tar.xz | 9ba871ff2ecd36526b77432745980b7e6664ecd0c7ca11c48849073dcfe06da3 |
| gh_2.101.0_linux_amd64.tar.gz | 9bca2d1c16825f109907a23307628a2f0698fbf99662b73a5cf0b020293072b8 |

The initial Blender extraction produced incomplete files and `SIGBUS` (exit
135). Atomic replacement from the verified archive repaired them. The final
bootstrap and Blender probe both completed successfully. System-wide install
was unavailable, so the tools use the writable local prefix.

## Actual CLI/exporter probe

```sh
blender --background --factory-startup --python-exit-code 1 \
  --python tools/blender_cli_probe.py -- /absolute/new/disposable-directory
```

The script creates a disposable one-meter cube with unit object scale, UVs and
one material, saves `.blend`, exports GLB and validates the GLB 2.0 header,
mesh/material counts, normals and texture coordinates. The real run exited 0.
The output directory must not already exist. This is an installation probe,
not a production asset, visual acceptance test or complete export contract.
No binary from this probe is committed.

See [actual preflight output](evidence/blender_preflight_2026-09-21.log).

## Initial authentication blocker (resolved)

- `test -n "$GH_TOKEN"`: exit 1, value never printed.
- `gh auth status`: exit 1, `You are not logged into any GitHub hosts.`
- `gh api user --jq .login`: exit 4, authentication required.
- `git push --dry-run origin HEAD:refs/heads/feature/03-art-foundation/blender-export`:
  exit 128, `fatal: could not read Username for 'https://github.com': terminal prompts disabled`.

These failures describe the initial environment. In the subsequent authorized
credential run, `gh auth status`, `gh api user --jq .login`, `git ls-remote origin`,
`gh auth setup-git`, the repository permissions API and Git push dry-run passed.
The account was `MindDevastation`; repository pull/push permissions were true.
The authenticated LFS upload batch returned HTTP 200 for a real local GLB's
OID/size. This confirms upload negotiation only, not a payload transfer.

## Partial-clone object availability

The Git 2.51.1 / Git LFS 3.4.1 checkout uses `remote.origin.promisor=true` and
`remote.origin.partialclonefilter=blob:none`. An unqualified LFS scan first
failed on absent small Git blobs. A bounded fetch with
`--refetch --filter=blob:limit=65536` supplied small pointer candidates and
attribute files. With implicit Git blob downloads disabled for diagnosis,
`GIT_NO_LAZY_FETCH=1 git lfs ls-files` completed successfully.

The earlier full `git lfs fsck` was **BLOCKED**. Its revision enumeration
requires another ordinary-Git object, and without disabling lazy fetch it
starts downloading large ordinary audio objects. The diagnostic run reported:

```text
Error in `git rev-list --objects --no-walk --stdin --`: exit status 128
fatal: missing blob object '3e54de115c69de8539ce81d02dcd1930172556f1'
```

`git ls-tree -r HEAD` maps that object to
`assets/audio/music/A_Archive/shared/Activation Sequence.wav`.
This is an unmaterialized promisor blob, not evidence that the remote WAV is
corrupt or that it should be migrated to LFS. A complete shallow-clone transfer
was attempted and manually stopped while still downloading; it is not a
successful fresh-clone validation. No checks were marked PASS by excluding
the problematic file. The stopped transfer and scan left the published feature
unchanged.

The local technical sample passed Blender source reopen and Godot scale/pivot/
normal/UV/material import checks in the preceding environment, but that
uncommitted sample was lost when the environment was recreated. It is not
present in this PR and is not evidence of remote payload availability.

A repair on 2026-09-21 restored 97 missing Git blobs and the unqualified
`git lfs fsck` passed. The environment reset before that local commit reached
GitHub, so the tools and verified recovery were repeated on 2026-09-22. This run restored 107 missing blobs (1,110,877,466 bytes); all 179 HEAD blobs became available. Unqualified `git lfs fsck` and `git fsck --connectivity-only` exited 0. See [actual repair output](evidence/partial_clone_repair_2026-09-22.log).

`tools/hydrate_head_blobs.py` retrieves missing ordinary-Git HEAD blobs from
public raw URLs pinned to the exact commit. It checks immutable GitHub tree
metadata, origin, disk space, each Git blob SHA-1 and byte length before
`git hash-object -w --no-filters`. It checks refs again at completion. This does
not change history or working files and does not retrieve LFS payloads.

```sh
python tools/hydrate_head_blobs.py --repo /absolute/repository --scratch /absolute/temporary-directory --jobs 4
git lfs fsck
```

The first-binary gate requires a real LFS payload upload and independent clone
retrieval, followed by Blender/Godot checks. Upload negotiation alone remains
insufficient. The minimal test fixture uses a one-meter cube with bottom-center
pivot, identity object transforms, outward normals, one UV layer and one neutral
material. Its script-free Godot wrapper is separate from imported geometry.

Reasoning assessment: High is sufficient for the completed installation and
routine CLI probe. Cross-project pipeline design, modular architecture and
nontrivial Blender automation still require the owner's Extra High escalation
under `ASTRA_WORKFLOW.md`.

## First real payload upload and current retrieval blocker

Sample commit: `b6bda309cd2e0a26553bb675515d2609dfa253b9`.
Actual source/export checks: Blender source reopen, GLB Godot clean import,
scale/Y-up/pivot/normals/UV/material check and startup/eight-autoload/safe-exit
all PASS. See [local output](evidence/lfs_local_export_2026-09-22.log) and
[fixture scope](EXPORT_SAMPLE.md).

Both files are exact LFS pointers in Git. Their SHA-256 IDs and sizes are in
[evidence/lfs_sample_manifest.json](evidence/lfs_sample_manifest.json).
Authenticated upload negotiation returned HTTP 200 for both objects. The real
Git push reported `Uploading LFS objects: 100% (2/2), 452 KB` and updated the
feature ref. Full local `git lfs fsck` also passed after upload.

A separate HTTPS shallow partial clone at the sample commit succeeded with
smudging disabled. It has no Git object alternates, no LFS reference directory
and its own empty LFS object store. Both working files were verified as pointers
before the pull. Empty hash-prefix directories were initially misclassified by
the validation guard; inspection confirmed there were no cached payload files.

**BLOCKER:** `git lfs pull origin` produced no output or completion by 184.6
seconds. The wrapper's 180-second timeout did not terminate the remaining
session, which was then explicitly interrupted (exit 130). Both files remained
pointers and the fresh LFS cache contained zero payload files. No HTTP status
or endpoint-specific error was returned, so the network/transfer root cause is
not established. Do not infer successful retrieval from the successful upload.

See [transfer and fresh-clone evidence](evidence/lfs_transfer_2026-09-22.log).
Retrieved-copy Blender/Godot checks and fresh-clone fsck were not reached.
The first-binary gate remains BLOCKED; PR #15 stays draft and is not merged.
Next: diagnose the stalled LFS download in an execution environment that can
complete it, then repeat independent payload SHA-256, Blender/Godot and fsck
validation before integration. No destructive migration or WAV rewrite.
