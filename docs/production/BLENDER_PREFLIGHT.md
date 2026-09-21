# Blender and toolchain preflight

Date: 2026-09-21. Feature: `feature/03-art-foundation/blender-export`.
Base: `349dd3a6755ce8d6e12513181223013e9d585700` (main and Art Foundation).

**Local tool preflight: PASS. Production export/LFS feature: BLOCKED.**

## Installed and actually exercised

| Tool | Verified version | Result |
| --- | --- | --- |
| Godot standard | 4.7.2.stable.official.ed1daf0bf | Version, clean import and eight-autoload/startup/safe-exit smoke PASS |
| Blender | 4.5.14 LTS, build 62c1db4208e8 | Background CLI, embedded Python, source save and built-in GLB exporter PASS |
| GitHub CLI | 2.101.0 | Executable works; authentication BLOCKED |
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

## Remaining authentication blocker

- `test -n "$GH_TOKEN"`: exit 1, value never printed.
- `gh auth status`: exit 1, `You are not logged into any GitHub hosts.`
- `gh api user --jq .login`: exit 4, authentication required.
- `git push --dry-run origin HEAD:refs/heads/feature/03-art-foundation/blender-export`:
  exit 128, `fatal: could not read Username for 'https://github.com': terminal prompts disabled`.

Public Git fetch works and the authorized GitHub connection can preserve text
commits. Neither proves authenticated Git/LFS payload access. `gh auth setup-git`
is deferred until CLI authentication succeeds. Supply credentials through the
environment's secret configuration, never through committed files or chat.

The production first-binary gate remains blocked: no LFS pointer/payload upload,
fresh-clone retrieval, retrieved-source opening or retrieved-GLB Godot import
has been claimed. No history rewrite, WAV migration, pipeline scope or
performance-budget change was performed. Art Foundation/main receive no binary
feature merge until all required gates pass.

Reasoning assessment: High is sufficient for the completed installation and
routine CLI probe. Cross-project pipeline design, modular architecture and
nontrivial Blender automation still require the owner's Extra High escalation
under `ASTRA_WORKFLOW.md`.
