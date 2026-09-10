# daily-checklist

Skill which prepares the daily note for tomorrow in obsidian

Utilize [gws](https://github.com/googleworkspace/cli) for access to email and calendar

Override the date treated as today when preparing a missed checklist:

```bash
DAILY_CHECKLIST_TODAY=2025-03-10 ruby scripts/prepare.rb
```

This prepares the note for the following day, `2025-03-11`
