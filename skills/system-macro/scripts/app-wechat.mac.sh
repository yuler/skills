#!/bin/bash

# OpenClaw Skill: system-macro - WeChat macOS
# Send WeChat messages via AppleScript GUI Automation on macOS
# Requirements: Accessibility permission enabled

set -e

RECEIVER_NAME="#dev"
MESSAGE="test message"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Help message
usage() {
 cat <<-EOF
Usage: $(basename "$0") [options]

Send WeChat messages via AppleScript GUI automation on macOS.
WeChat app must be running and Accessibility permission must be granted.

Example: $(basename "$0") -r "#dev" -m "test message"

Options:
 -r, --receiver Receiver name (default: #dev)
 -m, --message Message to send (default: test message)
 -h, --help Show this help message and exit
 -v, --version Show version information and exit

Requirements:
 - macOS WeChat app must be running
 - System Settings → Privacy & Security → Accessibility → Terminal/your terminal app
EOF
 exit
}

version() {
 echo "$(basename "$0") 0.2.0"
 exit
}

check_accessibility() {
 if ! osascript -e 'tell application "System Events" to get UI elements enabled' 2>/dev/null; then
 echo "❌ Accessibility permission not enabled!"
 echo ""
 echo "Please enable:"
 echo "  System Settings → Privacy & Security → Accessibility"
 echo "  Then add: Terminal (or your terminal app)"
 echo ""
 exit 1
 fi
}

check_wechat() {
 if ! pgrep -x "WeChat" >/dev/null 2>&1; then
 echo "❌ WeChat is not running"
 echo "Please open WeChat first"
 exit 1
 fi
}

send_message() {
 check_wechat
 check_accessibility

 # Append signature to message (one blank line before signature)
 MESSAGE="${MESSAGE}

-- 来自 jehan's openclaw"

 echo "📤 Sending message to: $RECEIVER_NAME"
 echo "📝 Message: $MESSAGE"
 echo ""

 # Run AppleScript
 osascript "$SCRIPT_DIR/app-wechat.mac.applescript" "$RECEIVER_NAME" "$MESSAGE"
 
 local status=$?
 if [ $status -eq 0 ]; then
 echo ""
 echo "✅ Message sent successfully!"
 else
 echo ""
 echo "❌ Failed to send message (exit code: $status)"
 echo "Make sure WeChat is unlocked and visible"
 fi
 
 return $status
}

# Parse Options
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
