#!/usr/bin/env ruby
# Prepares tomorrow's daily note in the Obsidian vault.
#
# - creates <tomorrow>.md from daily-template.md
# - appends the first-level items from "## Open Loops" in backlog.md
# - carries over today's unchecked checklist items (no duplicates)
# - removes obsidian links from the unchecked items in today's note
#
# Usage: ruby prepare.rb [vault-dir]   (defaults to ~/Documents/obsidian)

require "date"

vault = ARGV[0] || File.expand_path("~/Documents/obsidian")
daily_dir = File.join(vault, "daily")
template_path = File.join(daily_dir, "daily-template.md")
backlog_path = File.join(vault, "backlog.md")

today = Date.today
tomorrow = today + 1
today_path = File.join(daily_dir, "#{today}.md")
tomorrow_path = File.join(daily_dir, "#{tomorrow}.md")

raise "#{tomorrow_path} already exists" if File.exist?(tomorrow_path)

def read_lines(path)
  raise "#{path} does not exist" unless File.exist?(path)
  File.readlines(path, chomp: true)
end

# Returns the [start, end) line range of the "## Checklist" section
def checklist_range(lines)
  heading = lines.index { |line| line.start_with?("## Checklist") }
  raise "no ## Checklist heading" unless heading
  offset = lines[(heading + 1)..].index { |line| line.start_with?("#") }
  [heading + 1, offset ? heading + 1 + offset : lines.length]
end

# First-level list items under "## Open Loops"
def open_loops(lines)
  found = false
  in_section = false
  items = []
  lines.each do |line|
    if line.start_with?("#")
      found = true if line.start_with?("## Open Loops")
      in_section = line.start_with?("## Open Loops")
    elsif in_section && line.start_with?("- ")
      items << line
    end
  end
  raise 'no "## Open Loops" heading' unless found
  items
end

# Removes obsidian links: [[target]] -> target, [[target|display]] -> display
def delink(line)
  line.gsub(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/) { Regexp.last_match(2) || Regexp.last_match(1) }
end

template_lines = read_lines(template_path)
backlog_items = open_loops(read_lines(backlog_path))
today_lines = read_lines(today_path)

# Carry over today's unchecked items, then remove their links in today's note
from, to = checklist_range(today_lines)
unchecked = today_lines[from...to].select { |line| line.start_with?("- [ ] ") }
today_lines[from...to] = today_lines[from...to].map do |line|
  line.start_with?("- [ ] ") ? delink(line) : line
end

# Assemble tomorrow's checklist: template items, backlog items, carried items
from, to = checklist_range(template_lines)
items = []
seen = []
(template_lines[from...to].grep(/\A- \[/) +
 backlog_items.map { |item| "- [ ] #{item.sub(/\A- (?:\[[ xX]\] )?/, "")}" } +
 unchecked).each do |line|
  text = line[/\A- \[[ xX]\] (.*)\z/, 1]
  next if text && seen.include?(text.strip)
  seen << text.strip if text
  items << line
end

tomorrow_lines = template_lines[0...from] + items + template_lines[to..]

File.write(tomorrow_path, tomorrow_lines.join("\n") + "\n")
File.write(today_path, today_lines.join("\n") + "\n")

puts tomorrow_path
