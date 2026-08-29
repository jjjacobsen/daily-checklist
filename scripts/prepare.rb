#!/usr/bin/env ruby
# Prepares tomorrow's daily note in the Obsidian vault.
#
# - creates <tomorrow>.md from daily-template.md
# - adds tasks due from recurring.md, then advances or removes them
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
recurring_path = File.join(vault, "recurring.md")

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

# Returns the next date for intervals such as 1d, 2w, 3mo, 1y, or Mon,Wed,Fri
def advance(date, interval)
  weekdays = %w[Sun Mon Tue Wed Thu Fri Sat]
  if interval.match?(/\A(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)(?:,(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat))*\z/)
    scheduled_days = interval.split(",")
    date += 1
    date += 1 until scheduled_days.include?(weekdays[date.wday])
    return date
  end

  amount, unit = interval.match(/\A([1-9]\d*)(d|w|mo|y)\z/)&.captures
  raise "invalid recurring interval: #{interval}" unless amount

  case unit
  when "d" then date + amount.to_i
  when "w" then date + (amount.to_i * 7)
  when "mo" then date >> amount.to_i
  when "y" then date >> (amount.to_i * 12)
  end
end

# Returns tasks due on or before due_on and advances their dates in the table
def recurring_tasks(lines, due_on)
  header_index = lines.index { |line| line.split("|").map(&:strip).include?("Next Due") }
  raise 'no recurring table with a "Next Due" column' unless header_index

  header = lines[header_index].split("|", -1).map(&:strip)
  task_index = header.index("Task")
  due_index = header.index("Next Due")
  interval_index = header.index("Interval")
  raise 'recurring table must have "Task", "Next Due", and "Interval" columns' unless task_index && due_index && interval_index

  tasks = []
  updated = lines.dup
  one_time_rows = []
  lines[(header_index + 2)..].each_with_index do |line, offset|
    columns = line.split("|", -1)
    next unless columns.length == header.length

    task = columns[task_index].strip
    next_due = Date.iso8601(columns[due_index].strip)
    interval = columns[interval_index].strip
    next if next_due > due_on

    tasks << task
    row_index = header_index + 2 + offset
    if interval == "-"
      one_time_rows << row_index
      next
    end

    next_due = advance(next_due, interval) while next_due <= due_on
    columns[due_index] = columns[due_index].sub(/\S+/, next_due.to_s)
    updated[row_index] = columns.join("|")
  end

  one_time_rows.reverse_each { |index| updated.delete_at(index) }
  [tasks, updated]
end

# Removes obsidian links: [[target]] -> target, [[target|display]] -> display
def delink(line)
  line.gsub(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/) { Regexp.last_match(2) || Regexp.last_match(1) }
end

template_lines = read_lines(template_path)
backlog_items = open_loops(read_lines(backlog_path))
recurring_items, recurring_lines = recurring_tasks(read_lines(recurring_path), tomorrow)
today_lines = read_lines(today_path)

# Carry over today's unchecked items, then remove their links in today's note
from, to = checklist_range(today_lines)
unchecked = today_lines[from...to].select { |line| line.start_with?("- [ ] ") }
today_lines[from...to] = today_lines[from...to].map do |line|
  line.start_with?("- [ ] ") ? delink(line) : line
end

# Assemble tomorrow's checklist: recurring items, backlog items, carried items
from, to = checklist_range(template_lines)
items = []
seen = []
(recurring_items.map { |item| "- [ ] #{item}" } +
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
File.write(recurring_path, recurring_lines.join("\n") + "\n")

puts tomorrow_path
