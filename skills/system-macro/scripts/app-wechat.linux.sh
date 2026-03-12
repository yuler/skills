#!/bin/bash

RECEIVER_NAME=""
MESSAGE=""
FILE=""

# Help message
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
        exit
}

version() {
    echo "$(basename "$0") 0.1.0"
    exit
}

# Note: To prevent using the input method (such as pinyin)
# paste text using the clipboard instead of typing
type_text_through_clipboard() {
    local text="$1"
    if [[ -z "$text" ]]; then
        return
    fi
    # Copy to clipboard (xclip for X11, fallback to xsel)
    if command -v xclip &>/dev/null; then
        echo -n "$text" | xclip -selection clipboard
    elif command -v xsel &>/dev/null; then
        echo -n "$text" | xsel --clipboard
    else
        echo "Error: xclip or xsel required for clipboard paste. Install: sudo apt install xclip" >&2
        exit 1
    fi
    xdotool key --clearmodifiers ctrl+v
}

copy_file_to_clipboard() {
    local path="$1"

    if [[ -z "$path" ]]; then
        return
    fi

    if [[ ! -f "$path" ]]; then
        echo "Error: File '$path' not found" >&2
        exit 1
    fi

    # Detect mime type if possible
    local mimetype=""
    if command_exists file; then
        mimetype=$(file --brief --mime-type "$path")
    fi

    # If it's an image, copy binary image data; otherwise copy as file URI
    if [[ "$mimetype" == image/* ]]; then
        xclip -selection clipboard -t "$mimetype" -i "$path"
    else
        local abs_path
        if command_exists realpath; then
            abs_path=$(realpath "$path")
        else
            abs_path=$(readlink -f "$path")
        fi
        printf 'file://%s\n' "$abs_path" | xclip -selection clipboard -t text/uri-list
    fi
}

check_wechat_running() {
    if ! pgrep -x "wechat" > /dev/null; then
        echo "WeChat is not running"
        exit 1
    fi
}

command_exists() {
    command -v "$1" &>/dev/null
}

check_dependencies() {
   local dependencies=("xdotool" "wmctrl" "xclip" "xsel")
   for dependency in "${dependencies[@]}"; do
        if ! command_exists "$dependency"; then
            echo "Error: $dependency required. Install: sudo apt install $dependency" >&2
            exit 1
        fi
   done
}

confirm_dialog() {
    local title="wechat-app"
    local message="I will send a message to $RECEIVER_NAME, after continue, please don't interrupt me."

    # Prefer graphical dialogs if available
    if command_exists zenity; then
        zenity --question --title="$title" --text="$message"
        return $?
    elif command_exists kdialog; then
        kdialog --yesno "$message" --title "$title"
        return $?
    fi

    # Fallback to terminal confirmation
    echo "$title"
    echo "$message [y/N]: "
    read -r answer
    case "$answer" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
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
}

send() {
    check_wechat_running
    check_dependencies
    check_arguments

    # Confirm before sending the message
    if ! confirm_dialog "Send WeChat message" "Send message to $RECEIVER_NAME?"; then
        echo "User cancelled, exiting"
        exit 1
    fi

    # Focus to the wechat window, `wmctrl -x -l` should list the window id
    wmctrl -x -a "wechat.wechat"

    # Hack: focus "File Transfer" channel
    sleep 1
    xdotool key --clearmodifiers "ctrl+f"
    sleep 0.5
    type_text_through_clipboard "weixin"
    sleep 0.5
    xdotool key --clearmodifiers "Return"
    
    # Find the receiver
    sleep 1
    xdotool key --clearmodifiers "ctrl+f"
    sleep 0.5
    type_text_through_clipboard "$RECEIVER_NAME"
    sleep 0.5
    xdotool key --clearmodifiers "Return"

    # Send file
    if [[ -n "$FILE" ]]; then
        if [[ ! -f "$FILE" ]]; then
            echo "Error: File '$FILE' not found" >&2
            exit 1
        fi
        copy_file_to_clipboard "$FILE"
        sleep 2
        xdotool key --clearmodifiers "ctrl+v"
        xdotool key --clearmodifiers "Return"
        sleep 1
    fi

    # Send text
    if [[ -n "$MESSAGE"]]; then
        sleep 2
        type_text_through_clipboard "$MESSAGE"
        xdotool key --clearmodifiers "Return"
    fi

    exit 0
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

# Main
send
