# Papercuts

## 2026-08-28: Skill validator is not executable

Running the skill validator directly failed with `permission denied` at `/Users/jonahjacobsen/.codex/skills/.system/skill-creator/scripts/quick_validate.py`. Running it with `uv run python` then failed because PyYAML is not installed. The validator would also reject the existing `compatibility` frontmatter field. Manual validation with Ruby checked the changed skill without adding a package or changing unrelated metadata

## 2026-09-19: Remote CLI tools on pi5

`ssh pi5 'hermes cron --help'` failed with `hermes: command not found`. Non-interactive SSH does not include `~/.local/bin` in PATH. Use `~/.local/bin/hermes` for remote CLI commands. `jq` is also unavailable, so read cron JSON with Python through `~/.local/bin/uv run --no-project python`
