#!/usr/bin/env bash
# git-commit skill: execute pre/post hooks from environment variables.

set -euo pipefail

log() {
  echo "[git-commit-hooks] $*" >&2
}

debug() {
  [[ "${GIT_COMMIT_DEBUG:-}" == "true" ]] && echo "[git-commit-hooks:debug] $*" >&2 || true
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

  debug "Stage: $stage, cwd: $cwd"
  debug "GIT_COMMIT_HOOK_PRE=${GIT_COMMIT_HOOK_PRE:-<unset>}"
  debug "GIT_COMMIT_HOOK_POST=${GIT_COMMIT_HOOK_POST:-<unset>}"

  if [[ -z "$hook_value" ]]; then
    log "No $stage hook configured, skip."
    return 0
  fi

  debug "Resolved $stage hook value: $hook_value"

  local run_cwd="$cwd"
  local git_root
  git_root="$(get_git_root "$cwd")"
  [[ -n "$git_root" ]] && run_cwd="$git_root"

  debug "Git root: ${git_root:-<not found>}, run cwd: $run_cwd"

  local maybe_path
  maybe_path="$(resolve_hook_path "$hook_value" "$run_cwd")"
  debug "Resolved hook path: $maybe_path (exists=$([ -f "$maybe_path" ] && echo yes || echo no))"

  if [[ -f "$maybe_path" ]]; then
    log "Running $stage hook script: $maybe_path"
    (cd "$run_cwd" && bash "$maybe_path")
  else
    log "Running $stage inline hook in $run_cwd"
    debug "Inline command: bash -lc \"$hook_value\""
    (cd "$run_cwd" && bash -lc "$hook_value")
  fi

  log "$stage hook completed"
}

stage="${1:-}"
[[ "$stage" != "pre" && "$stage" != "post" ]] && usage

cwd="${2:-.}"
run_hook "$stage" "$cwd"
