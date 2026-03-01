# START HERE (Noob-Friendly) — Regenerate the Project Cleanly

If things feel confusing, use this exact reset flow.

## 1) Confirm you are in the project folder

You should see `project.godot` in the root.

## 2) Confirm key folders exist

You should have:

- `data/`
- `scenes/`
- `scripts/`
- `assets/images/`

If `assets/images/` is missing, create it.

## 3) Put your images in the right place

Copy all artwork into:

- `assets/images/`  
  (Godot path format: `res://assets/images/your_file.png`)

## 4) Open Godot project correctly

- Open Godot.
- Click **Import**.
- Select this repo folder (the folder that contains `project.godot`).

## 5) Assign image for first page (quickest proof)

Two ways:

### Option A: JSON path
- Open `data/story_pages.json`.
- First page is `page_id: "act1_start"`.
- Set `image_path` to your real file path like `res://assets/images/act1_01_overlook.png`.

### Option B: Inspector override (recommended for noobs)
- Open `scenes/Main.tscn`.
- Click node: `PagePlayer`.
- In Inspector: **Image Overrides**.
- Add one entry:
  - `page_id = act1_start`
  - `image =` pick your texture file.

## 6) Run basic validation before pressing Play

```bash
python -m json.tool data/story_pages.json > /tmp/story_pages.pretty.json
python scripts/tools/validate_story_data.py
```

If both pass, your files are structurally valid.

## 7) If Godot still looks wrong, do this refresh

- In Godot FileSystem dock: click **Scan**.
- Close and reopen Godot.
- Re-open `scenes/Main.tscn` and verify `PagePlayer` still has image override entries.

## 8) Play test

- Press Play in Godot.
- Click Start.
- First page should show your chosen image.

---

## What "regenerate everything" means in plain words

It does **not** mean rebuilding code from scratch every time.
It means:

1. Make sure folder structure is present.
2. Make sure JSON is valid.
3. Make sure images are in `assets/images/`.
4. Make sure `PagePlayer` image overrides are filled for pages you want visuals on.
