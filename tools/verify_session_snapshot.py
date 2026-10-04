#!/usr/bin/env python3
"""Verify archive payloads and recovery in temporary repositories only."""

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile

sys.dont_write_bytecode = True


def git(repo, *args, data=None):
    return subprocess.check_output(["git", "-C", str(repo), *args], input=data, stderr=subprocess.DEVNULL)


def unpack_and_verify(archive, destination):
    with tarfile.open(archive) as reader:
        reader.extractall(destination, filter="data")
    manifest = json.loads((destination / "manifest.json").read_text())
    actual = {str(path.relative_to(destination)) for path in destination.rglob("*") if path.is_file()}
    assert actual == set(manifest) | {"manifest.json"}, "manifest coverage mismatch"
    for name, record in manifest.items():
        path = destination / name
        with path.open("rb") as handle:
            digest = hashlib.file_digest(handle, "sha256").hexdigest()
        assert path.stat().st_size == record["bytes"] and digest == record["sha256"], "payload checksum mismatch"
    return json.loads((destination / "state.json").read_text()), len(manifest)


def fixture_roundtrip(snapshot):
    with tempfile.TemporaryDirectory(prefix="snapshot-roundtrip-") as directory:
        root = Path(directory)
        source, output = root / "source", root / "snapshots"
        source.mkdir()
        git(source, "init")
        git(source, "config", "user.name", "Snapshot Test")
        git(source, "config", "user.email", "snapshot@example.invalid")
        (source / "edited.txt").write_text("baseline\n")
        (source / "deleted.txt").write_text("to delete\n")
        git(source, "add", ".")
        git(source, "commit", "-m", "baseline")
        head = git(source, "rev-parse", "HEAD")
        (source / "edited.txt").write_text("staged version\n")
        git(source, "add", "edited.txt")
        (source / "edited.txt").write_text("unstaged version\n")
        (source / "deleted.txt").unlink()
        (source / "new.txt").write_text("retained untracked evidence\n")
        before = git(source, "status", "--porcelain=v1", "-z")
        archive = snapshot(source, output, [])
        extracted = root / "extracted"
        extracted.mkdir()
        state, _ = unpack_and_verify(archive, extracted)
        assert state["history"]["complete"]
        rebuilt = root / "rebuilt"
        subprocess.check_call(["git", "clone", "-q", str(extracted / "repository.bundle"), str(rebuilt)])
        git(rebuilt, "apply", "--index", str(extracted / "worktrees/0/staged.patch"))
        git(rebuilt, "apply", str(extracted / "worktrees/0/unstaged.patch"))
        shutil.copyfile(extracted / "worktrees/0/files/new.txt", rebuilt / "new.txt")
        assert git(rebuilt, "rev-parse", "HEAD") == head
        assert git(rebuilt, "status", "--porcelain=v1", "-z") == before
        assert (rebuilt / "edited.txt").read_text() == "unstaged version\n"
        assert git(source, "status", "--porcelain=v1", "-z") == before
        print("PASS: bundle roundtrip preserves HEAD, staged/unstaged edits, deletion and untracked evidence; source unchanged")
        link = source / "unsafe-link"
        link.symlink_to(root / "foreign.txt")
        (root / "foreign.txt").write_text("foreign input\n")
        try:
            snapshot(source, output, [])
        except RuntimeError as error:
            assert "symlink" in str(error)
        else:
            raise AssertionError("symlink accepted")
        link.unlink()
        (source / "blocked.txt").write_bytes(b"github_pat_" + b"X" * 80)
        try:
            snapshot(source, output, [])
        except RuntimeError as error:
            assert "credential pattern" in str(error)
        else:
            raise AssertionError("credential accepted")
        assert len(list(output.glob("*.tar.gz"))) == 1 and not list(output.glob("*.partial"))
        print("PASS: unsafe inputs refused; last complete archive retained; no incomplete archive published")
        (source / "blocked.txt").unlink()
        import datetime as dt
        deadline = (dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=1.8)).isoformat()
        runner = subprocess.run([
            sys.executable, str(Path(__file__).with_name("session_snapshot.py")),
            "--repo", str(source), "--output", str(root / "scheduled"),
            "--interval", "1", "--until", deadline,
        ], capture_output=True, text=True, check=True)
        records = [json.loads(line) for line in runner.stdout.splitlines()]
        passes = [record for record in records if record["status"] == "PASS"]
        assert len(passes) == 2 and records[-1]["status"] == "PAUSED"
        gap = (dt.datetime.fromisoformat(passes[1]["utc"]) - dt.datetime.fromisoformat(passes[0]["utc"])).total_seconds()
        assert 0.8 <= gap <= 1.6
        print("PASS: local timer produces successive checkpoints and pauses at the UTC deadline")


def verify_archive(archive):
    with tempfile.TemporaryDirectory(prefix="snapshot-verify-") as directory:
        root = Path(directory)
        extracted = root / "extracted"
        extracted.mkdir()
        state, count = unpack_and_verify(archive, extracted)
        rebuilt = root / "git-recovery"
        subprocess.check_call(["git", "init", "--bare", "-q", str(rebuilt)])
        if state["history"]["mode"] == "verified_bundle":
            git(rebuilt, "bundle", "verify", str(extracted / "repository.bundle"))
            git(rebuilt, "fetch", str(extracted / "repository.bundle"), "refs/*:refs/*")
        else:
            shutil.copytree(extracted / "available_git_objects", rebuilt / "objects", dirs_exist_ok=True)
            for line in (extracted / "refs.txt").read_text().splitlines():
                sha, ref = line.split(" ", 1)
                git(rebuilt, "update-ref", ref, sha)
        for worktree in state["worktrees"]:
            assert git(rebuilt, "cat-file", "-t", worktree["head"]).strip() == b"commit"
        print(f"PASS: actual archive has {count} verified payloads; all {len(state['worktrees'])} worktree HEAD objects recoverable; history mode={state['history']['mode']}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--fixture", action="store_true")
    args = parser.parse_args()
    if not args.archive and not args.fixture:
        parser.error("select --archive and/or --fixture")
    if args.fixture:
        path = Path(__file__).with_name("session_snapshot.py")
        spec = importlib.util.spec_from_file_location("session_snapshot", path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        fixture_roundtrip(module.snapshot)
    if args.archive:
        verify_archive(args.archive.resolve())


if __name__ == "__main__":
    main()
