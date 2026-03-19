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
- Run the skill-local script at `GIT_COMMIT_DIFF = skills/git-commit/scripts/git-diff.sh` to obtain the staged file changes.
- Use `$GIT_COMMIT_DIFF` as the changed content and `$GIT_COMMIT_PROMPT` as the guiding rules to generate a concise commit message.
- Run post hooks (report failures, do not undo commit) via `skills/git-commit/scripts/git-commit-hooks.sh post`.

## Emoji handbook (gitmoji.dev)

Use these common mappings when `GIT_COMMIT_EMOJI=true`:

| Change type                                                  | Emoji | Example                                    |
| :----------------------------------------------------------- | :---: | :----------------------------------------- |
| Improve structure / format of the code                       |   🎨   | 🎨 Reformat commit message helper           |
| Improve performance                                          |   ⚡️   | ⚡️ Speed up staged diff parsing             |
| Remove code or files                                         |   🔥   | 🔥 Remove unused commit hook script         |
| Fix a bug                                                    |   🐛   | 🐛 Fix emoji selection for docs commits     |
| Critical hotfix                                              |   🚑️   | 🚑️ Patch broken commit message generator    |
| Introduce new features                                       |   ✨   | ✨ Add configurable emoji mappings          |
| Add or update documentation                                  |   📝   | 📝 Document `.git-commit.json` precedence   |
| Deploy stuff                                                 |   🚀   | 🚀 Deploy updated commit hooks              |
| Add or update the UI and style files                         |   💄   | 💄 Refresh CLI prompt styling               |
| Begin a project                                              |   🎉   | 🎉 Initialize git-commit skill scaffolding  |
| Add, update, or pass tests                                   |   ✅   | ✅ Add tests for commit message formatting  |
| Fix security or privacy issues                               |   🔒️   | 🔒️ Fix unsafe shell quoting in hooks        |
| Add or update secrets                                        |   🔐   | 🔐 Add example secret injection workflow    |
| Release / Version tags                                       |   🔖   | 🔖 Tag v1.2.0                               |
| Fix compiler / linter warnings                               |   🚨   | 🚨 Fix markdown lint for handbook table     |
| Work in progress                                             |   🚧   | 🚧 WIP refine emoji heuristics              |
| Fix CI Build                                                 |   💚   | 💚 Fix CI failing on missing bash           |
| Downgrade dependencies                                       |   ⬇️   | ⬇️ Downgrade node for compatibility         |
| Upgrade dependencies                                         |   ⬆️   | ⬆️ Upgrade dev dependencies                 |
| Pin dependencies to specific versions                        |   📌   | 📌 Pin prettier to 3.3.0                    |
| Add or update CI build system                                |   👷   | 👷 Add GitHub Actions workflow              |
| Add or update analytics or track code                        |   📈   | 📈 Add commit metrics tracking              |
| Refactor code                                                |   ♻️   | ♻️ Extract emoji resolver                   |
| Add a dependency                                             |   ➕   | ➕ Add `chalk` for terminal colors          |
| Remove a dependency                                          |   ➖   | ➖ Remove unused `lodash`                   |
| Add or update configuration files                            |   🔧   | 🔧 Add repo `.git-commit.json`              |
| Add or update development scripts                            |   🔨   | 🔨 Add `scripts/git-diff.sh` helper         |
| Internationalization and localization                        |   🌐   | 🌐 Add i18n-ready commit templates          |
| Fix typos                                                    |   ✏️   | ✏️ Fix handbook wording                     |
| Write bad code that needs to be improved                     |   💩   | 💩 Add naive parser (to refactor later)     |
| Revert changes                                               |   ⏪️   | ⏪️ Revert emoji handbook update             |
| Merge branches                                               |   🔀   | 🔀 Merge main into feature branch           |
| Add or update compiled files or packages                     |   📦️   | 📦️ Update bundled release artifacts         |
| Update code due to external API changes                      |   👽️   | 👽️ Adapt to new `gh` output format          |
| Move or rename resources (e.g.: files, paths, routes)        |   🚚   | 🚚 Move hooks into `scripts/`               |
| Add or update license                                        |   📄   | 📄 Add MIT license                          |
| Introduce breaking changes                                   |   💥   | 💥 Change config schema for hooks           |
| Add or update assets                                         |   🍱   | 🍱 Add logo assets for docs                 |
| Improve accessibility                                        |   ♿️   | ♿️ Improve CLI color contrast               |
| Add or update comments in source code                        |   💡   | 💡 Clarify semver rules in prompt           |
| Write code drunkenly                                         |   🍻   | 🍻 Spike experimental commit generator      |
| Add or update text and literals                              |   💬   | 💬 Update default commit prompt             |
| Perform database related changes                             |   🗃️   | 🗃️ Add migrations for commit metadata store |
| Add or update logs                                           |   🔊   | 🔊 Add debug logging for emoji selection    |
| Remove logs                                                  |   🔇   | 🔇 Remove noisy debug output                |
| Add or update contributor(s)                                 |   👥   | 👥 Add new contributor to AUTHORS           |
| Improve user experience / usability                          |   🚸   | 🚸 Simplify interactive commit flow         |
| Make architectural changes                                   |   🏗️   | 🏗️ Restructure skills layout                |
| Work on responsive design                                    |   📱   | 📱 Improve mobile docs layout               |
| Mock things                                                  |   🤡   | 🤡 Mock git output in tests                 |
| Add or update an easter egg                                  |   🥚   | 🥚 Add hidden "gitmoji" command             |
| Add or update a .gitignore file                              |   🙈   | 🙈 Add `.env` to `.gitignore`               |
| Add or update snapshots                                      |   📸   | 📸 Update snapshot tests                    |
| Perform experiments                                          |   ⚗️   | ⚗️ Experiment with new commit heuristics    |
| Improve SEO                                                  |   🔍️   | 🔍️ Improve docs meta tags                   |
| Add or update types                                          |   🏷️   | 🏷️ Add TypeScript types for config          |
| Add or update seed files                                     |   🌱   | 🌱 Add seed config examples                 |
| Add, update, or remove feature flags                         |   🚩   | 🚩 Add flag to disable emojis               |
| Catch errors                                                 |   🥅   | 🥅 Add error handling for missing repo      |
| Add or update animations and transitions                     |   💫   | 💫 Add subtle UI transitions                |
| Deprecate code that needs to be cleaned up                   |   🗑️   | 🗑️ Deprecate legacy config loader           |
| Work on code related to authorization, roles and permissions |   🛂   | 🛂 Restrict hook execution permissions      |
| Simple fix for a non-critical issue                          |   🩹   | 🩹 Fix minor wording in output              |
| Data exploration/inspection                                  |   🧐   | 🧐 Inspect commit history patterns          |
| Remove dead code                                             |   ⚰️   | ⚰️ Remove unused helper functions           |
| Add a failing test                                           |   🧪   | 🧪 Add failing test for edge case           |
| Add or update business logic                                 |   👔   | 👔 Update commit classification logic       |
| Add or update healthcheck                                    |   🩺   | 🩺 Add healthcheck for git availability     |
| Infrastructure related changes                               |   🧱   | 🧱 Update CI runner setup                   |
| Improve developer experience                                 |   🧑‍💻   | 🧑‍💻 Add better local debug output            |
| Add sponsorships or money related infrastructure             |   💸   | 💸 Add funding metadata                     |
| Add or update code related to multithreading or concurrency  |   🧵   | 🧵 Parallelize diff processing              |
| Add or update code related to validation                     |   🦺   | 🦺 Validate `.git-commit.json` schema       |
| Improve offline support                                      |   ✈️   | ✈️ Cache gitmoji mappings locally           |
| Code that adds backwards compatibility                       |   🦖   | 🦖 Support legacy config keys               |

