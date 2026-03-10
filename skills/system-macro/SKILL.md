---
name: system-macro
description: Automate desktop operations via keyboard/mouse simulation and macros on Linux and macOS. Current support wechat-app send message
---

# System Macro

Simulate keyboard/mouse input and automate desktop application operations on Linux and macOS.

## Platform Requirements

- **Linux**: `xdotool`, `wmctrl`
- **macOS**: `osascript` (built-in)

## app-wechat

Send a message to a WeChat contact or group via keyboard simulation. WeChat must be running.

**Linux:**

```bash
scripts/app-wechat.linux.sh -r "<receiver>" -m "<message>"
```

**macOS:**

```bash
scripts/app-wechat.mac.sh -r "<receiver>" -m "<message>"
```

Options:

- `-r, --receiver` — Contact or group name (default: `#dev`)
- `-m, --message` — Message text (default: `test message`)
