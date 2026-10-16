---
name: daily-todos
description: Use when the user assigns a daily to-do for today, tomorrow, or a given date, carries unfinished tasks into a new day, or records a completion or remark in `.todos/`.
---

# Daily todos

One file per day: `.todos/YYYY-MM-DD.md` in the repo the user named. For the brain vault, that repo is `~/brain`.

Dates are the user's local calendar day in Asia/Shanghai. Default target is today. `tomorrow` / `明天` is the next local day. An explicit `YYYY-MM-DD` is used after it validates; an invalid date is a question, and nothing is written.

- Today: `TZ=Asia/Shanghai date +%F`
- Tomorrow: `TZ=Asia/Shanghai date -d tomorrow +%F`

```markdown
# 2026-10-16

- [ ] 01: Look into REA https://github.com/morluto/rea
- [x] 02: Organize the todos folder

---

## Notes

- 02: Moved it into brain and kept one file per day
```

A checklist line is `- [ ] NN: short title`, with an optional link at the end. A note line is `- NN:` followed by the note. The same `NN` ties them. Numbers run `01`–`99`. A number already in the file stays on that task when lines are removed or reordered. The next task takes the highest `NN` plus one. A new file starts at `01`.

## Assign

Each non-empty input line is one task. Commas and `、` stay inside the title. When the input is a single line and the tasks are not already one per line, ask for one task per line and write nothing. Repeated titles in the same input are added once.

Create `.todos/` when it is missing. Read the day's file when it exists. Append each new task as `- [ ] NN: title` on the checklist, above `---` when a record section exists. A title that already appears on a checklist line, checked or not, is skipped. Leave every existing line as it is, including checks, record lines, and linked files.

Done when the new lines are on disk and you have told the user the date, whether the file was created or extended, the lines added, and any titles skipped.

## Record

Mark `[x]` in the same edit that writes the record line `- NN: ...`. The record line says what got done. An unfinished task stays `[ ]`, and its record line says why.

Write the note under `## Notes`. Create the `---` and `## Notes` heading with the first note. Until then the file is only the checklist.

Keep the note in the day's file, even when it runs past one line. The day's checklist stays one file.

A long note can live beside the day file as `.todos/YYYY-MM-DD.NN.md`, linked from the note line. That file is for a note longer than one screen, at least 100 characters. Leave the split to the user. When you are reading and a note is already that long, suggest the `.todos/YYYY-MM-DD.NN.md` name and wait. When the repo already has the note, suggest linking that file.

Done when the checkbox and the matching note line agree, and any split suggestion names the `.NN.md` file without creating it.

## Next day

When the user asks to carry unfinished tasks forward, copy each still-open task's short title and trailing link from the source day into the target day's checklist. Number the copied lines from the target's next `NN` (a new file starts at `01`). Skip titles the target already has. The source file, its records, and its linked files stay where they are.

Done when you have reported how many lines were copied and how many titles were skipped. When the source file is missing or has no open tasks, say so and write nothing.

## Ask first

Ask, and write nothing, when the input is empty, when no line is a task, when the date is invalid, or when the named number is not in the file.
