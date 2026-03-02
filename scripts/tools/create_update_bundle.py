#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "update_bundle"

INCLUDE = [
    Path("project.godot"),
    Path("data/story_pages.json"),
    Path("docs/BEGINNER_FILE_UPDATE_GUIDE.md"),
    Path("docs/IMAGE_ASSIGNMENT_CHECKLIST.md"),
    Path("docs/PROJECT_ARCHITECTURE.md"),
    Path("docs/START_HERE_NOOB.md"),
    Path("docs/SYNC_TROUBLESHOOTING.md"),
    Path("docs/WRITE_YOUR_SCENES.md"),
    Path("scenes/Main.tscn"),
    Path("scenes/PagePlayer.tscn"),
    Path("scenes/TitleMenu.tscn"),
    Path("scenes/acts/Act1.tscn"),
    Path("scenes/acts/Act2.tscn"),
    Path("scenes/acts/Act3.tscn"),
    Path("scenes/acts/Act4.tscn"),
    Path("scenes/acts/Act5.tscn"),
    Path("scenes/acts/Act6.tscn"),
    Path("scripts/acts/act_wrapper.gd"),
    Path("scripts/controllers/main.gd"),
    Path("scripts/controllers/title_menu.gd"),
    Path("scripts/singletons/game_state.gd"),
    Path("scripts/tools/validate_story_data.py"),
    Path("scripts/ui/page_image_entry.gd"),
    Path("scripts/ui/page_player.gd"),
    Path("assets/images/.gitkeep"),
]



def current_commit() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    except Exception:
        return "unknown"

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True, exist_ok=True)

    manifest_lines: list[str] = []
    for rel in INCLUDE:
        src = ROOT / rel
        if not src.exists():
            raise SystemExit(f"Missing required source file: {rel}")
        dest = OUT / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        manifest_lines.append(f"{sha256_file(src)}  {rel.as_posix()}")

    (OUT / "MANIFEST.sha256").write_text("\n".join(manifest_lines) + "\n", encoding="utf-8")

    version_text = (
        f"source_commit={current_commit()}\n"
        f"generated_utc={datetime.now(timezone.utc).isoformat()}\n"
        f"files_in_bundle={len(INCLUDE)}\n"
    )
    (OUT / "BUNDLE_VERSION.txt").write_text(version_text, encoding="utf-8")
    (OUT / "README.md").write_text(
        "# Update Bundle\n\n"
        "This folder contains the latest project files to copy into your Godot project.\n\n"
        "## Quick use\n\n"
        "1. Copy everything inside `update_bundle/` into your project root.\n"
        "2. Overwrite existing files when prompted.\n"
        "3. Open Godot and run the project.\n\n"
        "## Verify bundle integrity\n\n"
        "Use `MANIFEST.sha256` to confirm file hashes if needed.\n\n"
        "Read `BUNDLE_VERSION.txt` to confirm which commit this bundle came from.\n",
        encoding="utf-8",
    )
    print(f"Wrote bundle to: {OUT}")


if __name__ == "__main__":
    main()
