# Write Your Own Scenes (Text + Images)

This project is made so you can edit **every scene** yourself.

## Where to edit scene text

Open:

- `data/story_pages.json`

Each scene/page is one object with:

- `page_id`
- `story_text`  ← edit this line to write your own words
- `image_path`  ← image path for that page
- `choices`

## Where to put scene images

Put files in:

- `assets/images/`

Use paths like:

- `res://assets/images/my_scene_image.png`

Then set that path in the page's `image_path`.

## Easy image method (no JSON path typing)

You can also set images in Godot Inspector:

1. Open `scenes/Main.tscn`
2. Click `PagePlayer`
3. Find `Image Overrides`
4. Add entry:
   - `page_id` = your page id (example: `act1_p05_vow`)
   - `image` = pick texture

`Image Overrides` are used first. `image_path` is fallback.

## Writing style for 10-year-old readers

Use short, clear lines:

- 1–2 short sentences per page.
- Simple words.
- Strong action words.
- Avoid big technical words.

Example:

- Hard: "Jordan calibrates his tactical approach amid escalating volatility."
- Better: "Jordan takes a breath and picks his next move."

## Quick check before running

```bash
python -m json.tool data/story_pages.json > /tmp/story_pages.pretty.json
python scripts/tools/validate_story_data.py
```


## If images still do not show

Check these 4 things:

1. File is really inside `assets/images/`.
2. Path starts with `res://assets/images/`.
3. File extension matches (`.png`, `.jpg`, `.jpeg`, or `.webp`).
4. `page_id` image override is mapped to the right page.

Good news: runtime now tries fallback filenames too:

- `res://assets/images/<page_id>.png` (and jpg/jpeg/webp)
- legacy format like `act1_05_vow.png` for page id `act1_p05_vow`
