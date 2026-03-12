---
name: system-macro
description: Automate desktop applications on Linux and macOS through keyboard or mouse simulation. Current supported workflow: send a WeChat message or file with `scripts/app-wechat.sh`. Use when the user wants the agent to send a WeChat message from the local desktop or automate an existing WeChat app session.
---

# System Macro

Use this skill only for real desktop-side automation with visible side effects.

## Supported Workflow

### `app-wechat`

Send text and/or a file to a WeChat contact or group. WeChat must already be open and logged in.

Prefer the dispatcher unless you are debugging a platform-specific problem:

```bash
scripts/app-wechat.sh -r "<receiver>" -m "<message>" -f "<file-path>"
```

## Before Running

- Confirm the exact `receiver`, `message`, and optional `file` with the user.
- Warn the user not to touch the keyboard or mouse until the macro finishes.
- Verify WeChat is already running.
- Stop if both `message` and `file` are empty.
- Use the platform-specific script only when the dispatcher is not appropriate.

## Platform Requirements

- Linux: `xdotool`, `wmctrl`, and clipboard support via `xclip` or `xsel`
- macOS: `osascript` (built-in)

## Behavior

- If the message is **longer than 500 words**, the script writes the content to a temporary file and **sends the file** instead of pasting text.
- Otherwise, it sends a trimmed text message.
- If `-f` is provided, the file is sent before the text message.
- The dispatcher auto-detects Linux vs macOS.
- Both platform scripts show a confirmation dialog before sending.

## Platform Scripts

- Linux: `scripts/app-wechat.linux.sh` …
- macOS: `scripts/app-wechat.mac.sh` …

## Arguments

- `-r, --receiver` — Contact or group name
- `-m, --message` — Message text
- `-f, --file` — Path to a file to send (optional)
- `-h, --help` — Show usage
- `-v, --version` — Show version

## Recommended Flow

1. Collect the exact receiver, message, and optional file path.
2. Tell the user the macro will take control of the desktop briefly.
3. Run `scripts/app-wechat.sh` with quoted arguments.
4. Report whether the command succeeded or failed.

## Example

```bash
scripts/app-wechat.sh -r "#dev" -m "Build is green. Please review the latest changes."
```
