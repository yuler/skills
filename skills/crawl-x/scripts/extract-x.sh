#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: bash scripts/extract-x.sh <x-or-twitter-status-url>" >&2
  exit 1
fi

POST_URL="$1"

if [[ ! "$POST_URL" =~ ^https?://(x|twitter)\.com/[^/]+/status/[0-9]+ ]]; then
  echo "Error: expected an X/Twitter status URL." >&2
  exit 1
fi

STATUS_ID="$(echo "$POST_URL" | sed -E 's#.*status/([0-9]+).*#\1#')"
USERNAME="$(echo "$POST_URL" | sed -E 's#https?://(x|twitter)\.com/([^/]+)/status/.*#\2#')"
JSON_FILE="$(mktemp)"
OUTPUT_FILE="$(mktemp)"

cleanup() {
  rm -f "$JSON_FILE" "$OUTPUT_FILE"
}

trap cleanup EXIT

fetch_json() {
  local base_url="$1"
  curl -fsSL "$base_url/$USERNAME/status/$STATUS_ID" > "$JSON_FILE"
}

if ! fetch_json "https://api.fxtwitter.com"; then
  fetch_json "https://api.vxtwitter.com"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bun "$SCRIPT_DIR/extract-x.ts" "$JSON_FILE" "$POST_URL" "$OUTPUT_FILE"

FILENAME="$(< "$OUTPUT_FILE")"
echo "Saved to: $FILENAME"
sed -n '1,10p' "$FILENAME"
