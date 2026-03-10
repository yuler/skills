#!/bin/bash

RECEIVER_NAME="#dev"
MESSAGE="test message"

# Help message
usage() {
    cat <<-EOF
Usage: $(basename "$0") [options]

Example: $(basename "$0") -r "#dev" -m "test message"

Options:
    -r, --receiver  Receiver name (default: #dev)
    -m, --message   Message to send (default: test message)
    -h, --help      Show this help message and exit
    -v, --version   Show version information and exit
EOF
        exit
}

version() {
    echo "$(basename "$0") 0.1.0"
    exit
}

send_message() {
    # Check exist wechat process
    if ! pgrep -x "wechat" > /dev/null; then
        echo "WeChat is not running"
        exit 1
    fi

    # Focus to the wechat window, `wmctrl -x -l` should list the window id
    wmctrl -x -a "wechat.wechat"

    # Hack: focus "File Transfer" channel
    sleep 1
    xdotool key --clearmodifiers "ctrl+f"
    sleep 1
    xdotool type "weixin"
    xdotool key --clearmodifiers "Return"
    
    # Find the receiver
    sleep 1
    xdotool key --clearmodifiers "ctrl+f"
    sleep 1
    xdotool type "$RECEIVER_NAME"
    xdotool key --clearmodifiers "Return"

    # Type message
    sleep 2
    xdotool type "$MESSAGE"

    # wait for confirm to send message
    # Send message, press enter key
    xdotool key --clearmodifiers "Return"
    # return home page
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
send_message