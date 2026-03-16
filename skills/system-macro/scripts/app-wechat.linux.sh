#!/bin/bash

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Note: To prevent input-method issues (such as pinyin),
# paste text through clipboard instead of direct typing.
platform_send_text() {
    local text="$1"
    if [[ -z "$text" ]]; then
        return
    fi

    if command_exists xclip; then
        echo -n "$text" | xclip -selection clipboard
    elif command_exists xsel; then
        echo -n "$text" | xsel --clipboard
    else
        echo "Error: xclip or xsel required for clipboard paste." >&2
        exit 1
    fi

    sleep 0.5
    xdotool key --clearmodifiers ctrl+v
    xdotool key --clearmodifiers Return
}

platform_send_file() {
    local path="$1"
    local mimetype=""
    local abs_path=""

    if [[ ! -f "$path" ]]; then
        echo "Error: File '$path' not found" >&2
        exit 1
    fi

    if command_exists file; then
        mimetype=$(file --brief --mime-type "$path")
    fi

    if [[ "$mimetype" == image/* ]]; then
        xclip -selection clipboard -t "$mimetype" -i "$path"
    else
        if command_exists realpath; then
            abs_path=$(realpath "$path")
        else
            abs_path=$(readlink -f "$path")
        fi
        printf 'file://%s\n' "$abs_path" | xclip -selection clipboard -t text/uri-list
    fi

    sleep 0.5
    xdotool key --clearmodifiers ctrl+v
    xdotool key --clearmodifiers Return
}

platform_check_wechat_running() {
    if ! pgrep -x "wechat" >/dev/null 2>&1; then
        echo "WeChat is not running" >&2
        exit 1
    fi
}

platform_check_dependencies() {
    local dependencies=("xdotool" "wmctrl" "xclip")
    local dependency

    for dependency in "${dependencies[@]}"; do
        if ! command_exists "$dependency"; then
            echo "Error: $dependency required. Install: sudo apt install $dependency" >&2
            exit 1
        fi
    done
}

platform_confirm_dialog() {
    local receiver_name="$1"
    local title="wechat-app"
    local message="I will send a message to $receiver_name, after continue, please don't interrupt me."

    if command_exists zenity; then
        zenity --question --title="$title" --text="$message"
        return $?
    fi

    if command_exists kdialog; then
        kdialog --yesno "$message" --title "$title"
        return $?
    fi

    echo "$title"
    echo "$message [y/N]: "
    read -r answer
    case "$answer" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

platform_focus_wechat() {
    wmctrl -x -a "wechat.wechat"
    sleep 1
}

platform_search_chat() {
    local chat_name="$1"
    xdotool key --clearmodifiers ctrl+f
    sleep 0.5

    if command_exists xclip; then
        echo -n "$chat_name" | xclip -selection clipboard
    else
        echo -n "$chat_name" | xsel --clipboard
    fi

    xdotool key --clearmodifiers ctrl+v
    sleep 0.5
    xdotool key --clearmodifiers Return
    sleep 1
}
