---
name: daily-checklist
description: Prepares tomorrow's daily note in Obsidian. A deterministic Ruby script builds the checklist from due recurring tasks, backlog open loops, and today's unfinished items, then AI adds email and calendar items, a principle, and a bible verse. Runs daily at 9 PM
compatibility: Requires Ruby, gws, and the system timezone set properly
---

# Daily Checklist

## Situation

Obsidian has a core plugin called "Daily notes". This plugin provides keybindings and settings for utilizing daily notes. I have mine setup so that they all exist under the `~/Documents/obsidian/daily` directory and their filename is of the format `YYYY-MM-DD`. This skill will write tomorrows note using deterministic processing from a script and then some AI generated sections

## Instructions

1. Run the deterministic script from this skill's directory. It creates tomorrow's note and prints its path

   ```bash
   ruby scripts/prepare.rb
   ```

   If the user provides a date to use as today, set `DAILY_CHECKLIST_TODAY` for the command. Treat the following day as tomorrow in all remaining steps

   ```bash
   DAILY_CHECKLIST_TODAY=YYYY-MM-DD ruby scripts/prepare.rb
   ```

   The script copies `daily-template.md`, populates its existing `## Checklist` section from due recurring tasks, backlog open loops, and today's unfinished items, and avoids duplicates. Recurring intervals can be elapsed periods such as `1d`, `2w`, `3mo`, and `1y`, or weekday schedules such as `Mon,Wed,Fri`. It also advances recurring due dates, removes due one-time tasks, and removes Obsidian links from carried items in today's note. If tomorrow's note already exists, use it and continue with the steps below

2. Use `gws` to fetch my email and calendar information. Add anything important for tomorrow to the `## Checklist` section of the note as new `- [ ] ` items (appointments, deadlines, emails that need action). Do not add things already on the list

   First, list my calendars. Fetch tomorrow's events from every calendar whose `selected` field is `true`, not only the primary calendar. The selected calendars should include Jonah Jacobsen, one of the two calendars named Birthdays, Christian and U.S. Holidays, Church, Fun, and Roadmap. Use the `selected` field to distinguish the two Birthdays calendars. Do not fetch events from the unselected Birthdays or Tasks calendars

   ```bash
   gws gmail users messages list --params '{"userId": "me", "maxResults": 10}'
   gws calendar calendarList list --params '{}'
   gws calendar events list --params '{"calendarId": "<selected-calendar-id>", "timeMin": "<tomorrow>T00:00:00Z", "timeMax": "<tomorrow+1>T00:00:00Z", "singleEvents": true, "orderBy": "startTime"}'
   ```

   Run the events command once for each selected calendar ID

3. Populate the existing `## Principle` section in the note. Choose a random top-level bullet from anywhere in `~/Documents/obsidian/principles.md` (any section, not just "My own thoughts"). Copy the bullet and its indented sub-bullets. Do not repeat a principle used in the past week of daily notes

4. Populate the existing `## Daily Verse` section. Fetch a random verse and write its text and reference (Book Chapter:Verse) as-is. The translation is KJV, do not modify the wording

   ```bash
   curl -s 'https://bible-api.com/data/kjv/random'
   ```

5. After all sections are populated, ensure there are exactly two blank lines before each subsequent H2 heading. Do not leave a checklist item, principle, or verse directly adjacent to the next `##` heading
