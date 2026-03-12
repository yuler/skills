#!/bin/bash
# Dispatch to platform-specific WeChat send script (Linux or macOS).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

case "$OS" in
    Linux)
        exec "$SCRIPT_DIR/app-wechat.linux.sh" "$@"
        ;;
    Darwin)
        exec "$SCRIPT_DIR/app-wechat.mac.sh" "$@"
        ;;
    *)
        echo "Error: Unsupported system '$OS'. Use app-wechat.linux.sh or app-wechat.mac.sh directly." >&2
        exit 1
        ;;
esac
