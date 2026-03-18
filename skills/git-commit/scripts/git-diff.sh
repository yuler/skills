#!/usr/bin/env bash

set -euo pipefail

SCRIPT_TAG="git-diff"

warn() {
  echo "[$SCRIPT_TAG][WARN] $*" >&2
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

# Build exclude pathspecs (one per file)
exclude_args=()
for f in "${LOCKFILES[@]}"; do
    exclude_args+=(':(exclude)'"$f")
done

# Get the diff with exclusions
diff=$(git diff --staged -- . "${exclude_args[@]}")

# If don't have staged changes, exit
if [[ -z "$diff" ]]; then
    warn "No staged changes to commit"
    exit 1
fi

# Print the diff
echo "$diff"
