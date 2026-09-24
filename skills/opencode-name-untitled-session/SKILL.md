---
name: opencode-name-untitled-session
description: Rename opencode sessions stuck with the default time-format title ("New session - <timestamp>") to content-based titles. Use when the user asks to name, title, or clean up unnamed opencode sessions.
---

# Opencode Session Title

Find opencode sessions that never got a real title and rename them based on
what was actually discussed in each conversation.

## Scope rule

Only touch titles in the **default time format**:

```text
New session - 2026-09-24T01:22:27.078Z
```

Do **not** touch other auto-generated titles such as `Git commit`,
`Greeting`, or `Empty chat ...` — those are opencode's own summaries and are
out of scope unless the user explicitly asks for them.

## Workflow

1. List candidates with the helper script:

```bash
python3 scripts/list-untitled.py
```

The script prints each session id, its working directory, and its first
meaningful user message (tool-call noise and file dumps are skipped).

2. Derive one short content-based title per session.
   - Keep it a concise phrase in the user's language.
   - Examples: `background worker auto-stop investigation`,
     `terminal color config fix`, `floating window rule lookup`.
   - When several sessions look similar, make the titles distinguishable,
     e.g. `dropdown console opacity tweak` vs `dropdown console height lookup`.

3. Show the `session id -> proposed title` mapping to the user and get
   confirmation before writing. Titles are subjective; never bulk-rename
   blindly.

4. Apply with a direct sqlite update (opencode has no rename command):

```bash
sqlite3 ~/.local/share/opencode/opencode.db \
  "UPDATE session SET title='<title>' WHERE id='<session_id>';"
```

   - The database runs in WAL mode; a plain `UPDATE` is safe.
   - Only update `title`. Do not touch `time_updated` so list ordering
     is preserved.

5. Verify nothing is left:

```bash
sqlite3 ~/.local/share/opencode/opencode.db \
  "SELECT COUNT(*) FROM session WHERE title LIKE 'New session%';"
```

   The count must be `0`.

6. Report the renames. Remind the user that already-open opencode TUI
   processes cache the session list — restart the TUI if old titles are
   still shown there. `opencode session list` reflects the new titles
   immediately.

## Script

- Lister: `scripts/list-untitled.py` (python3 stdlib only, read-only)
- Input: none (`--limit N` optional, default 50)
- Output: candidate sessions with first user message, or
  `no untitled sessions` when clean
