# Development snapshots and remote checkpoints

Mandatory owner instruction, 2026-10-04. This supplements the local archive
tool; a local snapshot alone does not protect against environment replacement.
Working branch for the resumed T019 state:
`feature/04-archive-gameplay/checkpoints-2026-10-04`.

## Every 15 minutes of active work

1. Use the verified foreground `tools/session_snapshot.py` timer in a managed
   execution session, `--interval 900`, with the authorized UTC work deadline.
   Retain its session identity/output and inspect it after an interruption.
   Do not rely on the previously unverified detached-process approach.
2. Pause writers briefly for collection. Keep required in-progress logs in
   evidence or select them using `--extra-evidence`. Verify the new archive with
   `tools/verify_session_snapshot.py`; retain its time and SHA-256. A failed
   collection does not replace the last complete checkpoint. Resolve and retry
   promptly rather than silently skipping a timer tick.
3. After every snapshot inspect `git status`, unstaged and staged `git diff`,
   plus new files. Check the branch, credentials, sparse-path safety and exact
   validation scope. Use explicit paths when staging; sparse absence is not an
   intentional deletion. Do not commit archives, toolchain or credentials.
4. If coherent and not known broken, create a checkpoint commit and immediately
   run normal `git push origin HEAD:refs/heads/<working-branch>`. Verify that
   `git ls-remote origin refs/heads/<working-branch>` reports that exact SHA.
   A local commit or successful read alone is not proof of a remote backup.
5. Record UTC snapshot time, archive/hash, branch, checkpoint SHA, current stage,
   test status/source identity, push result and verified remote SHA in
   `docs/production/evidence/checkpoints/`. Capture complete sanitized command
   results. Store the push receipt in a following documentation commit and push
   it too; a commit cannot contain its own SHA. The receipt names the previously
   verified checkpoint, and the latest remote ref is the recovery entry point.

When a state temporarily fails tests, still snapshot it locally. Preserve the
failure and next action; do not call it stable or push it as a stable checkpoint.
An optional WIP commit must say `WIP` in its message and evidence and remains on
the same working branch. Never push WIP to `main`.

For unchanged source, reuse an accepted result only after comparing its exact
source and evidence hashes. Changed behavior requires its relevant tests before
a stable label. A completed logical stage gets a separate stable commit and
immediate push, even if the 15-minute tick is not yet due. Checkpoint operations
do not restart accepted environment preflights or unrelated completed tests.

The snapshot timer only creates archives; the coding agent must handle each
reported snapshot's review/commit/push immediately while monitoring that managed
session. Do not leave a timer unattended or claim it provides remote backups.
At a work-window deadline pause the unfinished stage, checkpoint its actual
state, report the last confirmed step and stop active work. No continuous
background timer is claimed between authorized work windows.

## Branch and recovery safety

Work on a dedicated feature/working branch, never directly on `main`. Check the
remote branch before the first push. If it already has a newer checkpoint,
retrieve and compare it first; do not replace it with an older archive or local
HEAD. Never use force-push, ref deletion, history/LFS rewrite or a `main` push as
part of checkpoint handling. Non-fast-forward rejection requires inspection
and safe integration, not forced publication.

After loss/disconnection, inspect surviving processes, files, `git status` and
logs first. Compare their state against the newest remote working-branch
checkpoint. Recover into a fresh checkout if required, preserving newer local
changes and evidence. Use a local archive as a comparison/recovery supplement,
not as authority over newer remote state. Determine the last completed test and
unfinished command; terminate only a proven hung process owned by that test.
Do not rerun accepted tests, roll back surviving changes, or restart stages.

A push/ref-verification failure is a durability blocker: preserve the local
snapshot/commit and exact redacted error. Do not claim remote safety or continue
a long development session without resolving that failure. Use previously
verified transport/toolchain paths before declaring an environment blocker.

Git commits back up tracked source and committed evidence. The archive's private
environment/toolchain, ignored files and uncommitted failing state are outside
that remote commit. Snapshot archives remain local unless separately exported;
their SHA/time in Git is a receipt, not an uploaded archive.

## Current acceptance boundary

The isolated T019 gate/channel stage is accepted at source
`d757a084c0773c9108f4d1fcbb95eb60bebf3dfd`: seven commands PASS, 163 materialized
source identities, 147 behavioral assertions and four inspected native images.
See `evidence/archive_route/README.md` and the current checkpoint receipts.
Only the isolated stage is stable; full ArchiveMain/Boot/S02 reconstruction and
T019 integration remain open. No old historical source is assigned new PASS.

The first remote checkpoint is
`127a7dfb832250575797ec474767069905459986`, verified on the working branch at
2026-10-04 17:01:19 UTC. Its complete local commit history was preserved by normal
Git push. The following receipt commits carry the actual transport/checkpoint
logs. Use the newest remote branch tip during later recovery.

In this environment, use the existing official gh 2.101.0 portable binary.
Authenticated `gh auth status`, `gh api user --jq .login` and repository push
permission passed for MindDevastation; `gh auth setup-git` enables Git's helper.
Supply GH_TOKEN through the session's private credential input/environment,
never a remote URL, repository file, command argument or evidence value.
The credential remains necessary in that process environment when the helper
has no persistent login. Do not interpret an anonymous read as write access.

The reconstructed partial clone initially lacked six small historical ordinary
blobs needed during packing. Restore requested objects using the already
documented `hydrate_head_blobs.py` method: immutable GitHub blob metadata,
byte length and Git SHA-1 verification, then `git hash-object -w --no-filters`.
Only the object cache changed. The checkpoint's 123-object incremental closure
above published c6818057 was already complete; no full asset hydration, file
replacement, history/LFS rewrite, missing-object suppression or hook bypass was
used. Exact failed attempts and restorations remain in checkpoint evidence.

The 16:38:05 to 16:53:36 UTC manual gap was 930.919423 seconds, exceeding the
900-second requirement by 30.919423 seconds. It is recorded as a cadence miss.
The verified foreground timer was then started and monitored for the remainder
of this checkpoint task. Start that timer at the beginning of future active
work, including recovery tasks that may exceed 15 minutes.
