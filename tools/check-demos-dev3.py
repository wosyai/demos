#!/usr/bin/env python3
"""Run Dev3 Check against the actual demo sources without invoking their builders."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

DEMOS = ("flight", "voxel", "ferry", "orbital")
SOURCE_ROOT = b'root = "engine.w"'
PROJECT = b"[package]\n"


def stage_check(app, scratch):
    manifest = (app / "wosy.toml").read_bytes()
    if manifest.count(PROJECT) != 1 or manifest.count(SOURCE_ROOT) != 1:
        raise ValueError(f"{app.name}: expected the demo's flat source layout")
    # Check needs an explicit package source root. Keep this projection out
    # of the release manifests and feed Check the same Wosy source bytes.
    manifest = manifest.replace(PROJECT, PROJECT + b'source_root = "src"\n', 1)
    manifest = manifest.replace(SOURCE_ROOT, b'root = "src/engine.w"', 1)
    (scratch / "wosy.toml").write_bytes(manifest)
    for source in sorted(app.rglob("*.w")):
        relative = source.relative_to(app)
        if ".wosy" not in relative.parts:
            target = scratch / "src" / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wosy", type=Path, required=True, help="path to the Dev3 compiler")
    parser.add_argument("--all-errors", action="store_true")
    parser.add_argument("--main-flow-only", action="store_true")
    parser.add_argument("games", nargs="*", metavar="GAME", help=f"one or more of {', '.join(DEMOS)}")
    args = parser.parse_args()
    games = tuple(args.games) or DEMOS
    if any(game not in DEMOS for game in games):
        parser.error(f"games must be selected from {', '.join(DEMOS)}")
    compiler = args.wosy.resolve(strict=True)
    repo = Path(__file__).resolve().parents[1]
    flags = ["--main-flow-only"] if args.main_flow_only else ["--declared-package"]
    if args.all_errors:
        flags.append("--all-errors")
    failed = False
    with tempfile.TemporaryDirectory(prefix="dev3-demos-") as temp:
        temp = Path(temp)
        home = temp / "home"
        home.mkdir()
        env = {"HOME": str(home), "PATH": str(home), "TMPDIR": str(temp), "LC_ALL": "C.UTF-8"}
        for game in games:
            scratch = temp / game
            scratch.mkdir()
            stage_check(repo / game, scratch)
            print(f"[{game}]", flush=True)
            result = subprocess.run(
                [str(compiler), "check", "app", "--profile", "dev", *flags],
                cwd=scratch, env=env, stdin=subprocess.DEVNULL,
            )
            failed = failed or result.returncode != 0
            if not result.returncode:
                print("Check exited 0 (use a reached negative control to establish proof coverage).")
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
