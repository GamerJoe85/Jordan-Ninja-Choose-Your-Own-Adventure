#!/usr/bin/env python3
"""Validate story JSON schema and required Fire Chapter scaffold files.

This performs only deterministic data + file-structure checks.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STORY_PATH = ROOT / "data" / "story_pages.json"

REQUIRED_FILES = [
    "project.godot",
    "scenes/Main.tscn",
    "scenes/TitleMenu.tscn",
    "scenes/PagePlayer.tscn",
    "scenes/acts/Act1.tscn",
    "scenes/acts/Act2.tscn",
    "scenes/acts/Act3.tscn",
    "scenes/acts/Act4.tscn",
    "scenes/acts/Act5.tscn",
    "scenes/acts/Act6.tscn",
    "scripts/singletons/game_state.gd",
    "scripts/controllers/main.gd",
    "scripts/controllers/title_menu.gd",
    "scripts/ui/page_player.gd",
    "scripts/acts/act_wrapper.gd",
    "data/story_pages.json",
]

REQUIRED_PAGE_KEYS = {"page_id", "act_id", "image_path", "story_text", "choices"}
REQUIRED_CHOICE_KEYS = {"label", "effects", "next_page_id"}


def fail(message: str) -> None:
    raise SystemExit(f"VALIDATION FAILED: {message}")


def validate_required_files() -> None:
    missing = [p for p in REQUIRED_FILES if not (ROOT / p).exists()]
    if missing:
        fail(f"Missing required files: {missing}")


def validate_story_json() -> None:
    if not STORY_PATH.exists():
        fail("story_pages.json is missing")

    try:
        data = json.loads(STORY_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"Invalid JSON format: {exc}")

    if not isinstance(data, dict) or "pages" not in data or not isinstance(data["pages"], list):
        fail("Top-level JSON must be an object with a 'pages' array")

    pages = data["pages"]
    if not pages:
        fail("'pages' array is empty")

    seen_page_ids: set[str] = set()

    for index, page in enumerate(pages):
        if not isinstance(page, dict):
            fail(f"Page #{index} is not an object")

        missing_keys = REQUIRED_PAGE_KEYS - page.keys()
        if missing_keys:
            fail(f"Page #{index} missing keys: {sorted(missing_keys)}")

        page_id = page["page_id"]
        if not isinstance(page_id, str) or not page_id.strip():
            fail(f"Page #{index} has invalid page_id")
        if page_id in seen_page_ids:
            fail(f"Duplicate page_id: {page_id}")
        seen_page_ids.add(page_id)

        choices = page["choices"]
        if not isinstance(choices, list) or not (1 <= len(choices) <= 4):
            fail(f"Page '{page_id}' must have 1-4 choices")

        for c_index, choice in enumerate(choices):
            if not isinstance(choice, dict):
                fail(f"Page '{page_id}' choice #{c_index} is not an object")
            missing_choice_keys = REQUIRED_CHOICE_KEYS - choice.keys()
            if missing_choice_keys:
                fail(
                    f"Page '{page_id}' choice #{c_index} missing keys: {sorted(missing_choice_keys)}"
                )
            if "requirements" in choice and not isinstance(choice["requirements"], dict):
                fail(f"Page '{page_id}' choice #{c_index} has non-dict requirements")
            if not isinstance(choice["effects"], dict):
                fail(f"Page '{page_id}' choice #{c_index} has non-dict effects")

    # validate next_page references are defined
    for page in pages:
        for choice in page["choices"]:
            next_page_id = choice["next_page_id"]
            if not isinstance(next_page_id, str) or next_page_id not in seen_page_ids:
                fail(f"Choice points to unknown next_page_id: {next_page_id}")


if __name__ == "__main__":
    validate_required_files()
    validate_story_json()
    print("Validation passed: JSON format + required file structure are valid.")
