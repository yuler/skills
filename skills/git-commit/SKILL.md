---
name: git-commit
description: Generate a concise, human-readable git commit message from the staged diff with a leading emoji, then run `git commit` to complete the commit. Use when the user wants to commit changes, asks for a commit message, or needs a summary of staged changes. Start by running `./scripts/git-diff.sh`, which reads the staged diff while excluding common lock files such as `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `bun.lockb`, `Gemfile.lock`, `uv.lock`, `composer.lock`, `go.sum`, and `Cargo.lock`.
---

# Git Commit

## Quickstart

Use this skill when the user wants to **commit** current work (or wants help writing a commit message) based on the **staged diff**.

### What this skill does

- Reads repo/global config and exports normalized env vars.
- Runs an optional **pre** hook (failure aborts the commit).
- Generates a **single-line** commit subject from the **staged diff** (via `skills/git-commit/scripts/git-diff.sh`).
- Optionally prepends a gitmoji-style emoji.
- Runs `git commit -m "<subject>"`.
- Runs an optional **post** hook (failure is reported, commit is not rolled back).

## Workflow (required order)

- Load config into env vars via `eval "$(skills/git-commit/scripts/git-commit-config.sh export)"`.
- Run pre hook (abort on failure) via `skills/git-commit/scripts/git-commit-hooks.sh pre`.
- Run the skill-local script at `skills/git-commit/scripts/git-diff.sh` to obtain the staged file changes.
- Use the script output instead of raw `git diff` so common lock files are excluded.
- If the script returns `No changes to commit`, report that there are **no staged changes** and stop.
- Build the commit-message rules:
  - Start from the default rules in **Commit message rules** below.
  - If `GIT_COMMIT_PROMPT` is set and not empty, **replace** the default rules with that value.
- Generate a concise commit **subject** that reflects the primary change (subject line only).
- Pick an emoji only if `GIT_COMMIT_EMOJI=true`; otherwise do not prepend emoji.
- Build the final commit subject line as:
  - With emoji: `<emoji> <subject>`
  - Without emoji: `<subject>`
- Run `git commit -m "<subject>"` with the final subject to complete the commit.
- Run post hooks (report failures, do not undo commit) via `skills/git-commit/scripts/git-commit-hooks.sh post`.

## Commit message rules

Use `GIT_COMMIT_PROMPT` when this environment variable exists and is not empty.

If `GIT_COMMIT_PROMPT` does not exist or is empty, use the default rules below:

- Write **one** concise commit subject line in **imperative mood** (e.g. “Add…”, “Fix…”, “Refactor…”).
- Focus on the primary change, not every small detail.
- Keep the subject line concise (typically \( \le 72 \) chars).

## Emoji handbook (gitmoji.dev)

Use these common mappings when `GIT_COMMIT_EMOJI=true`:

| Change type                | Emoji | Example                         |
|---------------------------|-------|---------------------------------|
| New feature               | ✨    | ✨ Add login form               |
| Bug fix                   | 🐛    | 🐛 Fix date timezone parsing    |
| Critical hotfix           | 🚑️   | 🚑️ Patch production auth crash |
| Documentation             | 📝    | 📝 Update API usage docs        |
| Code format / structure   | 🎨    | 🎨 Reformat linted modules      |
| UI style updates          | 💄    | 💄 Refresh button styles        |
| Refactor                  | ♻️    | ♻️ Extract auth token helper    |
| Performance               | ⚡️   | ⚡️ Reduce image decode cost     |
| Add dependency            | ➕    | ➕ Add zod for schema checks     |
| Remove dependency         | ➖    | ➖ Remove unused lodash          |
| Upgrade dependencies      | ⬆️   | ⬆️ Upgrade React to 19          |
| Downgrade dependencies    | ⬇️   | ⬇️ Downgrade Vite for stability |
| Configuration files       | 🔧    | 🔧 Add ESLint rule              |
| Dev scripts / tooling     | 🔨    | 🔨 Add pre-commit script        |
| Tests                     | ✅    | ✅ Add unit tests for parser    |
| CI build                  | 💚    | 💚 Fix flaky CI node setup      |

Prefer the closest semantic match from gitmoji. Keep the subject concise and focused on the primary change.

## Configuration (`.git-commit.json`)

This skill supports a JSON config file named `.git-commit.json` at two levels.

### Config precedence and discovery

- Global defaults: `~/.git-commit.json`
- Repo override: `<git-root>/.git-commit.json`
- Merge order: **global first, then repo overrides**

After load, the helper script exports:

- `GIT_COMMIT_DEBUG`: `true` / `false`
- `GIT_COMMIT_EMOJI`: `true` / `false`
- `GIT_COMMIT_PROMPT`: custom commit-message rules text (replaces this file's default rules when non-empty)
- `GIT_COMMIT_HOOK_PRE`: pre hook string (script path or inline shell)
- `GIT_COMMIT_HOOK_POST`: post hook string (script path or inline shell)

### Schema

```json
{
  "debug": false,
  "emoji": true,
  "prompt": [
    "Write imperative commit subject under 60 chars.",
    "Use imperative mood and active voice."
  ],
  "hooks": {
    "pre": "./scripts/commit-pre.sh",
    "post": "echo \"Committed: $(git rev-parse --short HEAD)\""
  }
}
```

- `debug` (boolean, optional): default `false`. Enable verbose debug logging.
- `emoji` (boolean, optional): default `true`.
- `prompt` (string or string[], optional): custom rules text to replace default `SKILL.md` commit rules. Arrays are joined with newlines.
- `hooks.pre` (string, optional): pre hook, either:
  - path to a script file (relative to repo root, or absolute), or
  - inline shell content executed by `bash -lc`.
- `hooks.post` (string, optional): post hook with the same behavior as `hooks.pre`.

Notes:

- `prompt` is treated as **replacement** text, not an append/merge.
- Hooks run with CWD set to the detected git root when available.

## Debugging

Set `"debug": true` in `.git-commit.json` or `GIT_COMMIT_DEBUG=true` as an env var to enable verbose logging. Debug output is written to stderr with `[...:debug]` prefixes and includes:

- Config file discovery and parse results
- Merged and normalized JSON
- Exported environment variable values
- Hook resolution, paths, and execution details

Example: `GIT_COMMIT_DEBUG=true eval "$(skills/git-commit/scripts/git-commit-config.sh export)"`

Additional notes:

- Config and hooks are implemented in bash; the helper script requires `jq` for JSON.
- Use `skills/git-commit/scripts/git-commit-config.sh print` to inspect the normalized effective config.
- If you only want per-repo overrides, create `<git-root>/.git-commit.json` and set only the fields you need.
- Example templates are in `skills/git-commit/assets/`.
