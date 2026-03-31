#!/usr/bin/env bash
# git-commit skill: execute pre/post hooks from environment variables.

set -euo pipefail

SCRIPT_TAG="git-commit-hooks"

is_debug_enabled() {
  [[ "${GIT_COMMIT_DEBUG:-}" == "true" ]]
}

log() {
  echo "[$SCRIPT_TAG:log] $*" >&2
}

debug() {
  is_debug_enabled && echo "[$SCRIPT_TAG:debug] $*" >&2 || true
}

usage() {
  echo "Usage: $0 <pre|post> [cwd]" >&2
  exit 1
}

get_git_root() {
  local cwd="${1:-.}"
  git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true
}

resolve_hook_path() {
  local raw="$1"
  local base="${2:-.}"
  if [[ "$raw" = /* ]]; then
    echo "$raw"
  else
    echo "$base/$raw"
  fi
}

run_hook() {
  local stage="$1"
  local cwd="${2:-.}"
  local hook_value=""

  if [[ "$stage" == "pre" ]]; then
    hook_value="${GIT_COMMIT_HOOK_PRE:-}"
  else
    hook_value="${GIT_COMMIT_HOOK_POST:-}"
  fi

  debug "stage=$stage cwd=$cwd"

  if [[ -z "$hook_value" ]]; then
    debug "no $stage hook configured, skipping"
    return 0
  fi

  local run_cwd="$cwd"
  local git_root
  git_root="$(get_git_root "$cwd")"
  [[ -n "$git_root" ]] && run_cwd="$git_root"

  debug "resolved run cwd: ${run_cwd}"

  local maybe_path
  maybe_path="$(resolve_hook_path "$hook_value" "$run_cwd")"
  debug "resolved hook path: $maybe_path"

  if [[ -f "$maybe_path" ]]; then
    log "running $stage hook: $maybe_path"
    debug "executing script file"
    (cd "$run_cwd" && bash "$maybe_path")
  else
    log "running $stage hook (inline)"
    debug "inline command: $hook_value"
    (cd "$run_cwd" && bash -lc "$hook_value")
  fi
}

stage="${1:-}"
[[ "$stage" != "pre" && "$stage" != "post" ]] && usage

cwd="${2:-.}"
run_hook "$stage" "$cwd"
