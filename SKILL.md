---
name: daily-checklist
description: Prepares tomorrow's daily note in Obsidian. A deterministic Ruby script builds the checklist from due recurring tasks, backlog open loops, and today's unfinished items, then AI adds email and calendar items, a principle, a bible verse, and a zig coding challenge. Runs daily at 9 PM
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

   The script copies `daily-template.md` and populates its existing `## Checklist` section. It adds tasks from `recurring.md` whose `Next Due` date is tomorrow or earlier, then advances each due date by its interval. Supported intervals are days (`1d`), weeks (`1w`), months (`1mo`), and years (`1y`), with any positive number. It also appends the first-level items from the `## Open Loops` section of `backlog.md`, carries over today's unchecked checklist items (an item already on the list is not added twice), and removes obsidian links from the unchecked items in today's note. Checked items keep their links. If the script fails because the note already exists, use that note and continue with the steps below

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

5. Populate the existing `## Daily Challenge` section. Write one somewhat easy coding problem in the style of a LeetCode prompt: a title, a problem statement, constraints, and an example input and output. Gear it toward Zig and include Zig-specific requirements where natural (slices, allocators, optionals, error unions, comptime). Only the prompt is needed, no test framework and no solution. Do not repeat a problem from the past week of daily notes
