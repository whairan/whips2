#!/usr/bin/env python3
"""
Whips Content Validator
Validates content JSON files against schemas and runs lint rules.

Usage:
    python content_validator.py [path]           # validate specific file or directory
    python content_validator.py --all            # validate all content
    python content_validator.py --check-graph    # validate region connectivity
    python content_validator.py --check-balance  # validate reward balance
    python content_validator.py --check-coverage # validate skill tag coverage
"""

import json
import os
import sys
import re
from pathlib import Path
from typing import Any

# Try to import jsonschema; provide install hint if missing
try:
    import jsonschema
    from jsonschema import Draft202012Validator, ValidationError
    HAS_JSONSCHEMA = True
except ImportError:
    HAS_JSONSCHEMA = False

CONTENT_DIR = Path(__file__).parent.parent / "content"
SCHEMA_DIR = CONTENT_DIR / "schemas"

# Maps content directory names to their schema file
SCHEMA_MAP = {
    "zones": "zone.schema.json",
    "levels": "level.schema.json",
    "tasks": "task.schema.json",
    "reference_pages": "reference_page.schema.json",
    "dialogues": "dialogue.schema.json",
}


class ValidationResult:
    def __init__(self):
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.info: list[str] = []

    def error(self, msg: str):
        self.errors.append(msg)

    def warn(self, msg: str):
        self.warnings.append(msg)

    def add_info(self, msg: str):
        self.info.append(msg)

    @property
    def ok(self) -> bool:
        return len(self.errors) == 0

    def summary(self) -> str:
        lines = []
        for e in self.errors:
            lines.append(f"  ERROR: {e}")
        for w in self.warnings:
            lines.append(f"  WARN:  {w}")
        for i in self.info:
            lines.append(f"  INFO:  {i}")
        return "\n".join(lines) if lines else "  OK"


def load_schema(schema_name: str) -> dict | None:
    path = SCHEMA_DIR / schema_name
    if not path.exists():
        return None
    with open(path) as f:
        return json.load(f)


def load_json(path: Path) -> tuple[dict | None, str | None]:
    try:
        with open(path) as f:
            return json.load(f), None
    except json.JSONDecodeError as e:
        return None, f"Invalid JSON: {e}"
    except Exception as e:
        return None, f"Could not read file: {e}"


def validate_schema(data: dict, schema: dict, result: ValidationResult):
    """Validate data against a JSON schema."""
    if not HAS_JSONSCHEMA:
        result.warn("jsonschema not installed — skipping schema validation. Install with: pip install jsonschema")
        return

    validator = Draft202012Validator(schema)
    for error in sorted(validator.iter_errors(data), key=lambda e: list(e.absolute_path)):
        path = ".".join(str(p) for p in error.absolute_path) or "(root)"
        result.error(f"Schema: {path}: {error.message}")


# --- Lint Rules ---

def lint_level(data: dict, result: ValidationResult):
    """Level-specific lint rules."""
    level_id = data.get("level_id", "unknown")

    # Check minimum interactables
    interactables = data.get("interactables", [])
    if len(interactables) < 8:
        result.error(f"{level_id}: Must have at least 8 interactables, found {len(interactables)}")

    # Check minimum traversal
    traversal = data.get("traversal", [])
    if len(traversal) < 2:
        result.error(f"{level_id}: Must have at least 2 traversal mechanics, found {len(traversal)}")

    # Check eco puzzle exists
    eco = data.get("eco_puzzle")
    if not eco:
        result.error(f"{level_id}: Missing eco_puzzle")
    elif not eco.get("task_ref"):
        result.error(f"{level_id}: eco_puzzle missing task_ref")

    # Check quest line completeness
    quest = data.get("quest_line", {})
    if not quest.get("warmup"):
        result.error(f"{level_id}: quest_line missing warmup")
    if not quest.get("boss"):
        result.error(f"{level_id}: quest_line missing boss")
    if len(quest.get("practice", [])) < 2:
        result.warn(f"{level_id}: quest_line should have at least 2 practice tasks")

    # Check rewards
    rewards = data.get("rewards", {})
    if not rewards.get("reference_pages"):
        result.error(f"{level_id}: Must unlock at least 1 reference page")

    # Check choice map
    choices = data.get("choice_map", [])
    if len(choices) < 2:
        result.error(f"{level_id}: choice_map must have at least 2 approaches")

    # Check mini games
    mini_games = data.get("mini_games", [])
    if len(mini_games) < 2:
        result.warn(f"{level_id}: Should have at least 2 mini-games, found {len(mini_games)}")


