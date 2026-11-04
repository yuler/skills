---
name: md-todos
description: Use when the user assigns a to-do (for today, tomorrow, a given date, or active backlog), carries unfinished tasks forward, or records a completion or remark in `todos/`.
---

# Markdown todos

One file per month: `todos/YYYY-MM.md` in the repo the user named. For the brain vault, that repo is `~/brain`.

Dates are the user's local calendar day in Asia/Shanghai. Default target is today. `tomorrow` / `明天` is the next local day. An explicit `YYYY-MM-DD` is used after it validates; an invalid date is a question, and nothing is written.

- Today: `TZ=Asia/Shanghai date +%F`
- Tomorrow: `TZ=Asia/Shanghai date -d tomorrow +%F`
- Current month: `TZ=Asia/Shanghai date +%Y-%m`

```markdown
# 2026-11

## Active

- [ ] 01: Read "Designing Data-Intensive Applications" chapters 3-4
- [ ] 02: Renew annual domain registration (due: 2026-11-27)

---

## 2026-11-03

- [ ] 01: Research SQLite vs DuckDB for local analytics

## 2026-11-02

- [x] 01: Refactor auth middleware and update API docs
- [x] 02: Benchmark Redis cache vs in-memory LRU

### Notes

- 01: Replaced deprecated JWT parser and verified test suite passing.
- 02: In-memory cache is 4x faster for p99 latency; Redis kept only for cross-instance state.
```

## Structure

1. **Monthly file (`todos/YYYY-MM.md`)**: Starts with `# YYYY-MM`.
2. **Root pointer (`TODOS.md`)**: Repo-root symlink to the current month's `todos/YYYY-MM.md`. Opening or editing `TODOS.md` is the same file as that month. Relative target only (`todos/YYYY-MM.md`).
3. **`## Active` (top section)**: Holds cross-day, weekly, or future-due tasks that are not tied to finishing on a single day. Separated from the daily sections below by `---`. Omit `## Active` and `---` when there are no active tasks.
4. **Daily sections (`## YYYY-MM-DD`)**: Ordered **newest date first** (reverse chronological) below `---` (or below `# YYYY-MM` if `## Active` is absent). Past daily sections only retain completed tasks (`- [x]`) and notes; unfinished tasks are moved forward rather than kept as open checkboxes across days.
5. **Numbering (`NN`)**:
   - A checklist line is `- [ ] NN: short title`, with an optional link or `(due: YYYY-MM-DD)` at the end.
   - A note line is `- NN:` followed by the note under that day's `### Notes`.
   - Numbers run `01`–`99` independently within `## Active` and within each `## YYYY-MM-DD` section.
   - Checklist lines and `### Notes` lines share the same `NN`. When lines are removed, reorder `NN` on the remaining checklist items and corresponding notes if needed to eliminate gaps and keep the sequence contiguous (`01`, `02`, `03`...). A new section starts at `01`.

## Assign

Each non-empty input line is one task. Commas and `、` stay inside the title. When the input is a single line and the tasks are not already one per line, ask for one task per line and write nothing. Repeated titles in the same input are added once.

Create `todos/` and `todos/YYYY-MM.md` when missing. Point repo-root `TODOS.md` at that monthly file (`ln -sfn todos/YYYY-MM.md TODOS.md`); create the symlink if it is missing.
- **Daily task** (default today, tomorrow, or explicit `YYYY-MM-DD`): Find or insert `## YYYY-MM-DD` in reverse chronological position. Append each new task as `- [ ] NN: title` on that day's checklist, above `### Notes` when a notes subsection exists.
- **Active / long-term task** (when the user assigns a weekly, multi-day, or future-due task): Add to `## Active` at the top of the current month's file.

A title that already appears in the target section (or open in `## Active`) is skipped. Leave every existing line as it is.

Done when the new lines are on disk and you have told the user the target (`Active` or `YYYY-MM-DD`), whether the file/section was created or extended, the lines added, and any titles skipped.

## Record

- **Recording a daily task**: Mark `[x]` on the task line under `## YYYY-MM-DD` in the same edit that writes `- NN: ...` under that day's `### Notes`. Create `### Notes` with the first note for that day. An unfinished task stays `[ ]` while active on that day, and its record line says why. When carried forward to another day or `## Active`, it is moved out of the source day's checklist (see Carry forward).
- **Recording an `## Active` task**: When an item in `## Active` is completed on day `YYYY-MM-DD`, remove it from `## Active`, append it to `## YYYY-MM-DD` with that day's next `NN` marked `[x]`, and write `- NN: ...` under that day's `### Notes`. If it is only partially progressed and remains ongoing, keep it `[ ]` in `## Active` and log the progress on the day's checklist and `### Notes`.

Keep the note in the monthly file, even when it runs past one line.

A long note can live beside the monthly file as `todos/YYYY-MM-DD.NN.md`, linked from the note line. That file is for a note longer than one screen, at least 100 characters. Leave the split to the user. When you are reading and a note is already that long, suggest the `todos/YYYY-MM-DD.NN.md` name and wait. When the repo already has the note, suggest linking that file.

Done when the checkbox and the matching note line agree, and any split suggestion names the `.NN.md` file without creating it.

## Carry forward

Because tasks are consolidated in a single monthly file (`todos/YYYY-MM.md`), carry-forward balances avoiding pointless duplicate empty checklists across days with preserving daily work logs.

- **Daily open tasks**: When unfinished tasks are carried forward from a day (e.g. today to tomorrow, to a specific date, or to `## Active`):
  - **Tasks with NO notes (完全未开展 / 无备注)**: Directly delete the uncompleted `- [ ]` line from the source day so untouched tasks do not repeat across days. Move them to the target day's checklist.
  - **Tasks WITH notes (有进展 / 有备注但未完结)**: **Do NOT directly delete them** from the source day. Because progress notes, partial work, or reasons for rollover were recorded under `### Notes`, the checklist item must stay on the source day so that notes never become orphaned numbers and the day's attempt record is preserved. The ongoing task is also carried forward to the target day (or `## Active`) for next steps.
  - **Reorder indices when needed (序号整理)**: When tasks without notes are removed from the source day, reorder the remaining checklist items and their matching `### Notes` lines (e.g. `01`, `02`, `03`, `07` → `01`, `02`, `03`, `04`) to eliminate index gaps and keep numbering contiguous. Number the target day's tasks cleanly from `01` as well.
  - **Clean up empty days**: If removing moved tasks leaves the source day with neither checklist items nor notes, delete that day heading entirely.
- **New month**: When creating a new `todos/YYYY-MM.md`, move any still-open items from the previous month's `## Active` into the new month's `## Active`, and point `TODOS.md` at the new monthly file.

Done when you have reported how many lines were carried forward, which lines were retained/reordered or removed, and any titles skipped.

## Ask first

Ask, and write nothing, when the input is empty, when no line is a task, when the date is invalid, or when the named number is not in the section.
