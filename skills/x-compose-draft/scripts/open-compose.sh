#!/usr/bin/env bash
# Open X compose in the default browser with pre-filled tweet text.
set -euo pipefail

TEXT="${1:?Usage: open-compose.sh \"tweet text\"}"

ENCODED="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$TEXT")"
URL="https://x.com/intent/tweet?text=${ENCODED}"

case "$(uname -s)" in
  Darwin) open "$URL" ;;
  Linux)  xdg-open "$URL" ;;
  *)
    echo "Unsupported OS: $(uname -s). Open this URL manually:" >&2
    echo "$URL" >&2
    exit 1
    ;;
esac
