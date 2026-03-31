#!/usr/bin/env bash

set -euo pipefail

SCRIPT_TAG="git-diff"

is_debug_enabled() {
  [[ "${GIT_COMMIT_DEBUG:-}" == "true" ]]
}

log() {
  echo "[$SCRIPT_TAG] $*" >&2
}

debug() {
  is_debug_enabled && echo "[$SCRIPT_TAG:debug] $*" >&2 || true
}

LOCKFILES=(
    # Node.js: pnpm, npm, yarn, bun
    "pnpm-lock.yaml"
    "package-lock.json"
    "yarn.lock"
    "bun.lockb"

    # Ruby
    "Gemfile.lock"

    # Python: uv
    "uv.lock"

    # PHP: composer
    "composer.lock"
    
    # Go
    "go.sum"

    # Rust
    "Cargo.lock"
)

exclude_args=()
for f in "${LOCKFILES[@]}"; do
    exclude_args+=(':(exclude)'"$f")
done

debug "running git diff --staged with ${#exclude_args[@]} lockfile exclusions"

diff=$(git diff --staged -- . "${exclude_args[@]}")

if [[ -z "$diff" ]]; then
    log "no staged changes to commit"
    exit 1
fi

debug "staged diff: $(echo "$diff" | wc -l) lines"

echo "$diff"
