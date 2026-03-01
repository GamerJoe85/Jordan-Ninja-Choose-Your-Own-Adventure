# Beginner File Update Guide (Godot + GitHub)

This guide answers: **"Do I need to upload everything every time?"**

Short answer: **No**. Only changed files need to be updated.

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

## Safety check before opening Godot

```bash
python -m json.tool data/story_pages.json > /tmp/story_pages.pretty.json
python scripts/tools/validate_story_data.py
```

If both pass, your story data and required file structure are valid.
