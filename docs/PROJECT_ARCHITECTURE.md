# Fire Chapter Project Architecture (Godot 4.6)

## Quick plain-language map (for beginners)

- `project.godot`: the **project file** Godot opens.
- `scenes/*.tscn`: the **screens** you see (menu, gameplay UI, act wrappers).
- `scripts/**/*.gd`: the **logic** that makes buttons, choices, and state work.
- `data/story_pages.json`: the **story database** (all pages + choices).
- `docs/*`: human-readable notes and setup guides.

If a change only touches `scripts/` or `data/`, you do **not** need to rebuild the whole project. Update only changed files (or pull latest with Git).

## Folder structure

- `project.godot`
- `scenes/`
  - `TitleMenu.tscn` (optional launcher)
  - `Main.tscn` (runtime controller)
  - `PagePlayer.tscn` (reusable page UI)
  - `acts/`
    - `Act1.tscn` ... `Act6.tscn` (lightweight wrappers)
- `scripts/`
  - `singletons/game_state.gd` (Autoload runtime state)
  - `controllers/main.gd`
  - `controllers/title_menu.gd`
  - `ui/page_player.gd`
  - `acts/act_wrapper.gd`
  - `tools/validate_story_data.py` (data + file-structure validation)
- `data/story_pages.json` (authoritative story/page content)
- `assets/images/` (still-image backgrounds, one path per page)

## Naming conventions

- **Scenes**: `PascalCase.tscn` for root scenes (`Main`, `TitleMenu`, `PagePlayer`), `Act#.tscn` for act wrappers.
- **Scripts**: `snake_case.gd`.
- **Page IDs**: `act#_...` (`act1_start`, `act5_start`, etc.).
- **Flags**: `snake_case` booleans (`detected`, `cavern_found`).
- **State values**:
  - Health tiers: `Prime | Healthy | Wounded | Critical | Dying`
  - Hook state: `Good | Damaged | Lost`
  - Disciplines: `Reflex | Focus | Steel | Shadow`

## Data contract (`data/story_pages.json`)

Each page object uses deterministic fields only:

- `page_id` (string)
- `act_id` (string)
- `image_path` (string)
- `story_text` (string)
- `choices` (array, 1-4)
  - `label` (string)
  - `requirements` (optional dictionary)
  - `effects` (dictionary)
  - `next_page_id` (string)

No random fields are used, and all progression is explicit through requirements/effects.
