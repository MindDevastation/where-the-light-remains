#!/usr/bin/env python3
"""Local, read-only source/evidence checkpoints; never capture Git config or env."""

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile
import time


UTC = dt.timezone.utc
CREDENTIAL = re.compile(rb"(?:github_pat_|gh[pousr]_)[A-Za-z0-9_]{20,}")
PRIVATE_NAMES = {".env", ".netrc", ".git-credentials", "export_credentials.cfg"}


def stamp():
    return dt.datetime.now(UTC).isoformat()


def git(repo, *args):
    env = dict(os.environ, GIT_NO_LAZY_FETCH="1", GIT_LFS_SKIP_SMUDGE="1")
    result = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, env=env)
    if result.returncode:
        diagnostic = CREDENTIAL.sub(b"[REDACTED]", result.stderr)
        token = os.environ.get("GH_TOKEN")
        if token:
            diagnostic = diagnostic.replace(token.encode(), b"[REDACTED]")
        diagnostic = re.sub(rb"https?://[^\s/]*@", b"https://[REDACTED]@", diagnostic)
        raise RuntimeError(f"git {args[0]} failed with exit {result.returncode}: " + diagnostic.decode(errors="replace").strip())
    return result.stdout


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def copy_checked(source, target, expected_hash=None):
    if source.name in PRIVATE_NAMES or source.name.startswith(".env."):
        raise RuntimeError("credential file selected; snapshot refused")
    if source.is_symlink():
        raise RuntimeError("snapshot refuses symlinks; select a regular source explicitly")
    before = source.stat()
    if not source.is_file():
        raise RuntimeError("snapshot input is not a regular file")
    target.parent.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha256()
    tail = b""
    with source.open("rb") as reader, target.open("xb") as writer:
        while chunk := reader.read(1024 * 1024):
            if CREDENTIAL.search(tail + chunk):
                raise RuntimeError("credential pattern in input; snapshot refused")
            tail = chunk[-256:]
            digest.update(chunk)
            writer.write(chunk)
    after = source.stat()
    if (before.st_size, before.st_mtime_ns, before.st_ino) != (
        after.st_size, after.st_mtime_ns, after.st_ino
    ):
        raise RuntimeError("source changed during snapshot; retry after writer completes")
    if expected_hash and digest.hexdigest() != expected_hash:
        raise RuntimeError("LFS cache object checksum mismatch")
    os.chmod(target, before.st_mode & 0o777)


def worktrees(repo):
    records = git(repo, "worktree", "list", "--porcelain", "-z").split(b"\0\0")
    roots = []
    for record in records:
        fields = record.split(b"\0")
        entry = next((f[9:] for f in fields if f.startswith(b"worktree ")), None)
        if entry is not None:
            roots.append(Path(os.fsdecode(entry)).resolve())
    return roots


def identity(repo):
    return {
        "head": git(repo, "rev-parse", "HEAD").decode().strip(),
        "branch": git(repo, "rev-parse", "--abbrev-ref", "HEAD").decode().strip(),
        "status_sha256": hashlib.sha256(git(repo, "status", "--porcelain=v1", "-z")).hexdigest(),
    }


def capture_history(repo, stage, mode):
    """Preserve partial-clone objects without fetching or modifying the source."""
    failure = None
    if mode != "available":
        try:
            git(repo, "bundle", "create", str(stage / "repository.bundle"), "--all")
            git(repo, "bundle", "verify", str(stage / "repository.bundle"))
            return {"mode": "verified_bundle", "complete": True}
        except RuntimeError as error:
            if mode == "bundle":
                raise
            failure = str(error)
            (stage / "repository.bundle").unlink(missing_ok=True)
    object_root = Path(os.fsdecode(git(repo, "rev-parse", "--path-format=absolute", "--git-path", "objects")).strip())
    if (object_root / "info" / "alternates").exists():
        raise RuntimeError("external alternate object store needs an explicit backup path")
    for path in sorted(object_root.rglob("*")):
        relative = path.relative_to(object_root)
        if re.fullmatch(r"[0-9a-f]{2}/[0-9a-f]{38}", relative.as_posix()) or re.fullmatch(
            r"pack/pack-[0-9a-f]{40}\.(?:pack|idx|promisor)", relative.as_posix()
        ):
            copy_checked(path, stage / "available_git_objects" / relative)
    (stage / "refs.txt").write_bytes(git(repo, "show-ref"))
    return {"mode": "available_objects", "complete": False, "bundle_failure": failure,
            "limitation": "Preserves the existing local object cache only; missing promisor objects still need hydration from the original repository."}


