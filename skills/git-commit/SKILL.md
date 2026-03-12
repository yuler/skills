---
name: git-commit
description: Generate a concise, human-readable git commit message from the staged diff with a leading emoji, then run `git commit` to complete the commit. Use when the user wants to commit changes, asks for a commit message, or needs a summary of staged changes. Start by running `./scripts/git-diff.sh`, which reads the staged diff while excluding common lock files such as `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `bun.lockb`, `Gemfile.lock`, `uv.lock`, `composer.lock`, `go.sum`, and `Cargo.lock`.
---

# Git Commit

## Workflow

- Run `./scripts/git-diff.sh` to inspect the staged diff.
- Use the script output instead of raw `git diff` so common lock files are excluded.
- If the script returns `No changes to commit`, report that there are no staged changes.
- Generate one concise commit message that reflects the primary change.
- Run `git commit -m "<message>"` with the generated message to complete the commit.

## Commit message format

- Write a single concise sentence.
- Begin with an emoji, followed by a space, then the message.
- Use present tense and active voice, such as `Add feature` instead of `Added feature`.
- Focus on the main change, not every small detail.


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

Pick the closest change type and keep the message concise.
