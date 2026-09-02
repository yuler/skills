---
name: x-compose-draft
description: >-
  Draft an X (Twitter) post and open the compose box in the system default browser
  with pre-filled text. Use when the user wants to post on X/Twitter, tweet
  something, open x.com compose, or share a link on X — always wait for user
  confirmation before posting.
---

# X Compose Draft

Open **x.com** in the default browser with a pre-filled compose draft. The user
reviews and clicks **Post** themselves; never post on their behalf.

## Workflow

1. **Collect content** — Get the message from the user (rough notes are fine).
2. **Draft** — Polish obvious typos only if the user did not ask for exact wording.
   Add hashtags when requested or when they clearly help (project name, stack, topic).
3. **Show draft in chat** — Paste the full text so the user can review before the
   browser opens.
4. **Open compose** — Run the script with the final draft:

   ```bash
   scripts/open-compose.sh "Full tweet text here"
   ```

5. **Wait for confirmation** — Tell the user nothing was posted. They can:
   - Click **Post** in the browser
   - Ask for wording or hashtag changes (re-run from step 3)
   - Cancel

## Rules

- **Never** automate clicking Post or submitting the tweet.
- **Never** post without explicit user approval after they see the draft.
- Keep tweets within X length limits (~280 characters unless the user asks for a thread).
- Put URLs on their own line when the draft is long enough to benefit from it.
- On Linux use `xdg-open`; on macOS use `open` (the script handles both).

## Hashtag guidance

- Include 2–5 relevant tags: project name, platform, topic (e.g. `#Omarchy #Linux #OpenSource`).
- Avoid hashtag spam; skip tags that do not match the content.

## Example

User: "Post about my omaports plugin, repo https://github.com/yuler/omaports"

Draft shown in chat:

```text
I wrote an Omarchy plugin, omaports, to manage your ports on an Omarchy computer.
Check out the repo: https://github.com/yuler/omaports

#Omarchy #Linux #DevTools #OpenSource #omaports
```

Then run:

```bash
scripts/open-compose.sh "I wrote an Omarchy plugin..."
```
