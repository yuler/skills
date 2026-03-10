---
name: git-commit
description: Generates human-readable commit messages with leading emoji by analyzing git diff. Use when the user wants to commit, needs a commit message, or asks to summarize staged/unstaged changes. Ignores lock files (e.g. pnpm-lock.yaml).
---

## What I do

- Analyze `git diff` (or `git diff --staged`) to determine changes, explicitly ignoring bundler lock files (e.g., `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`)
- Generate a concise, single-line commit message with a leading emoji
- Exclude changes in bundler lock files from the commit summary unless those are the only files changed
- Push commits to the remote repository

## When to use me

- Use when you want to run `git commit` or generate a commit message.
- Use when you want to include all changes, including those from the stash.

## Commit message format

- Write a single, concise sentence.
- Begin with an emoji followed by a space and the message.
- Use present tense and active voice (e.g., "Add feature" instead of "Added feature").


## Emoji reference

| Change type        | Emoji | Example                    |
|--------------------|-------|----------------------------|
| New feature        | ✨    | ✨ Add login form          |
| Bug fix            | 🐛    | 🐛 Fix date timezone       |
| Documentation      | 📝    | 📝 Update API readme       |
| Style / format     | 💄    | 💄 Format with prettier    |
| Refactor           | ♻️    | ♻️ Extract auth helper     |
| Performance        | ⚡    | ⚡ Lazy load images          |
| Dependencies       | 📦    | 📦 Upgrade React to 19     |
| Config / tooling   | 🔧    | 🔧 Add ESLint rule         |

Pick the closest type; keep the message concise.
