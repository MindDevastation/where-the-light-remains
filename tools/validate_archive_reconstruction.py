#!/usr/bin/env python3
"""Targeted Archive delta validation from an exact, initially cache-free copy."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def stamp():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def validate(args):
    source = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    paths = sorted(p.relative_to(source).as_posix() for folder in ("game", "tools")
                   for p in (source / folder).rglob("*") if p.is_file() and not p.is_symlink()
                   and not any(part in {".godot", ".import", "__pycache__"} for part in p.parts))
    hashes = {p: digest(source / p) for p in paths}
    result = {"status": "RUNNING", "started_at": stamp(), "source_hashes": hashes,
              "scope": args.tests, "save_mode": args.save_mode, "records": []}
    receipt = output / "results.json"
    receipt.write_text(json.dumps(result, indent=2) + "\n")
    try:
        with tempfile.TemporaryDirectory(prefix="wlr-archive-delta-") as private:
            scratch = Path(private)
            clean = scratch / "source"
            for name in paths:
                target = clean / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source / name, target)
            if (clean / "game/.godot").exists() or any(digest(clean / p) != h for p, h in hashes.items()):
                raise RuntimeError("Clean-copy source mismatch or reused import cache")
            def run(name, command, marker="", timeout=90):
                data = scratch / ("userdata-" + name)
                slots = data / "godot/app_userdata/Where the Light Remains"
                slots.mkdir(parents=True)
                if args.save_mode == "read-only":
                    for filename in ("savegame.json", "savegame.backup.json"):
                        saved = {"save_version": 1, "stage_id": "s01_saved_fixture", "checkpoint_id": "protected",
                                 "collected_fragments": [], "world_states": {}, "milestones": {},
                                 "achievement_ids": [], "game_completed": False}
                        (slots / filename).write_text(json.dumps(saved) + "\n")
                before = {p.name: digest(p) for p in slots.iterdir() if p.is_file()}
                env = dict(os.environ, GODOT_SILENCE_ROOT_WARNING="1", XDG_DATA_HOME=str(data))
                if name == "app_save_exit_smoke":
                    command = command + ["--", "--save-exit-root=" + str(data)]
                record = {"name": name, "command": command, "started_at": stamp()}
                process = subprocess.Popen(command, cwd=clean, env=env, stdout=subprocess.PIPE,
                                           stderr=subprocess.STDOUT, start_new_session=True)
                timed_out = False
                try:
                    raw, _ = process.communicate(timeout=timeout)
                except subprocess.TimeoutExpired:
                    timed_out = True
                    process.terminate()
                    try:
                        raw, _ = process.communicate(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        raw, _ = process.communicate()
                log = output / (name + ".complete.log")
                log.write_bytes(raw)
                after = {p.name: digest(p) for p in slots.iterdir() if p.is_file()}
                passed = process.returncode == 0 and not timed_out and (not marker or marker.encode() in raw) and \
                    not any(word in raw for word in (b"ERROR:", b"SCRIPT ERROR", b"Parse Error", b"WARNING:")) and \
                    (args.save_mode != "read-only" or before == after)
                record.update(exit_code=process.returncode, timeout=timed_out, finished_at=stamp(),
                              stdout_sha256=digest(log), stdout_bytes=len(raw), passed=passed,
                              slots_before=before, slots_after=after)
                result["records"].append(record)
                receipt.write_text(json.dumps(result, indent=2) + "\n")
                print(json.dumps({"name": name, "passed": passed, "exit_code": process.returncode}), flush=True)
                if not passed:
                    raise RuntimeError("Targeted validation failed: " + name)
            godot = str(args.godot.resolve())
            run("clean_import", [godot, "--headless", "--path", "game", "--editor", "--import"])
            for test in args.tests:
                if not test.replace("_", "").isalnum():
                    raise ValueError("Invalid test name")
                run(test, [godot, "--headless", "--path", "game", "res://tests/" + test + ".tscn"],
                    test.removesuffix("_smoke").upper() + " PASS", 60)
            if any(digest(source / p) != h for p, h in hashes.items()):
                raise RuntimeError("Source changed during validation; result cannot certify current bytes")
        result["status"] = "PASS"
        result["clean_copy_removed"] = True
    except Exception as error:
        result.update(status="FAIL", failure=str(error))
        raise
    finally:
        result["finished_at"] = stamp()
        receipt.write_text(json.dumps(result, indent=2) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--tests", nargs="+", required=True)
    parser.add_argument("--save-mode", choices=("read-only", "test-owned"), default="read-only")
    validate(parser.parse_args())
