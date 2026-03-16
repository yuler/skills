#!/bin/bash
# Main entrypoint for sending WeChat messages.
# Contains shared CLI parsing and send flow. Platform scripts only provide
# platform-specific implementations.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

RECEIVER_NAME=""
MESSAGE=""
FILE=""

usage() {
    cat <<-EOF
Usage: $(basename "$0") [options]

Example: $(basename "$0") -r "#dev" -m "test message" -f "~/Downloads/test.png"

Options:
    -r, --receiver  Receiver name
    -m, --message   Message to send
    -f, --file      Path to a file to send
    -h, --help      Show this help message and exit
    -v, --version   Show version information and exit
EOF
}

version() {
    echo "$(basename "$0") 0.1.0"
}

load_platform_script() {
    case "$OS" in
        Linux)
            # shellcheck source=/dev/null
            . "$SCRIPT_DIR/app-wechat.linux.sh"
            ;;
        Darwin)
            # shellcheck source=/dev/null
            . "$SCRIPT_DIR/app-wechat.mac.sh"
            ;;
        *)
            echo "Error: Unsupported system '$OS'." >&2
            exit 1
            ;;
    esac
}

ensure_platform_contract() {
    local required_functions=(
        platform_check_dependencies
        platform_check_wechat_running
        platform_confirm_dialog
        platform_focus_wechat
        platform_search_chat
        platform_send_text
        platform_send_file
    )

    local fn
    for fn in "${required_functions[@]}"; do
        if ! command -v "$fn" >/dev/null 2>&1; then
            echo "Error: Platform script is missing required function '$fn'." >&2
            exit 1
        fi
    done
}

expand_path() {
    local path="$1"
    if [[ "$path" == ~* ]]; then
        echo "${path/#\~/$HOME}"
    else
        echo "$path"
    fi
}

check_arguments() {
    if [[ -z "$RECEIVER_NAME" ]]; then
        echo "Error: Receiver name is required" >&2
        exit 1
    fi

    if [[ -z "$MESSAGE" && -z "$FILE" ]]; then
        echo "Error: At least a message or a file is required" >&2
        exit 1
    fi

    if [[ -n "$FILE" && ! -f "$FILE" ]]; then
        echo "Error: File '$FILE' not found" >&2
        exit 1
    fi
}

parse_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        -v | --version)
            version
            exit 0
            ;;
        -r | --receiver)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --receiver requires a value" >&2
                exit 1
            fi
            RECEIVER_NAME="$2"
            shift 2
            ;;
        -f | --file)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --file requires a value" >&2
                exit 1
            fi
            FILE="$2"
            shift 2
            ;;
        -m | --message)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --message requires a value" >&2
                exit 1
            fi
            MESSAGE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
        esac
    done
}

send() {
    platform_check_dependencies
    platform_check_wechat_running

    if ! platform_confirm_dialog "$RECEIVER_NAME"; then
        echo "User cancelled, exiting"
        exit 1
    fi

    platform_focus_wechat

    # Keep the same behavior: first focus "File Transfer", then locate target.
    platform_search_chat "weixin"
    platform_search_chat "$RECEIVER_NAME"

    if [[ -n "$FILE" ]]; then
        platform_send_file "$FILE"
    fi

    if [[ -n "$MESSAGE" ]]; then
        platform_send_text "$MESSAGE"
    fi
}

main() {
    load_platform_script
    ensure_platform_contract

    parse_options "$@"

    if command -v platform_expand_path >/dev/null 2>&1; then
        [[ -n "$FILE" ]] && FILE="$(platform_expand_path "$FILE")"
    else
        [[ -n "$FILE" ]] && FILE="$(expand_path "$FILE")"
    fi

    check_arguments
    send
}

main "$@"
