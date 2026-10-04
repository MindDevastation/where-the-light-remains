# Remote development checkpoints

Owner instruction: `../../SESSION_CHECKPOINTS.md`.

The resumed work uses
`feature/04-archive-gameplay/checkpoints-2026-10-04`. The remote ref was absent
before preparation; the published Audio baseline and `main` identities are
recorded in `remote_before_2026-10-04.json`. Checkpoint pushes target only this
working branch and use ordinary fast-forward Git publication.

`accepted_state_2026-10-04.json` rechecks the exact accepted T019 state without
rerunning completed tests: 163 source hashes and 41 evidence payloads match,
all seven immutable command results remain PASS. Current new changes are
production policy and checkpoint evidence only. Full gameplay reconstruction
and T019 integration remain open.

`checkpoint_log.json` records snapshot identity, stage, source/test status and
checkpoint publication. A push receipt names the commit already verified on
the remote branch; its following documentation commit cannot include its own
SHA. Resolve the current remote ref for the newest recovery entry point.

A failed push or ref comparison is recorded as BLOCKER, never remote PASS.
Local archives preserve extra recovery state but are not themselves uploaded
by a Git source/evidence push. Credentials, Git configuration and private
runtime dependencies are excluded from both committed evidence and snapshots.
