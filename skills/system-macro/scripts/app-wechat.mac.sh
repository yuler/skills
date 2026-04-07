#!/bin/bash

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

platform_check_dependencies() {
    if ! command_exists osascript; then
        echo "Error: osascript is required on macOS" >&2
        exit 1
    fi
}

platform_check_wechat_running() {
    if ! pgrep -x "WeChat" >/dev/null 2>&1; then
        echo "WeChat is not running" >&2
        exit 1
    fi
}

platform_confirm_dialog() {
    local receiver_name="$1"
    osascript - "$receiver_name" <<'APPLESCRIPT' >/dev/null
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

platform_expand_path() {
    local path="$1"
    if [[ "$path" == ~* ]]; then
        echo "${path/#\~/$HOME}"
    else
        echo "$path"
    fi
}

platform_focus_wechat() {
    open '/Applications/WeChat.app' >/dev/null 2>&1 || {
        echo "Failed to launch WeChat" >&2
        return 1
    }
}

platform_search_chat() {
    local chat_name="$1"
    osascript - "$chat_name" <<'APPLESCRIPT' >/dev/null
on run argv
    set chatName to item 1 of argv
    tell application "System Events"
        keystroke "f" using {command down}
        delay 0.8
        set the clipboard to chatName
        keystroke "v" using {command down}
        delay 0.8
        keystroke return
        delay 1
    end tell
end run
APPLESCRIPT
}

platform_send_file() {
    local file_path="$1"
    osascript - "$file_path" <<'APPLESCRIPT' >/dev/null
on run argv
    set filePath to item 1 of argv
    set the clipboard to (POSIX file filePath)
    tell application "System Events"
        keystroke "v" using {command down}
        delay 0.8
        keystroke return
        delay 1
    end tell
end run
APPLESCRIPT
}

platform_send_text() {
    local text="$1"
    osascript - "$text" <<'APPLESCRIPT' >/dev/null
on run argv
    set messageText to item 1 of argv
    tell application "System Events"
        set the clipboard to messageText
        keystroke "v" using {command down}
        delay 0.8
        keystroke return
        delay 1
    end tell
end run
APPLESCRIPT
}
