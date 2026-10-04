# Recovery at 2026-10-04 14:53 UTC

The reconnected execution environment contains an older filesystem. This is
observed source loss, not a requested rollback. No reset, existing-file overwrite,
LFS migration, old preflight or accepted gameplay rerun was performed.

## Preserved checkpoint and live state

The newest surviving complete pre-interruption archive is
`wlr-snapshot-20261003T232304708406Z.tar.gz`, started at
`2026-10-03T23:23:04.127057+00:00` (02:23:04 Europe/Moscow on October 4).
The archive's internal time establishes creation; the newer filesystem mtime of
the 23:19 archive does not establish a newer checkpoint. Verification recovered
both worktree HEADs and checked all 534 payloads.

All 225 saved worktree files match the current files: 58 in
`where-the-light-remains`, 167 in `wlr-art-integration`. Both status outputs are
empty; their HEADs remain `9e4a45b57e73f8757d707cbce5be0066186b24f3` and
`9ad6867a77bf68872651ad2362c5f7098c9404fb`. No Godot/Xvfb process was present.
No process was signaled. No staged/unstaged/untracked source was discarded.

The prior `wlr-reconstruction` checkout and its snapshot directory are absent.
The previously reported October 4 11:56–approximately 13:00 UTC snapshots cannot
be verified or used here. Library and prior-context recovery found no surviving
archive bytes. A new checkpoint of the surviving environment was created at
14:56:23 UTC and verified: 533 payloads and both original HEADs recoverable.
There is an actual gap in the available 15-minute checkpoint series; no missing
archive or automatic persistence is claimed.

## Completed versus unfinished work

The last historically confirmed feature was connected S02, source
`cc63a5f9e14917f271941f2afff8d42162a00a38`, integrated locally as `99bcfa3`:
24 commands, 208 source files unchanged, successful cleanup, Star/Hearth physical
slots and independent restore, nine reviewed Forward+ images. Its files and
receipts are absent now. These are retained historical results, not verification
of a reconstructed implementation.

The next unfinished command was an `apply_patch` adding the T019 gate/channel
scripts and ownership contract. Its completion was never observed. A subsequent
read-only recovery exec also had no retrievable result. The earlier exec failure
was `409 Conflict, environment_offline: Environment is not connected`, before
process creation, including `/bin/true` without a login shell. It was not an X11,
Godot, package or AF_UNIX failure. No old target test remains running.

## Continuation

A separate partial checkout reconstructs the exact published
`c6818057b96174172b59e29ca0fba187c698c904` commit and
`2da0a03b0d2664986c810f8f1e1cd52ec6f20975` tree. Selected ordinary text blobs
are individually verified against Git identities. Original checkout files,
ref identities and sparse absent paths remain untouched. Heavy art/LFS payloads
are not silently replaced, hydrated or deleted.

Continue the unfinished, independent T019 presentation components and test only
their new behavior. Integration with the missing newer ArchiveMain/Boot/fragment
controllers remains dependent on source recovery or explicitly labeled
reconstruction. Do not start S03 while `GATE-VS1` is open. Do not mark absent
historical source/evidence as currently verified. Snapshots of the live recovery
checkout continue every 15 minutes during active work, with actual times and
verification recorded.
