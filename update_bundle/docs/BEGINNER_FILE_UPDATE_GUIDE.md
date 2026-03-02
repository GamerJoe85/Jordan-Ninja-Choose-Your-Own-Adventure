# Beginner File Update Guide (Godot + GitHub)

This guide answers: **"Do I need to upload everything every time?"**

Short answer: **No**. Only changed files need to be updated.

Need a full reset walkthrough? See `docs/START_HERE_NOOB.md`.

If updates seem unchanged, see `docs/SYNC_TROUBLESHOOTING.md`.

## Easiest workflow (recommended)

1. Keep one project folder on your computer.
2. Open that same folder in Godot each time.
3. Pull new commits from GitHub into that folder.
4. Godot will use updated files automatically.

## How to see exactly what changed

Run this in your project folder:

```bash
git show --name-only --oneline -n 1
```

That command prints the last commit and every file changed in it.

## What each file type means

- `.gd` = script logic (game behavior)
- `.tscn` = scene layout (nodes/UI setup)
- `.json` = story data/content
- `project.godot` = project settings entry point

## If you are not using Git locally

You can still copy only changed files manually:

1. Download changed files from GitHub.
2. Replace matching local files in your Godot project folder.
3. Reopen project (or reload scenes/scripts in Godot).

## Typical example

If a commit changes only:

- `scripts/controllers/title_menu.gd`
- `scenes/TitleMenu.tscn`

Then you only update those two files locally.


## If game still shows old pages after reopening Godot

Run these in your project folder:

```bash
pwd
git log --oneline -n 5
git pull
git log --oneline -n 5
```

Then fully close and reopen Godot on the same folder (the one containing `project.godot`).

Quick check for the Exile flow in current data:

```bash
python - <<'PY2'
import json
from pathlib import Path
j=json.loads(Path("data/story_pages.json").read_text())
by={p["page_id"]:p for p in j["pages"]}
print("Page 5 ->", by["act1_p05_turning"]["choices"][0]["next_page_id"])
print("Page 6 title:", by["act1_p06_discipline"]["story_text"].split("\n")[0])
PY2
```

Expected output includes:
- `Page 5 -> act1_p06_discipline`
- `Page 6 title: Page 6 — The Frozen Peaks`

## Safety check before opening Godot

```bash
python -m json.tool data/story_pages.json > /tmp/story_pages.pretty.json
python scripts/tools/validate_story_data.py
```

If both pass, your story data and required file structure are valid.


## How to assign a picture to every story page in Godot

You can now set per-page images directly on the `PagePlayer` node in the Inspector:

1. Open `scenes/Main.tscn`.
2. Click the `PagePlayer` node.
3. In Inspector, find **Image Overrides**.
4. Increase array size and add one entry per page.
5. For each entry:
   - set `page_id` to the exact page id from `data/story_pages.json` (example: `act2_roof_a1`),
   - assign the `image` texture you want.

At runtime, `PagePlayer` uses your Inspector override image first. If no override exists, it falls back to `image_path` from JSON.


## Where this folder is in your repo

In this repository, put your story images here:

- `assets/images/` (Godot path: `res://assets/images/`)

If you do not see it in Godot's FileSystem panel, click **Scan** or restart the editor after pulling latest files.


## I do not know which photo goes where

Use `docs/IMAGE_ASSIGNMENT_CHECKLIST.md`. It lists every `page_id` and its expected image path in one table.
