---
name: daily-todos
description: Generate a daily to-do list from freeform text for today, tomorrow, or a given date. Parse tasks and append them to a Markdown checklist in .todos/, and carry over unfinished tasks to the next day.
---

# Daily To-Do List Generator

Create or extend a day's to-do list from freeform text input, or carry over unfinished tasks to the next day.

## Target date

- Default: **today**
- Also accepted: `tomorrow` / `明天` (plan the night before), or an explicit `YYYY-MM-DD`
- Always use the user's local date (Asia/Shanghai), not UTC:
  - Today: `TZ=Asia/Shanghai date +%F`
  - Tomorrow: `TZ=Asia/Shanghai date -d tomorrow +%F`
- Validate explicit dates; if invalid, ask the user to correct it

## Your task

The user will provide a text description of their tasks (optionally with a target date). Your job is to:

1. **Resolve** the target date (see above)

2. **Parse** the input text to extract individual tasks
   - Split by common delimiters (commas, semicolons, newlines, Chinese punctuation like `、`)
   - Keep each task concise and actionable
   - Strip extra whitespace

3. **Write** the Markdown file:
   - Filename: `.todos/YYYY-MM-DD.md` (target date in ISO format)
   - Content: A `# YYYY-MM-DD` header followed by a checklist
   - Format: Each task as `- [ ] Task description`
   - If the file **does not exist**, create it with the header and tasks
   - If the file **already exists**, append the new tasks to the end of the checklist; never overwrite
     - Skip duplicates: a task is a duplicate if its text (trimmed) matches an existing item, whether `- [ ]` or `- [x]`
     - Keep existing items, their order, and their `[x]` states unchanged

4. **Save** the file to `.todos/` (create the directory if needed)

5. **Report** the result to the user:
   - Show the target date and whether the file was created or appended to
   - List tasks added and any skipped as duplicates
   - Be encouraging and brief

## Carry over

When the user asks to carry over (e.g. "carry over", "顺延", "把没做完的挪到明天"):

1. Source: today's file `.todos/<today>.md`; target: the next day `.todos/<today+1>.md` (dates in Asia/Shanghai)
2. Collect every unchecked `- [ ]` item from the source; ignore `- [x]` items
3. If the target file doesn't exist, create it with the `# YYYY-MM-DD` header
4. Append the items to the target, skipping duplicates (same rule as above); keep existing target items and `[x]` states
5. Leave the source file unchanged
6. Report how many items were carried over and how many were skipped; if there are none (or no source file), say so

## Examples

User input: `"开会、写代码、复查PR、修复auth bug"`

Generate file `.todos/2024-01-15.md`:
```
# 2024-01-15

- [ ] 开会
- [ ] 写代码
- [ ] 复查PR
- [ ] 修复auth bug
```

Later, user input: `"写代码、发周报"` when `写代码` is already done:
```
# 2024-01-15

- [ ] 开会
- [x] 写代码
- [ ] 复查PR
- [ ] 修复auth bug
- [ ] 发周报
```
(`写代码` skipped as duplicate, `[x]` kept.)

User input: `"carry over"` on 2024-01-15 → `.todos/2024-01-16.md`:
```
# 2024-01-16

- [ ] 开会
- [ ] 复查PR
- [ ] 修复auth bug
- [ ] 发周报
```

## Important rules

- If no tasks can be extracted, fail gracefully and ask the user to provide clearer input
- If `.todos/` doesn't exist, create it
- Never overwrite an existing day's file: append and skip duplicates, preserving `[x]` states
- All tasks go into ONE file per day, not separate files
- Keep task descriptions short (one sentence each)
- Dates are the user's local date (Asia/Shanghai)

## Handling edge cases

- **Empty input**: Politely ask for a valid task description
- **Very long input**: Still parse all of it, don't truncate
- **Special characters**: Keep them (they help with localization)
- **Duplicates within the input**: Add each task only once
