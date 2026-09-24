#!/usr/bin/env python3
"""List opencode sessions stuck with the default time-format title.

Prints each candidate with its directory and first meaningful user message,
so the agent can derive a content-based title.

Usage:
    python3 list-untitled.py [--limit N]

Only matches the default format: "New session - <ISO timestamp>".
Other auto-generated titles (e.g. "Git commit", "Greeting", "Empty chat ...")
are intentionally left alone.
"""

import json
import sqlite3
import sys
from pathlib import Path

DB = Path.home() / ".local" / "share" / "opencode" / "opencode.db"

SKIP_MARKERS = ("Called the", "<path>", "<type>")


def first_user_text(cur, session_id, max_len=300):
    cur.execute(
        """
        SELECT m.data, p.data FROM message m
        JOIN part p ON p.message_id = m.id
        WHERE m.session_id = ?
        ORDER BY m.time_created, p.time_created
        LIMIT 100
        """,
        (session_id,),
    )
    for mdata, pdata in cur.fetchall():
        try:
            md = json.loads(mdata)
            pd = json.loads(pdata)
        except (json.JSONDecodeError, TypeError):
            continue
        if md.get("role") != "user" or pd.get("type") != "text":
            continue
        text = (pd.get("text") or "").strip()
        if not text or any(m in text for m in SKIP_MARKERS):
            continue
        one_line = " | ".join(
            line.strip() for line in text.splitlines() if line.strip()
        )
        return one_line[:max_len]
    return "(no readable user message)"


def main():
    limit = 50
    if len(sys.argv) == 3 and sys.argv[1] == "--limit":
        limit = int(sys.argv[2])
    if not DB.exists():
        print(f"database not found: {DB}", file=sys.stderr)
        sys.exit(1)
    db = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    cur = db.cursor()
    cur.execute(
        """
        SELECT id, directory FROM session
        WHERE title LIKE 'New session%'
        ORDER BY time_updated DESC LIMIT ?
        """,
        (limit,),
    )
    rows = cur.fetchall()
    if not rows:
        print("no untitled sessions (default time-format titles: 0)")
        return
    for sid, directory in rows:
        print(f"{sid} | {directory}")
        print(f"  first user message: {first_user_text(cur, sid)}")
        print()
    db.close()


if __name__ == "__main__":
    main()
