#!/usr/bin/env python3
"""
Whips Content Build Tool
Compiles JSON content files into Godot-ready resources.
Copies validated content to the Godot project's resources/generated directory.

Usage:
    python build_content.py                 # build all content
    python build_content.py <path>          # build specific file
    python build_content.py --watch         # watch mode (hot reload)
"""

import json
import shutil
import sys
import time
import os
from pathlib import Path

CONTENT_DIR = Path(__file__).parent.parent / "content"
OUTPUT_DIR = Path(__file__).parent.parent / "godot_project" / "resources" / "generated"
VALIDATOR = Path(__file__).parent / "content_validator.py"

CONTENT_SUBDIRS = ["zones", "levels", "tasks", "reference_pages", "dialogues"]


def build_all() -> int:
    """Build all content files to Godot output."""
    errors = 0
    total = 0

    for subdir in CONTENT_SUBDIRS:
        src_dir = CONTENT_DIR / subdir
        out_dir = OUTPUT_DIR / subdir
        out_dir.mkdir(parents=True, exist_ok=True)

        if not src_dir.exists():
            continue

        for json_file in sorted(src_dir.glob("*.json")):
            total += 1
            if _build_file(json_file, out_dir):
                print(f"  OK: {json_file.name}")
            else:
                print(f"  FAIL: {json_file.name}")
                errors += 1

    print(f"\nBuilt {total - errors}/{total} files ({errors} errors)")
    return errors


def build_file(path: Path) -> bool:
    """Build a single file."""
    subdir = path.parent.name
    out_dir = OUTPUT_DIR / subdir
    out_dir.mkdir(parents=True, exist_ok=True)
    return _build_file(path, out_dir)


def _build_file(src: Path, out_dir: Path) -> bool:
    """Validate and copy a single content file."""
    # Validate first
    result = os.system(f"python3 {VALIDATOR} {src} > /dev/null 2>&1")
    if result != 0:
        return False

    # Copy to output
    dest = out_dir / src.name
    shutil.copy2(src, dest)
    return True


def watch_mode():
    """Watch content directory for changes and rebuild."""
    print("Watching for content changes... (Ctrl+C to stop)")
    mtimes: dict[str, float] = {}

    # Initial scan
    for subdir in CONTENT_SUBDIRS:
        src_dir = CONTENT_DIR / subdir
        if not src_dir.exists():
            continue
        for f in src_dir.glob("*.json"):
            mtimes[str(f)] = f.stat().st_mtime

    while True:
        time.sleep(1)
        for subdir in CONTENT_SUBDIRS:
            src_dir = CONTENT_DIR / subdir
            if not src_dir.exists():
                continue
            for f in src_dir.glob("*.json"):
                key = str(f)
                current_mtime = f.stat().st_mtime
                if key not in mtimes or current_mtime > mtimes[key]:
                    mtimes[key] = current_mtime
                    print(f"\nChange detected: {f.name}")
                    out_dir = OUTPUT_DIR / subdir
                    out_dir.mkdir(parents=True, exist_ok=True)
                    if _build_file(f, out_dir):
                        print(f"  Rebuilt: {f.name}")
                    else:
                        print(f"  Build FAILED: {f.name}")


def main():
    args = sys.argv[1:]

    if "--watch" in args:
        try:
            watch_mode()
        except KeyboardInterrupt:
            print("\nStopped watching.")
            return

    if not args:
        print("=== Building all content ===\n")
        errors = build_all()
        sys.exit(1 if errors > 0 else 0)

    for arg in args:
        if arg.startswith("--"):
            continue
        path = Path(arg)
        if path.is_file():
            if build_file(path):
                print(f"Built: {path}")
            else:
                print(f"Failed: {path}")
                sys.exit(1)
        elif path.is_dir():
            # Build all files in directory
            for f in sorted(path.glob("*.json")):
                build_file(f)
        else:
            print(f"Not found: {path}")
            sys.exit(1)


if __name__ == "__main__":
    main()
