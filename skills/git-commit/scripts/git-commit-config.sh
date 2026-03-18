#!/usr/bin/env bash
# git-commit skill: load ~/.git-commit.json + repo .git-commit.json and expose env vars.
# Requires: jq

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_SCRIPT="$SCRIPT_DIR/git-commit-hooks.sh"
GLOBAL_CONFIG="$HOME/.git-commit.json"
EFFECTIVE_JSON="{}"
GIT_ROOT=""

log() {
  echo "[git-commit-config] $*" >&2
}

debug() {
  [[ "${GIT_COMMIT_DEBUG:-}" == "true" ]] && echo "[git-commit-config:debug] $*" >&2 || true
}

get_git_root() {
  local cwd="${1:-.}"
  git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true
}

read_json_object() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    debug "Config file not found, skipping: $path"
    echo "{}"
    return 0
  fi

  debug "Reading config file: $path"
  local result
  if ! result="$(jq -c 'if type == "object" then . else {} end' "$path" 2>/dev/null)"; then
    debug "Failed to parse JSON, using empty object: $path"
    echo "{}"
    return 0
  fi
  debug "Parsed config: $result"
  echo "$result"
}

load_config() {
  local cwd="${1:-.}"
  GIT_ROOT="$(get_git_root "$cwd")"

  local repo_config=""
  [[ -n "$GIT_ROOT" ]] && repo_config="$GIT_ROOT/.git-commit.json"

  local global_json repo_json
  global_json="$(read_json_object "$GLOBAL_CONFIG")"
  repo_json="$(read_json_object "$repo_config")"

  if [[ -n "$repo_config" ]]; then
    debug "Loading config: global=$GLOBAL_CONFIG, repo=$repo_config"
  else
    debug "Loading config: global=$GLOBAL_CONFIG, repo=<none>"
  fi

  debug "Git root: ${GIT_ROOT:-<not found>}"
  debug "Global JSON: $global_json"
  debug "Repo JSON: $repo_json"

  # Repo config overrides global config.
  local merged
  merged="$(printf '%s\n%s\n' "$global_json" "$repo_json" | jq -s '.[0] * .[1]')"

  debug "Merged JSON: $merged"

  # Normalize to current schema only:
  # - prompt (string or string[])
  # - hooks.pre / hooks.post
  EFFECTIVE_JSON="$(echo "$merged" | jq '
    {
      debug: (
        if (.debug | type) == "boolean" then .debug else false end
      ),
      emoji: (
        if (.emoji | type) == "boolean" then .emoji else true end
      ),
      prompt: (
        if (.prompt | type) == "string" then
          .prompt
        elif (.prompt | type) == "array" then
          ([.prompt[] | select(type == "string")] | join("\n"))
        else
          ""
        end
      ),
      hookPre: (
        if (.hooks.pre | type) == "string" then .hooks.pre else "" end
      ),
      hookPost: (
        if (.hooks.post | type) == "string" then .hooks.post else "" end
      )
    }
  ')"

  # Activate debug mode from config when not already set via env var.
  if [[ "${GIT_COMMIT_DEBUG:-}" != "true" ]]; then
    local cfg_debug
    cfg_debug="$(echo "$EFFECTIVE_JSON" | jq -r '.debug')"
    [[ "$cfg_debug" == "true" ]] && GIT_COMMIT_DEBUG="true"
  fi

  debug "Effective config: $EFFECTIVE_JSON"
  debug "Config loaded successfully"
}

print_exports() {
  load_config "${1:-.}"

  local debug_val emoji prompt hook_pre hook_post
  debug_val="${GIT_COMMIT_DEBUG:-false}"
  emoji="$(echo "$EFFECTIVE_JSON" | jq -r '.emoji')"
  prompt="$(echo "$EFFECTIVE_JSON" | jq -r '.prompt')"
  hook_pre="$(echo "$EFFECTIVE_JSON" | jq -r '.hookPre')"
  hook_post="$(echo "$EFFECTIVE_JSON" | jq -r '.hookPost')"

  debug "Exporting env vars:"
  debug "  GIT_COMMIT_DEBUG=$debug_val"
  debug "  GIT_COMMIT_EMOJI=$emoji"
  debug "  GIT_COMMIT_PROMPT=$prompt"
  debug "  GIT_COMMIT_HOOK_PRE=$hook_pre"
  debug "  GIT_COMMIT_HOOK_POST=$hook_post"

  printf 'export GIT_COMMIT_DEBUG=%q\n' "$debug_val"
  printf 'export GIT_COMMIT_EMOJI=%q\n' "$emoji"
  printf 'export GIT_COMMIT_PROMPT=%q\n' "$prompt"
  printf 'export GIT_COMMIT_HOOK_PRE=%q\n' "$hook_pre"
  printf 'export GIT_COMMIT_HOOK_POST=%q\n' "$hook_post"
}

run_hook() {
  local stage="$1"
  local cwd="${2:-.}"
  load_config "$cwd"

  local hook_value
  if [[ "$stage" == "pre" ]]; then
    hook_value="$(echo "$EFFECTIVE_JSON" | jq -r '.hookPre')"
  else
    hook_value="$(echo "$EFFECTIVE_JSON" | jq -r '.hookPost')"
  fi

  debug "Hook value for $stage: ${hook_value:-<empty>}"

  if [[ ! -x "$HOOKS_SCRIPT" ]]; then
    log "Hook runner not executable, using bash: $HOOKS_SCRIPT"
  fi

  local run_cwd="$cwd"
  [[ -n "$GIT_ROOT" ]] && run_cwd="$GIT_ROOT"

  debug "Hook runner script: $HOOKS_SCRIPT"
  debug "Hook runner cwd: $run_cwd"
  log "Dispatching $stage hook to hook runner"
  GIT_COMMIT_DEBUG="${GIT_COMMIT_DEBUG:-}" \
  GIT_COMMIT_HOOK_PRE="$(echo "$EFFECTIVE_JSON" | jq -r '.hookPre')" \
  GIT_COMMIT_HOOK_POST="$(echo "$EFFECTIVE_JSON" | jq -r '.hookPost')" \
  bash "$HOOKS_SCRIPT" "$stage" "$run_cwd"
}

print_json() {
  load_config "${1:-.}"
  log "Printing normalized config"
  echo "$EFFECTIVE_JSON"
}

usage() {
  echo "Usage: $0 export" >&2
  echo "       $0 print" >&2
  echo "       $0 run-hook <pre|post>" >&2
  exit 1
}

# Main
case "${1:-export}" in
  export)
    print_exports "."
    ;;
  print)
    print_json "."
    ;;
  run-hook)
    stage="${2:-}"
    [[ "$stage" != "pre" && "$stage" != "post" ]] && usage
    run_hook "$stage" "."
    ;;
  *)
    usage
    ;;
esac
