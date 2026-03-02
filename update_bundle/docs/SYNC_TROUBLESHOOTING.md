# Sync Troubleshooting (Why updates look unchanged)

If the game still looks old, it usually means your Godot project folder is not on the latest commit.

## 1) Confirm you are in the correct folder

```bash
pwd
```

You should be in the folder that contains `project.godot`.

## 2) Check your recent commits

```bash
git log --oneline -n 10
```

For this repo, you should see recent commits like:
- `9507167` (stale-data troubleshooting docs)
- `0285722` (Act I Page 6 Exile sequence compatibility fix)

If you do not see those, your local copy is behind.

## 3) Check whether a GitHub remote is configured

```bash
git remote -v
```

If this prints nothing, your repo is local-only right now and cannot `git pull` from GitHub until a remote is added.

## 4) Pull latest changes (if remote exists)

```bash
git pull
```

Then reopen Godot from the same folder.

## 5) Verify the specific Act I Exile fix is present

```bash
python - <<'PY'
import json
from pathlib import Path
j = json.loads(Path('data/story_pages.json').read_text())
by = {p['page_id']: p for p in j['pages']}
print('Page 5 next ->', by['act1_p05_turning']['choices'][0]['next_page_id'])
print('Page 6 title ->', by['act1_p06_discipline']['story_text'].split('\n')[0])
PY
```

Expected output:
- `Page 5 next -> act1_p06_discipline`
- `Page 6 title -> Page 6 — The Frozen Peaks`