def lint_task(data: dict, result: ValidationResult):
    """Task-specific lint rules."""
    task_id = data.get("task_id", "unknown")

    # Check answer exists and is not None
    if "answer" not in data or data["answer"] is None:
        result.error(f"{task_id}: Missing answer")

    # Check hints exist
    hints = data.get("hints", [])
    if len(hints) < 1:
        result.error(f"{task_id}: Must have at least 1 hint")

    # Check explanation
    explanation = data.get("explanation", "")
    if len(explanation) < 10:
        result.error(f"{task_id}: Explanation too short (min 10 chars)")

    # Check difficulty range
    diff = data.get("difficulty", 0)
    if diff < 1 or diff > 5:
        result.error(f"{task_id}: Difficulty must be 1-5, got {diff}")

    # Check for division by zero in generated tasks
    gen = data.get("generator_params")
    if gen and gen.get("operation") == "division":
        divisor_min = gen.get("divisor_min", 1)
        if divisor_min <= 0:
            result.error(f"{task_id}: Generator allows division by zero (divisor_min={divisor_min})")


def lint_zone(data: dict, result: ValidationResult):
    """Zone-specific lint rules."""
    zone_id = data.get("zone_id", "unknown")
    levels = data.get("levels", [])
    if len(levels) < 1:
        result.error(f"{zone_id}: Must contain at least 1 level")


def lint_reference_page(data: dict, result: ValidationResult):
    """Reference page lint rules."""
    page_id = data.get("page_id", "unknown")
    sections = data.get("sections", [])
    if len(sections) < 1:
        result.error(f"{page_id}: Must have at least 1 section")

    # Check each section has meaningful content
    for i, section in enumerate(sections):
        content = section.get("content", "")
        if len(content) < 10:
            result.warn(f"{page_id}: Section {i} content very short")


LINT_MAP = {
    "levels": lint_level,
    "tasks": lint_task,
    "zones": lint_zone,
    "reference_pages": lint_reference_page,
}


# --- Graph Checks ---

def check_region_connectivity(result: ValidationResult):
    """Verify all regions are reachable from region_01 via connections."""
    levels_dir = CONTENT_DIR / "levels"
    if not levels_dir.exists():
        result.warn("No levels directory found — skipping connectivity check")
        return

    graph: dict[str, set[str]] = {}
    all_levels: set[str] = set()

    for f in sorted(levels_dir.glob("*.json")):
        data, err = load_json(f)
        if err or not data:
            continue
        level_id = data.get("level_id", "")
        all_levels.add(level_id)
        connections = data.get("connections", {})
        neighbors = set()
        for direction in ["north", "south", "east", "west"]:
            target = connections.get(direction)
            if target:
                neighbors.add(target)
        for shortcut in connections.get("shortcuts", []):
            target = shortcut.get("target")
            if target:
                neighbors.add(target)
        graph[level_id] = neighbors

    if not all_levels:
        result.warn("No levels found for connectivity check")
        return

    # BFS from level_01
    start = "level_01"
    if start not in all_levels:
        result.error(f"Starting level {start} not found")
        return

    visited: set[str] = set()
    queue = [start]
    while queue:
        current = queue.pop(0)
        if current in visited:
            continue
        visited.add(current)
        for neighbor in graph.get(current, set()):
            if neighbor not in visited:
                queue.append(neighbor)

    unreachable = all_levels - visited
    if unreachable:
        result.error(f"Unreachable levels from {start}: {sorted(unreachable)}")
    else:
        result.add_info(f"All {len(all_levels)} levels are reachable from {start}")


def check_reward_balance(result: ValidationResult):
    """Check reward distribution across levels."""
    levels_dir = CONTENT_DIR / "levels"
    if not levels_dir.exists():
        return

    tool_unlocks = {}
    traversal_unlocks = {}

    for f in sorted(levels_dir.glob("*.json")):
        data, err = load_json(f)
        if err or not data:
            continue
        level_id = data.get("level_id", "")
        rewards = data.get("rewards", {})

        tool = rewards.get("tool_unlock")
        if tool:
            if tool in tool_unlocks:
                result.error(f"Duplicate tool unlock '{tool}' in {level_id} and {tool_unlocks[tool]}")
            tool_unlocks[tool] = level_id

        traversal = rewards.get("traversal_unlock")
        if traversal:
            if traversal in traversal_unlocks:
                result.error(f"Duplicate traversal unlock '{traversal}' in {level_id} and {traversal_unlocks[traversal]}")
            traversal_unlocks[traversal] = level_id

    result.add_info(f"Tool unlocks: {len(tool_unlocks)}, Traversal unlocks: {len(traversal_unlocks)}")


