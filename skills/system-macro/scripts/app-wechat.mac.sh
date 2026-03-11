#!/bin/bash

RECEIVER_NAME="#dev"
MESSAGE="test message"
FILE=""

# Help message
usage() {
    cat <<-EOF
Usage: $(basename "$0") [options]

Example: $(basename "$0") -r "#dev" -m "test message" -f "~/Downloads/test.png"

Options:
    -r, --receiver  Receiver name (default: #dev)
    -m, --message   Message to send (default: test message)
    -f, --file      Path to a file to send
    -h, --help      Show this help message and exit
    -v, --version   Show version information and exit
EOF
        exit
}

version() {
    echo "$(basename "$0") 0.1.0"
    exit
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_dependencies() {
    if ! command_exists osascript; then
        echo "Error: osascript is required on macOS" >&2
        exit 1
    fi
}

check_wechat_running() {
    if ! pgrep -x "WeChat" >/dev/null 2>&1; then
        echo "WeChat is not running" >&2
        exit 1
    fi
}

confirm_dialog() {
    osascript - "$RECEIVER_NAME" <<'APPLESCRIPT' >/dev/null
on run argv
    set receiverName to item 1 of argv
    set msg to "I will send a message to " & receiverName & ". After continue, please don't interrupt me."
    tell application "System Events"
        activate
        display dialog msg buttons {"Cancel", "Continue"} default button "Continue" with title "wechat-app"
    end tell
end run
APPLESCRIPT
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

send_message() {
    check_dependencies
    check_wechat_running
    check_arguments

    if ! confirm_dialog; then
        echo "User cancelled, exiting"
        exit 1
    fi

    osascript - "$RECEIVER_NAME" "$MESSAGE" "$FILE" <<'APPLESCRIPT'
on run argv
    set receiverName to item 1 of argv
    set messageText to item 2 of argv
    set filePath to item 3 of argv

    tell application "WeChat" to activate
    delay 1

    tell application "System Events"
        -- Focus "File Transfer" channel first, same as linux flow.
        keystroke "f" using {command down}
        delay 0.8
        set the clipboard to "weixin"
        keystroke "v" using {command down}
        key code 36
        delay 0.8

        -- Search and open the receiver.
        keystroke "f" using {command down}
        delay 0.8
        set the clipboard to receiverName
        keystroke "v" using {command down}
        key code 36
        delay 1

        -- Send file when provided.
        if filePath is not "" then
            set the clipboard to (POSIX file filePath)
            keystroke "v" using {command down}
            key code 36
            delay 0.8
        end if

        -- Send message when provided.
        if messageText is not "" then
            set the clipboard to messageText
            keystroke "v" using {command down}
            key code 36
        end if
    end tell
end run
APPLESCRIPT
}

# Parse Opitons
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -h | --help)
        usage
        ;;
    -v | --version)
        version
        ;;
    -r | --receiver)
        RECEIVER_NAME="$2"
        shift 2
        ;;
    -f | --file)
        FILE="$2"
        shift 2
        ;;
    -m | --message)
        MESSAGE="$2"
        shift 2
        ;;
    *)
        echo "Unknown option: $1" >&2
        usage
        ;;
    esac
done

if [[ -n "$FILE" ]]; then
    FILE="$(expand_path "$FILE")"
fi

# Main
send_message
