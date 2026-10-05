#!/usr/bin/env python3
"""Supervised snapshots and ordinary working-branch pushes; periodic states are WIP."""
import argparse
import datetime as dt
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import select
import subprocess
import sys
import tarfile
import tempfile
import termios
import time

sys.dont_write_bytecode = True
from session_snapshot import snapshot, CREDENTIAL, PRIVATE_NAMES

UTC = dt.timezone.utc


def stamp():
    return dt.datetime.now(UTC).isoformat()


class Coordinator:
    def __init__(self, repo, output, branch, stage, fixture=False):
        self.repo, self.output = repo.resolve(), output.resolve()
        self.branch, self.stage, self.fixture = branch, stage, fixture
        self.env = dict(os.environ, GIT_NO_LAZY_FETCH="1", GIT_LFS_SKIP_SMUDGE="1", GIT_TERMINAL_PROMPT="0")
        self.log = Path("docs/production/evidence/checkpoints/development.jsonl")
        self.commands = []

    def safe(self, value):
        token = self.env.get("GH_TOKEN", "")
        if token:
            value = value.replace(token, "[REDACTED]")
        value = CREDENTIAL.sub(b"[REDACTED]", value.encode()).decode(errors="replace")
        return re.sub(r"https?://[^\s/]*@", "https://[REDACTED]@", value)

    def run(self, *args):
        result = subprocess.run(["git", *args], cwd=self.repo, env=self.env, capture_output=True, timeout=55)
        record = {"command": ["git", *args], "exit_code": result.returncode,
                  "stdout": self.safe(result.stdout.decode(errors="replace")),
                  "stderr": self.safe(result.stderr.decode(errors="replace")), "utc": stamp()}
        self.commands.append(record)
        if result.returncode:
            raise RuntimeError(json.dumps(record))
        return result.stdout

    def guard(self):
        if self.branch in {"main", "master", "HEAD"} or not self.branch.startswith(("feature/", "work/", "epic/")):
            raise RuntimeError("Ref safety: checkpoints require a dedicated working branch.")
        if self.run("branch", "--show-current").decode().strip() != self.branch:
            raise RuntimeError("Ref safety: current branch changed.")
        origin = self.run("remote", "get-url", "origin").decode().strip()
        if not self.fixture and origin != "https://github.com/MindDevastation/where-the-light-remains.git":
            raise RuntimeError("Unexpected origin; checkpoint refused.")

    def changed_paths(self):
        pieces = self.run("status", "--porcelain=v1", "-z").split(b"\0")
        paths, index = set(), 0
        while index < len(pieces):
            item = pieces[index]
            index += 1
            if not item:
                continue
            paths.add(os.fsdecode(item[3:]))
            if b"R" in item[:2] or b"C" in item[:2]:
                paths.add(os.fsdecode(pieces[index]))
                index += 1
        for name in paths:
            p = Path(name)
            if p.is_absolute() or ".." in p.parts or not (name.startswith(("game/", "tools/", "docs/", "assets/3d/blender/archive_kit/")) or name in {".gitignore", ".gitattributes", "README.md"}):
                raise RuntimeError("Changed path requires explicit review: " + name)
            if any(part in PRIVATE_NAMES or part.startswith(".env.") for part in p.parts):
                raise RuntimeError("Credential filename; checkpoint refused.")
            file = self.repo / p
            if file.is_symlink():
                raise RuntimeError("Changed symlink requires explicit review: " + name)
            if file.is_file():
                if file.stat().st_size > 8 * 1024**2:
                    raise RuntimeError("Changed file exceeds automatic checkpoint size limit: " + name)
                data = file.read_bytes()
                token = self.env.get("GH_TOKEN", "").encode()
                if CREDENTIAL.search(data) or (token and token in data):
                    raise RuntimeError("Credential-like payload; checkpoint refused.")
        for args in [("diff", "--no-ext-diff", "--binary"), ("diff", "--cached", "--no-ext-diff", "--binary")]:
            diff = self.run(*args)
            if CREDENTIAL.search(diff):
                raise RuntimeError("Credential-like diff; checkpoint refused.")
        return sorted(paths)

    def append(self, value):
        p = self.repo / self.log
        p.parent.mkdir(parents=True, exist_ok=True)
        with p.open("a") as f:
            f.write(json.dumps(value, ensure_ascii=False) + "\n")
            f.flush()
            os.fsync(f.fileno())

    def push(self, sha):
        self.guard()
        self.run("push", "origin", "HEAD:refs/heads/" + self.branch)
        remote = self.run("ls-remote", "origin", "refs/heads/" + self.branch).decode().split()
        if remote != [sha, "refs/heads/" + self.branch]:
            raise RuntimeError("Remote checkpoint SHA does not match.")

    def checkpoint(self, kind="wip", message=None, validation=None):
        self.commands = []
        self.guard()
        tests = {"status": "PENDING", "scope": "Intermediate state; no stable acceptance claimed."}
        if kind == "stable":
            if not validation:
                raise RuntimeError("Stable checkpoint needs an actual source-hash validation receipt.")
            receipt = json.loads(Path(validation).read_text())
            hashes = receipt.get("source_hashes", {})
            if receipt.get("status") != "PASS" or not hashes:
                raise RuntimeError("Stable validation receipt is not PASS with source hashes.")
            for name, expected in hashes.items():
                p = Path(name)
                if p.is_absolute() or ".." in p.parts or hashlib.sha256((self.repo / p).read_bytes()).hexdigest() != expected:
                    raise RuntimeError("Stable validation source identity mismatch: " + name)
            tests = {"status": "PASS", "validation": str(validation), "source_hashes": len(hashes)}
        before = self.changed_paths()
        previous = self.run("rev-parse", "HEAD").decode().strip()
        archive = snapshot(self.repo, self.output, [], "available")
        verify = subprocess.run([sys.executable, "-B", str(Path(__file__).with_name("verify_session_snapshot.py")), "--archive", str(archive)], cwd=self.repo, capture_output=True, text=True, timeout=55)
        if verify.returncode:
            raise RuntimeError("Archive verification failed: " + self.safe(verify.stdout + verify.stderr))
        with tarfile.open(archive) as t:
            state = json.load(t.extractfile("state.json"))
        after = self.changed_paths()
        self.guard()
        if before != after:
            raise RuntimeError("Writers changed path selection during checkpoint; retry after they finish.")
        archive_sha = archive.with_name(archive.name + ".sha256").read_text().split()[0]
        self.append({"event": "snapshot", "utc": stamp(), "snapshot_started_utc": state["started_utc"],
                     "archive": archive.name, "archive_sha256": archive_sha, "stage": self.stage,
                     "kind": kind.upper(), "head_before": previous, "changed_files": after,
                     "tests": tests, "archive_verification": verify.stdout.strip(),
                     "git_review": self.commands})
        paths = sorted(set(after + [str(self.log)]))
        self.run("add", "--sparse", "--", *paths)
        self.run("diff", "--cached", "--no-ext-diff", "--check")
        title = message or (("checkpoint: " if kind == "stable" else "wip-checkpoint: ") + self.stage)
        if kind == "wip" and not title.lower().startswith(("wip", "wip-checkpoint")):
            raise RuntimeError("Intermediate checkpoint must have an explicit WIP message.")
        self.run("commit", "-m", title)
        primary = self.run("rev-parse", "HEAD").decode().strip()
        self.push(primary)
        self.append({"event": "remote_checkpoint", "utc": stamp(), "stage": self.stage,
                     "kind": kind.upper(), "checkpoint_commit": primary, "remote_verified_sha": primary,
                     "snapshot": archive.name, "tests": tests, "push_commands": self.commands[-5:],
                     "receipt_identity": "Following receipt commit's SHA is resolved from the remote working-branch ref."})
        self.run("add", "--sparse", "--", str(self.log))
        self.run("commit", "-m", "checkpoint receipt: " + primary[:12])
        final = self.run("rev-parse", "HEAD").decode().strip()
        self.push(final)
        result = {"status": "REMOTE_PASS", "utc": stamp(), "kind": kind.upper(), "stage": self.stage,
                  "archive": str(archive), "checkpoint_commit": primary, "remote_sha": final}
        print(json.dumps(result), flush=True)
        return result


