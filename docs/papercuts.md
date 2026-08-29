# Papercuts

## 2026-08-28: Skill validator is not executable

Running the skill validator directly failed with `permission denied` at `/Users/jonahjacobsen/.codex/skills/.system/skill-creator/scripts/quick_validate.py`. Running it with `uv run python` then failed because PyYAML is not installed. The validator would also reject the existing `compatibility` frontmatter field. Manual validation with Ruby checked the changed skill without adding a package or changing unrelated metadata
