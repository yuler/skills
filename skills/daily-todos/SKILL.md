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

- 01: [ ] 调研 REA https://github.com/morluto/rea
- 02: [x] 整理 todos 文件夹

---

## 记录

- 02: 收进 brain，之后按天记
```

A checklist line is `- NN: [ ] short title`, with an optional link at the end. A record line is `- NN: one sentence`. The same `NN` ties them. Numbers run `01`–`99`. A number already in the file stays on that task when lines are removed or reordered. The next task takes the highest `NN` plus one. A new file starts at `01`.

## Assign

Each non-empty input line is one task. Commas and `、` stay inside the title. When the input is a single line and the tasks are not already one per line, ask for one task per line and write nothing. Repeated titles in the same input are added once.

Create `.todos/` when it is missing. Read the day's file when it exists. Append each new task as `- NN: [ ] title` on the checklist, above `---` when a record section exists. A title that already appears on a checklist line, checked or not, is skipped. Leave every existing line as it is, including checks, record lines, and linked files.

Done when the new lines are on disk and you have told the user the date, whether the file was created or extended, the lines added, and any titles skipped.

## Record

Mark `[x]` in the same edit that writes the record line `- NN: ...`. The record line says what got done. An unfinished task stays `[ ]`, and its record line says why.

Write the record under `## 记录`. Create the `---` and `## 记录` heading with the first record. Until then the file is only the checklist.

A record is one line. When the note is longer than one line, write `.todos/YYYY-MM-DD/NN.md` and put a Markdown link to it on that line. When the repo already has the note, link that file. The day's checklist stays one file.

Done when the checkbox and the matching record line agree, and any longer note is a separate file the record line links.

## Next day

When the user asks to carry unfinished tasks forward, copy each still-open task's short title and trailing link from the source day into the target day's checklist. Number the copied lines from the target's next `NN` (a new file starts at `01`). Skip titles the target already has. The source file, its records, and its linked files stay where they are.

Done when you have reported how many lines were copied and how many titles were skipped. When the source file is missing or has no open tasks, say so and write nothing.

## Ask first

Ask, and write nothing, when the input is empty, when no line is a task, when the date is invalid, or when the named number is not in the file.
