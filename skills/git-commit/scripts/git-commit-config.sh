#!/usr/bin/env bash
# git-commit skill: load ~/.git-commit.json + repo .git-commit.json and expose env vars.
# Requires: jq

set -euo pipefail

GLOBAL_CONFIG="$HOME/.git-commit.json"
EFFECTIVE_JSON="{}"
GIT_ROOT=""
SCRIPT_TAG="git-commit-config"

is_debug_enabled() {
  [[ "${GIT_COMMIT_DEBUG:-}" == "true" ]]
}

debug() {
  is_debug_enabled && echo "[$SCRIPT_TAG][DEBUG] $*" >&2 || true
}

warn() {
  echo "[$SCRIPT_TAG][WARN] $*" >&2
}

get_git_root() {
  local cwd="${1:-.}"
  git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true
}

read_json_object() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    debug "Config not found: $path"
    echo "{}"
    return 0
  fi

  debug "Reading config: $path"
  local result
  if ! result="$(jq -c 'if type == "object" then . else {} end' "$path" 2>/dev/null)"; then
    warn "Invalid JSON in $path, using defaults"
    echo "{}"
    return 0
  fi
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

  debug "Config sources: global=$GLOBAL_CONFIG repo=${repo_config:-<none>} git_root=${GIT_ROOT:-<none>}"

  # Repo config overrides global config.
  local merged
  merged="$(printf '%s\n%s\n' "$global_json" "$repo_json" | jq -s '.[0] * .[1]')"

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
        if (.hooks.pre | type) == "string" then
          .hooks.pre
        elif (.hooks.pre | type) == "array" then
          ([.hooks.pre[] | select(type == "string")] | join("\n"))
        else
          ""
        end
      ),
      hookPost: (
        if (.hooks.post | type) == "string" then
          .hooks.post
        elif (.hooks.post | type) == "array" then
          ([.hooks.post[] | select(type == "string")] | join("\n"))
        else
          ""
        end
      )
    }
  ')"

  # Activate debug mode from config when not already set via env var.
  if [[ "${GIT_COMMIT_DEBUG:-}" != "true" ]]; then
    local cfg_debug
    cfg_debug="$(echo "$EFFECTIVE_JSON" | jq -r '.debug')"
    [[ "$cfg_debug" == "true" ]] && GIT_COMMIT_DEBUG="true"
  fi

  debug "Effective config loaded (emoji=$(echo "$EFFECTIVE_JSON" | jq -r '.emoji') prompt_len=$(echo "$EFFECTIVE_JSON" | jq -r '.prompt | length') pre_hook=$(echo "$EFFECTIVE_JSON" | jq -r '.hookPre != ""') post_hook=$(echo "$EFFECTIVE_JSON" | jq -r '.hookPost != ""'))"
}

print_exports() {
  load_config "${1:-.}"

  local debug_val emoji prompt hook_pre hook_post
  debug_val="${GIT_COMMIT_DEBUG:-false}"
  emoji="$(echo "$EFFECTIVE_JSON" | jq -r '.emoji')"
  prompt="$(echo "$EFFECTIVE_JSON" | jq -r '.prompt')"
  hook_pre="$(echo "$EFFECTIVE_JSON" | jq -r '.hookPre')"
  hook_post="$(echo "$EFFECTIVE_JSON" | jq -r '.hookPost')"

  debug "Exporting env vars (emoji=$emoji prompt_len=${#prompt} pre_hook_set=$([[ -n "$hook_pre" ]] && echo true || echo false) post_hook_set=$([[ -n "$hook_post" ]] && echo true || echo false))"

  printf 'export GIT_COMMIT_DEBUG=%q\n' "$debug_val"
  printf 'export GIT_COMMIT_EMOJI=%q\n' "$emoji"
  printf 'export GIT_COMMIT_PROMPT=%q\n' "$prompt"
  printf 'export GIT_COMMIT_HOOK_PRE=%q\n' "$hook_pre"
  printf 'export GIT_COMMIT_HOOK_POST=%q\n' "$hook_post"
}

print_json() {
  load_config "${1:-.}"
  echo "$EFFECTIVE_JSON"
}

usage() {
  echo "Usage: $0 export" >&2
  echo "       $0 print" >&2
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
  *)
    usage
    ;;
esac