def self_test():
    with tempfile.TemporaryDirectory(prefix="wlr-checkpoint-fixture-") as temporary:
        root = Path(temporary)
        repo, remote = root / "repo", root / "remote.git"
        subprocess.run(["git", "init", "--bare", "-q", str(remote)], check=True)
        subprocess.run(["git", "init", "-q", "-b", "work/fixture", str(repo)], check=True)
        for args in [["config", "user.name", "Checkpoint fixture"], ["config", "user.email", "fixture@example.invalid"], ["remote", "add", "origin", str(remote)]]:
            subprocess.run(["git", "-C", str(repo), *args], check=True)
        (repo / "game").mkdir()
        source = repo / "game/source.txt"
        source.write_text("initial\n")
        subprocess.run(["git", "-C", str(repo), "add", "game/source.txt"], check=True)
        subprocess.run(["git", "-C", str(repo), "commit", "-qm", "fixture initial"], check=True)
        loop = Coordinator(repo, root / "archives", "work/fixture", "fixture", True)
        source.write_text("preserved delta\n")
        result = loop.checkpoint()
        assert subprocess.check_output(["git", "--git-dir", str(remote), "show", result["remote_sha"] + ":game/source.txt"]) == b"preserved delta\n"
        assert not loop.run("status", "--porcelain")
        old = loop.run("rev-parse", "HEAD")
        source.write_text("ghp_" + "x" * 30)
        try:
            loop.checkpoint()
        except RuntimeError as error:
            assert "Credential" in str(error)
        else:
            raise AssertionError("Credential payload accepted")
        assert loop.run("rev-parse", "HEAD") == old
        source.write_text("preserved delta\n")
        loop.branch = "main"
        try:
            loop.guard()
        except RuntimeError:
            pass
        else:
            raise AssertionError("Main checkpoint accepted")
        print(json.dumps({"status": "PASS", "checks": ["real snapshot verification", "WIP source and receipt push", "exact remote content", "clean source worktree", "credential refusal without ref mutation", "main refusal"]}), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--output", type=Path)
    parser.add_argument("--branch")
    parser.add_argument("--stage", default="ArchiveMain/S01/S02 reconstruction")
    parser.add_argument("--interval", type=int, default=600)
    parser.add_argument("--gh", type=Path)
    parser.add_argument("--credential-stdin", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if not args.output or not args.branch or not 60 <= args.interval <= 600:
        parser.error("output/branch required; interval 60..600 leaves room before the 900-second maximum")
    if args.gh:
        os.environ["PATH"] = str(args.gh.resolve().parent) + os.pathsep + os.environ["PATH"]
    if args.credential_stdin:
        terminal = termios.tcgetattr(0) if sys.stdin.isatty() else None
        if terminal:
            quiet = list(terminal)
            quiet[3] &= ~termios.ECHO
            termios.tcsetattr(0, termios.TCSANOW, quiet)
        print(json.dumps({"status": "READY_FOR_PRIVATE_CREDENTIAL_INPUT"}), flush=True)
        token = sys.stdin.readline().rstrip("\r\n")
        if terminal:
            termios.tcsetattr(0, termios.TCSANOW, terminal)
        if not token:
            raise RuntimeError("Empty credential input.")
        os.environ["GH_TOKEN"] = token
    if not os.environ.get("GH_TOKEN"):
        raise RuntimeError("GH_TOKEN unavailable; use private credential input.")
    coordinator = Coordinator(args.repo, args.output, args.branch, args.stage)
    lock_path = coordinator.repo / os.fsdecode(coordinator.run("rev-parse", "--git-path", "checkpoint-coordinator.lock")).strip()
    with lock_path.open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        due = time.monotonic()
        while True:
            if time.monotonic() >= due:
                coordinator.checkpoint()
                due += args.interval
            ready, _, _ = select.select([sys.stdin], [], [], max(0, min(30, due - time.monotonic())))
            if ready:
                line = sys.stdin.readline()
                if not line:
                    return 0
                action = json.loads(line)
                if action.get("op") == "stop":
                    print(json.dumps({"status": "PAUSED", "utc": stamp(), "reason": "owned coordinator stopped"}), flush=True)
                    return 0
                if action.get("op") == "checkpoint":
                    coordinator.stage = action.get("stage", coordinator.stage)
                    coordinator.checkpoint(action.get("kind", "wip"), action.get("message"), action.get("validation"))
                    due = time.monotonic() + args.interval
                else:
                    raise RuntimeError("Unsupported coordinator control operation.")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        value = CREDENTIAL.sub(b"[REDACTED]", str(error).encode()).decode(errors="replace")
        token = os.environ.get("GH_TOKEN")
        if token:
            value = value.replace(token, "[REDACTED]")
        print(json.dumps({"status": "BLOCKER", "utc": stamp(), "reason": value}), flush=True)
        raise SystemExit(1)
