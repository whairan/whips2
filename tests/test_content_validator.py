#!/usr/bin/env python3
"""Tests for the content validator."""

import json
import sys
import os
import tempfile
from pathlib import Path

# Add tools to path
sys.path.insert(0, str(Path(__file__).parent.parent / "tools"))
from content_validator import (
    validate_file, ValidationResult, lint_level, lint_task,
    check_region_connectivity, load_json
)

CONTENT_DIR = Path(__file__).parent.parent / "content"


def test_valid_level_passes():
    """A valid level file should pass validation."""
    path = CONTENT_DIR / "levels" / "level_01_counting.json"
    result = validate_file(path)
    assert result.ok, f"Level 01 should pass: {result.summary()}"
    print("PASS: test_valid_level_passes")


def test_valid_zone_passes():
    """A valid zone file should pass validation."""
    path = CONTENT_DIR / "zones" / "zone_1_jungle_edge.json"
    result = validate_file(path)
    assert result.ok, f"Zone 1 should pass: {result.summary()}"
    print("PASS: test_valid_zone_passes")


def test_valid_tasks_pass():
    """Valid task files should pass validation."""
    path = CONTENT_DIR / "tasks" / "level_01_tasks.json"
    result = validate_file(path)
    assert result.ok, f"Tasks should pass: {result.summary()}"
    print("PASS: test_valid_tasks_pass")


def test_valid_reference_page_passes():
    """A valid reference page should pass validation."""
    path = CONTENT_DIR / "reference_pages" / "ref_counting_basics.json"
    result = validate_file(path)
    assert result.ok, f"Reference page should pass: {result.summary()}"
    print("PASS: test_valid_reference_page_passes")


def test_level_missing_interactables_fails():
    """A level with fewer than 8 interactables should fail lint."""
    result = ValidationResult()
    data = {
        "level_id": "level_test",
        "interactables": [{"type": "fruit_tree", "id": "ft1"}],
        "traversal": ["climbable_tree", "vine_swing"],
        "eco_puzzle": {"id": "eco_1", "task_ref": "task_1", "description": "test", "on_solve": {}},
        "quest_line": {"warmup": "w1", "teach": ["t1"], "practice": ["p1", "p2"], "apply": ["a1"], "boss": "b1"},
        "rewards": {"reference_pages": ["ref_1"]},
        "choice_map": [{"approach": "a", "description": "d"}, {"approach": "b", "description": "d"}],
        "mini_games": [{"template": "fruit_count_harvest", "config": {}}]
    }
    lint_level(data, result)
    assert not result.ok, "Should fail with too few interactables"
    assert any("at least 8 interactables" in e for e in result.errors)
    print("PASS: test_level_missing_interactables_fails")


def test_level_missing_traversal_fails():
    """A level with fewer than 2 traversal mechanics should fail lint."""
    result = ValidationResult()
    data = {
        "level_id": "level_test",
        "interactables": [{"type": "t", "id": str(i)} for i in range(8)],
        "traversal": ["climbable_tree"],
        "eco_puzzle": {"id": "eco_1", "task_ref": "t1", "description": "test", "on_solve": {}},
        "quest_line": {"warmup": "w", "teach": ["t"], "practice": ["p1", "p2"], "apply": ["a"], "boss": "b"},
        "rewards": {"reference_pages": ["r"]},
        "choice_map": [{"approach": "a", "description": "d"}, {"approach": "b", "description": "d"}],
        "mini_games": [{"template": "fruit_count_harvest", "config": {}}]
    }
    lint_level(data, result)
    assert any("at least 2 traversal" in e for e in result.errors)
    print("PASS: test_level_missing_traversal_fails")


def test_task_missing_answer_fails():
    """A task without an answer should fail lint."""
    result = ValidationResult()
    data = {
        "task_id": "task_test",
        "hints": [{"level": 1, "text": "hint"}],
        "explanation": "This explains the answer.",
        "difficulty": 2
    }
    lint_task(data, result)
    # answer is present but None
    data["answer"] = None
    result2 = ValidationResult()
    lint_task(data, result2)
    assert not result2.ok
    print("PASS: test_task_missing_answer_fails")


def test_task_short_explanation_fails():
    """A task with too short an explanation should fail."""
    result = ValidationResult()
    data = {
        "task_id": "task_test",
        "answer": 42,
        "hints": [{"level": 1, "text": "hint text here"}],
        "explanation": "Short",
        "difficulty": 2
    }
    lint_task(data, result)
    assert any("Explanation too short" in e for e in result.errors)
    print("PASS: test_task_short_explanation_fails")


def test_region_connectivity():
    """All MVP regions should be reachable from level_01."""
    result = ValidationResult()
    check_region_connectivity(result)
    assert result.ok, f"Connectivity check failed: {result.summary()}"
    print("PASS: test_region_connectivity")


def test_invalid_json_reports_error():
    """Invalid JSON should be reported as an error."""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', dir=str(CONTENT_DIR / "levels"), delete=False) as f:
        f.write("{invalid json")
        temp_path = Path(f.name)

    try:
        result = validate_file(temp_path)
        assert not result.ok
        assert any("Invalid JSON" in e for e in result.errors)
        print("PASS: test_invalid_json_reports_error")
    finally:
        temp_path.unlink()


if __name__ == "__main__":
    tests = [
        test_valid_level_passes,
        test_valid_zone_passes,
        test_valid_tasks_pass,
        test_valid_reference_page_passes,
        test_level_missing_interactables_fails,
        test_level_missing_traversal_fails,
        test_task_missing_answer_fails,
        test_task_short_explanation_fails,
        test_region_connectivity,
        test_invalid_json_reports_error,
    ]

    passed = 0
    failed = 0
    for test in tests:
        try:
            test()
            passed += 1
        except Exception as e:
            print(f"FAIL: {test.__name__}: {e}")
            failed += 1

    print(f"\n{'='*40}")
    print(f"Results: {passed} passed, {failed} failed, {len(tests)} total")
    if failed > 0:
        sys.exit(1)