Prefer the closest semantic match from gitmoji. Keep the subject concise and focused on the primary change.

## Configuration (`.git-commit.json`)

This skill supports a JSON config file named `.git-commit.json` at two levels.

### Config precedence and discovery

- Global defaults: `~/.git-commit.json`
- Repo override: `<git-root>/.git-commit.json`
- Merge order: **global first, then repo overrides**

After load, the config script exports these env vars (see `scripts/git-commit-config.sh`):

- `GIT_COMMIT_DEBUG`: `true` / `false`
- `GIT_COMMIT_EMOJI`: `true` / `false`
- `GIT_COMMIT_PROMPT`: commit-message rules text — always populated, either from custom `prompt` in config or from `DEFAULT_PROMPT` in the script
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
    "pre": ["echo \"Running checks...\"", "npm run lint", "npm test"],
    "post": "echo \"Committed: $(git rev-parse --short HEAD)\""
  }
}
```

- `debug` (boolean, optional): default `false`. Enable verbose debug logging.
- `emoji` (boolean, optional): default `true`.
- `prompt` (string or string[], optional): custom rules text to **replace** the built-in `DEFAULT_PROMPT`. Arrays are joined with newlines.
- `hooks.pre` (string or string[], optional): pre hook, either:
  - path to a script file (relative to repo root, or absolute), or
  - inline shell content executed by `bash -lc`.
  - when provided as `string[]`, lines are joined with newlines into one multi-line shell command.
- `hooks.post` (string or string[], optional): post hook with the same behavior as `hooks.pre`.

Notes:

- `prompt` is treated as **replacement** text, not an append/merge.
- Hooks run with CWD set to the detected git root when available.

## Logging

All scripts use two output levels on stderr:

- **log** (`[script-tag] ...`): always shown. Reports config paths loaded, env vars exported, hook execution.
- **debug** (`[script-tag:debug] ...`): only when `GIT_COMMIT_DEBUG=true`. Reports every execution step, resolved values, inline commands.

Raw `git diff` / `git status` output is never written to stderr — only structured log messages appear.

Set `"debug": true` in `.git-commit.json` or `GIT_COMMIT_DEBUG=true` as an env var to enable debug output.

Example: `GIT_COMMIT_DEBUG=true eval "$(skills/git-commit/scripts/git-commit-config.sh export)"`

Additional notes:

- Config and hooks are implemented in bash; the helper script requires `jq` for JSON.
- Use `skills/git-commit/scripts/git-commit-config.sh print` to inspect the normalized effective config.
- If you only want per-repo overrides, create `<git-root>/.git-commit.json` and set only the fields you need.
- Example templates are in `skills/git-commit/assets/`.
