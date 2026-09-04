#!/bin/bash

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# WeChat on Omarchy runs as XWayland. wtype (Wayland virtual keyboard) does not
# deliver keys to it; xdotool does. Clipboard still uses wl-copy (Hyprland syncs
# it into the X11 clipboard WeChat reads).

omarchy_press() {
    xdotool key --clearmodifiers "$@"
}

# Paste via clipboard + Ctrl+V to avoid IME (e.g. pinyin) mangling typed text.
omarchy_clipboard_paste() {
    sleep 0.5
    omarchy_press ctrl+v
    sleep 0.3
    omarchy_press Return
}

omarchy_copy_text() {
    local text="$1"
    printf '%s' "$text" | wl-copy
}

omarchy_find_wechat_desktop() {
    local candidate
    for candidate in \
        "${XDG_DATA_HOME:-$HOME/.local/share}/applications/wechat.desktop" \
        "$HOME/.local/share/applications/wechat.desktop" \
        /usr/local/share/applications/wechat.desktop \
        /usr/share/applications/wechat.desktop; do
        if [[ -f "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

platform_send_text() {
    local text="$1"
    if [[ -z "$text" ]]; then
        return
    fi

    omarchy_copy_text "$text"
    omarchy_clipboard_paste
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

    if command_exists realpath; then
        abs_path=$(realpath "$path")
    else
        abs_path=$(readlink -f "$path")
    fi

    if [[ "$mimetype" == image/* ]]; then
        wl-copy --type "$mimetype" <"$abs_path"
    else
        printf 'file://%s\n' "$abs_path" | wl-copy --type text/uri-list
    fi

    omarchy_clipboard_paste
}

platform_check_wechat_running() {
    if ! pgrep -x "wechat" >/dev/null 2>&1; then
        echo "WeChat is not running" >&2
        exit 1
    fi
}

platform_check_dependencies() {
    # wl-copy/hyprctl/xdg-open/omarchy-launch-or-focus: Omarchy defaults
    # xdotool: needed because WeChat is XWayland (wtype cannot type into it)
    local dependencies=("wl-copy" "xdotool" "hyprctl" "xdg-open" "omarchy-launch-or-focus")
    local dependency

    for dependency in "${dependencies[@]}"; do
        if ! command_exists "$dependency"; then
            if [[ "$dependency" == "xdotool" ]]; then
                echo "Error: xdotool required (WeChat is XWayland). Install: sudo pacman -S xdotool" >&2
            else
                echo "Error: $dependency required (Omarchy / Hyprland tooling)." >&2
            fi
            exit 1
        fi
    done
}

platform_confirm_dialog() {
    local receiver_name="$1"
    local title="wechat-app"
    local message="I will send a message to $receiver_name, after continue, please don't interrupt me."

    if command_exists gum; then
        gum confirm --affirmative="Continue" --negative="Cancel" "$message"
        return $?
    fi

    if command_exists zenity; then
        zenity --question --title="$title" --text="$message"
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
    local desktop_file=""
    local launch_cmd=""

    if desktop_file=$(omarchy_find_wechat_desktop); then
        launch_cmd="xdg-open \"$desktop_file\""
    else
        launch_cmd="xdg-open wechat:"
    fi

    # Prefer Omarchy helper: focus existing window or launch via xdg-open.
    omarchy-launch-or-focus wechat "$launch_cmd" >/dev/null 2>&1 || \
        hyprctl dispatch 'hl.dsp.focus({ window = "class:wechat" })' >/dev/null
    sleep 1
}

platform_search_chat() {
    local chat_name="$1"

    omarchy_press ctrl+f
    sleep 0.5

    omarchy_copy_text "$chat_name"
    sleep 0.3
    omarchy_press ctrl+v
    sleep 0.5
    omarchy_press Return
    sleep 1
}
