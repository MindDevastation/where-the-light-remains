# Compact checkpoints against a verified remote baseline

Use `tools/durable_checkpoint.py --snapshot-mode remote-delta` during live
development of this repository. Keep its supervised interval at 600 seconds
to leave room for an ordinary commit, LFS upload and independent remote check
before the 900-second maximum. The existing `available` mode remains available
for a complete collection of locally cached history/materialized files.

The compact mode requires the current HEAD to exactly match the current
working branch on `origin` before collection. Publish a new branch or any
existing local commits normally first. It checks the remote before and after
collection, and never force-pushes. One source worktree is currently supported.

Each archive stores the exact remote URL/ref/SHA, staged and unstaged binary
patches, deletions and changed materialized files, including new/changed LFS
source payloads.
When a staged LFS pointer differs from its working file, its actual cached
payload is preserved separately and restored into the new checkout's own LFS
store. A missing unpublished staged object blocks collection. An unchanged
baseline object may instead require ordinary remote hydration.
It includes paths with a staged change that has been reverted
in the worktree, even when their net difference from HEAD is zero. All archive
payloads are independently decompressed and checked against the SHA-256
manifest before publication. Credential files/patterns and symlinks are refused.

The coordinator then commits and pushes the affected source/evidence normally,
including the Git LFS pre-push hook, independently resolves the remote ref, and
publishes its ordinary checkpoint receipt commit. Intermediate checkpoints stay
marked WIP. Stable checkpoints still require current hash-bound PASS evidence.

Example using an already configured private credential in the current process:

```bash
python -B tools/durable_checkpoint.py \
  --repo . --output /absolute/scratch/checkpoints \
  --branch feature/04-archive-gameplay/resume-2026-10-06 \
  --interval 600 --snapshot-mode remote-delta
```

The existing private `--credential-stdin` flow may be used instead. Stop the
owned coordinator with `{"op":"stop"}` on its control input when the live turn
ends. A stopped process is not a future automation or background-development
promise.

Create, inspect or restore a local delta explicitly:

```bash
python -B tools/remote_delta_snapshot.py --create /absolute/scratch/checkpoints
python -B tools/remote_delta_snapshot.py --verify /absolute/archive.tar.gz
python -B tools/remote_delta_snapshot.py --restore /absolute/archive.tar.gz \
  --destination /absolute/new-checkout
```

Restore pins the recorded SHA even if the remote branch has advanced. It requires
a new destination, fetches the baseline, recovers staged/unstaged state and
compares the recovered status. Existing baseline LFS objects must be hydrated
from their recorded repository before running the game. This is a compact
remote-dependent recovery artifact, not an offline backup of all game assets
or Git history. The GitHub checkpoint commit remains the durable source of truth.

`tools/test_remote_delta_snapshot.py` verifies actual recovery of a baseline
after the remote advances, staged/unstaged text and LFS binary, deletion, rename,
paths with spaces, zero-net changes, and untracked data. An unchanged 2 MiB file
is excluded from the archive. It also exercises actual coordinator commit/push/
receipt verification against a local bare remote and refusal of stale baselines,
credentials, symlinks and existing recovery folders. The original offline/full
archive and coordinator fixtures are separately retained and checked.
