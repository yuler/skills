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
    echo "TODO for macos"
    echo "Please implement this function"
    exit 1
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