def check_skill_coverage(result: ValidationResult):
    """Check that every skill tag used in levels has sufficient tasks."""
    levels_dir = CONTENT_DIR / "levels"
    tasks_dir = CONTENT_DIR / "tasks"

    if not levels_dir.exists() or not tasks_dir.exists():
        result.warn("Missing levels or tasks directory — skipping coverage check")
        return

    # Collect all skill tags from levels
    level_skills: set[str] = set()
    for f in levels_dir.glob("*.json"):
        data, err = load_json(f)
        if err or not data:
            continue
        for tag in data.get("skill_tags", []):
            level_skills.add(tag)

    # Collect task counts per skill tag
    task_counts: dict[str, int] = {}
    for f in tasks_dir.glob("*.json"):
        data, err = load_json(f)
        if err or not data:
            continue
        # Handle both single tasks and task arrays
        tasks = data if isinstance(data, list) else [data]
        for task in tasks:
            for tag in task.get("skill_tags", []):
                task_counts[tag] = task_counts.get(tag, 0) + 1

    # Check coverage
    for skill in sorted(level_skills):
        count = task_counts.get(skill, 0)
        if count == 0:
            result.error(f"Skill tag '{skill}' has no tasks")
        elif count < 10:
            result.warn(f"Skill tag '{skill}' has only {count} tasks (recommended: 10+)")

    uncovered = set(task_counts.keys()) - level_skills
    if uncovered:
        result.warn(f"Task skill tags not used in any level: {sorted(uncovered)}")


# --- Main validation ---

def validate_file(path: Path) -> ValidationResult:
    result = ValidationResult()

    # Determine content type from parent directory
    content_type = path.parent.name
    if content_type not in SCHEMA_MAP:
        result.warn(f"Unknown content type '{content_type}' for {path.name}")
        return result

    # Load data
    data, err = load_json(path)
    if err:
        result.error(f"{path.name}: {err}")
        return result

    # Handle files that contain arrays (e.g., task banks)
    items = data if isinstance(data, list) else [data]

    schema = load_schema(SCHEMA_MAP[content_type])
    lint_fn = LINT_MAP.get(content_type)

    for item in items:
        # Schema validation
        if schema:
            validate_schema(item, schema, result)
        else:
            result.warn(f"Schema not found for {content_type}")

        # Lint rules
        if lint_fn:
            lint_fn(item, result)

    return result


def validate_directory(dir_path: Path) -> dict[str, ValidationResult]:
    results = {}
    for f in sorted(dir_path.rglob("*.json")):
        if "schemas" in str(f):
            continue
        results[str(f)] = validate_file(f)
    return results


def main():
    args = sys.argv[1:]

    if not args:
        print("Usage: python content_validator.py [--all | --check-graph | --check-balance | --check-coverage | <path>]")
        sys.exit(1)

    total_errors = 0
    total_warnings = 0

    if "--all" in args:
        print("=== Validating all content ===\n")
        results = validate_directory(CONTENT_DIR)
        for path, result in results.items():
            status = "PASS" if result.ok else "FAIL"
            print(f"[{status}] {path}")
            if not result.ok or result.warnings:
                print(result.summary())
            total_errors += len(result.errors)
            total_warnings += len(result.warnings)

    if "--check-graph" in args:
        print("\n=== Region Connectivity ===\n")
        result = ValidationResult()
        check_region_connectivity(result)
        print(result.summary())
        total_errors += len(result.errors)

    if "--check-balance" in args:
        print("\n=== Reward Balance ===\n")
        result = ValidationResult()
        check_reward_balance(result)
        print(result.summary())
        total_errors += len(result.errors)

    if "--check-coverage" in args:
        print("\n=== Skill Coverage ===\n")
        result = ValidationResult()
        check_skill_coverage(result)
        print(result.summary())
        total_errors += len(result.errors)

    # Validate specific path
    for arg in args:
        if arg.startswith("--"):
            continue
        path = Path(arg)
        if path.is_file():
            result = validate_file(path)
            status = "PASS" if result.ok else "FAIL"
            print(f"[{status}] {path}")
            print(result.summary())
            total_errors += len(result.errors)
            total_warnings += len(result.warnings)
        elif path.is_dir():
            results = validate_directory(path)
            for p, result in results.items():
                status = "PASS" if result.ok else "FAIL"
                print(f"[{status}] {p}")
                if not result.ok or result.warnings:
                    print(result.summary())
                total_errors += len(result.errors)
                total_warnings += len(result.warnings)
        else:
            print(f"Path not found: {path}")
            total_errors += 1

    print(f"\n{'='*40}")
    print(f"Errors: {total_errors}  Warnings: {total_warnings}")
    if total_errors > 0:
        sys.exit(1)
    print("All validations passed!")


if __name__ == "__main__":
    main()