def snapshot(repo, output, extras, history_mode="auto"):
    output.mkdir(parents=True, exist_ok=True)
    roots = worktrees(repo)
    if any(output == root or root in output.parents for root in roots):
        raise RuntimeError("snapshot output must be outside all source worktrees")
    if shutil.disk_usage(output).free < 1024 ** 3:
        raise RuntimeError("less than 1 GiB free space; snapshot paused")
    started = stamp()
    before = {str(root): identity(root) for root in roots}
    refs = git(repo, "show-ref")
    with tempfile.TemporaryDirectory(prefix=".snapshot-", dir=output) as temporary:
        stage = Path(temporary)
        history = capture_history(repo, stage, history_mode)
        metadata = {"started_utc": started, "worktrees": [], "lfs_cached_objects": 0, "history": history}
        for number, root in enumerate(roots):
            destination = stage / "worktrees" / str(number)
            destination.mkdir(parents=True)
            paths = sorted(set(git(root, "ls-files", "--cached", "--others", "--exclude-standard", "-z").split(b"\0")))
            deleted = []
            for encoded in paths:
                if not encoded:
                    continue
                relative = Path(os.fsdecode(encoded))
                if relative.is_absolute() or ".." in relative.parts:
                    raise RuntimeError("unsafe worktree path")
                if any(part in PRIVATE_NAMES or part.startswith(".env.") for part in relative.parts):
                    raise RuntimeError("credential file selected; snapshot refused")
                source = root / relative
                if not source.exists() and not source.is_symlink():
                    deleted.append(str(relative))
                    continue
                copy_checked(source, destination / "files" / relative)
            for name, args in [
                ("status.porcelain", ("status", "--porcelain=v1", "-z")),
                ("unstaged.patch", ("diff", "--binary", "--no-ext-diff")),
                ("staged.patch", ("diff", "--cached", "--binary", "--no-ext-diff")),
                ("index.entries", ("ls-files", "--stage", "-z")),
                ("index.flags", ("ls-files", "-v", "-z")),
            ]:
                data = git(root, *args)
                if CREDENTIAL.search(data):
                    raise RuntimeError("credential pattern in diff; snapshot refused")
                (destination / name).write_bytes(data)
            metadata["worktrees"].append({"id": number, "original_path": str(root), **before[str(root)], "absent_files": deleted})
        common = Path(os.fsdecode(git(repo, "rev-parse", "--git-common-dir")).strip())
        if not common.is_absolute():
            common = repo / common
        cache = common.resolve() / "lfs" / "objects"
        if cache.is_dir():
            for source in sorted(cache.rglob("*")):
                if source.is_file() and re.fullmatch(r"[0-9a-f]{64}", source.name):
                    copy_checked(source, stage / "lfs_objects" / source.relative_to(cache), source.name)
                    metadata["lfs_cached_objects"] += 1
        for number, source in enumerate(extras):
            source = source.resolve()
            if ".git" in source.parts:
                raise RuntimeError("Git internals cannot be selected as extra evidence")
            if source.is_dir():
                for path in sorted(source.rglob("*")):
                    if path.is_file() or path.is_symlink():
                        if ".git" in path.parts:
                            raise RuntimeError("Git internals cannot be selected as extra evidence")
                        copy_checked(path, stage / "extra_evidence" / str(number) / path.relative_to(source))
            else:
                copy_checked(source, stage / "extra_evidence" / str(number) / source.name)
        if refs != git(repo, "show-ref") or before != {str(root): identity(root) for root in roots}:
            raise RuntimeError("Git state changed during snapshot; retry after writer completes")
        metadata["finished_utc"] = stamp()
        metadata["scope"] = "All local Git ref identities, materialized nonignored files in all worktrees, selected extra evidence, available LFS cache; Git history coverage is recorded separately. No Git config, environment, ignored toolchain or remote publication."
        metadata["consistency"] = "Read-only collection interval, not an atomic filesystem image; pause concurrent writers for a recovery checkpoint."
        write_json(stage / "state.json", metadata)
        manifest = {}
        for path in sorted(stage.rglob("*")):
            if path.is_file():
                with path.open("rb") as handle:
                    digest = hashlib.file_digest(handle, "sha256").hexdigest()
                manifest[str(path.relative_to(stage))] = {"bytes": path.stat().st_size, "sha256": digest}
        write_json(stage / "manifest.json", manifest)
        name = "wlr-snapshot-" + dt.datetime.now(UTC).strftime("%Y%m%dT%H%M%S%fZ") + ".tar.gz"
        partial = output / (name + ".partial")
        target = output / name
        try:
            with tarfile.open(partial, "w:gz") as archive:
                for path in sorted(stage.iterdir()):
                    archive.add(path, arcname=path.name)
            with partial.open("rb") as handle:
                os.fsync(handle.fileno())
            with partial.open("rb") as handle:
                digest = hashlib.file_digest(handle, "sha256").hexdigest()
            partial.rename(target)
            (output / (name + ".sha256")).write_text(digest + "  " + name + "\n")
        finally:
            partial.unlink(missing_ok=True)
        return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--extra-evidence", type=Path, action="append", default=[])
    parser.add_argument("--until", help="UTC/session deadline as ISO 8601; omit for one checkpoint")
    parser.add_argument("--interval", type=int, default=900)
    parser.add_argument("--history", choices=("auto", "bundle", "available"), default="auto")
    options = parser.parse_args()
    if options.interval < 1:
        parser.error("interval must be positive")
    repo, output = options.repo.resolve(), options.output.resolve()
    deadline = dt.datetime.fromisoformat(options.until.replace("Z", "+00:00")) if options.until else None
    if deadline and deadline.tzinfo is None:
        parser.error("deadline must include timezone")
    due = time.monotonic()
    while deadline is None or dt.datetime.now(UTC) < deadline:
        try:
            target = snapshot(repo, output, options.extra_evidence, options.history)
            print(json.dumps({"utc": stamp(), "status": "PASS", "archive": str(target)}), flush=True)
        except Exception as error:
            print(json.dumps({"utc": stamp(), "status": "BLOCKER", "reason": str(error)}), flush=True)
            return 1
        if deadline is None:
            return 0
        due += options.interval
        while time.monotonic() < due and dt.datetime.now(UTC) < deadline:
            time.sleep(min(30, max(0, due - time.monotonic()), max(0, (deadline - dt.datetime.now(UTC)).total_seconds())))
    print(json.dumps({"utc": stamp(), "status": "PAUSED", "reason": "session deadline"}), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
