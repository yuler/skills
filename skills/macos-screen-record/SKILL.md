---
name: macos-screen-record
description: >-
  Record macOS screen video reliably from local, SSH, tmux, or remote agent
  sessions using Terminal.app Aqua delegation, pre-flight TCC/lock checks,
  graceful SIGINT stop, H.264 MP4 transcoding, and frame verification.
---

# macOS Screen Record

Capture macOS screen recordings reliably even when invoked from SSH, detached
`tmux` (`PPID=1`), UURemote, or background agent sessions.

## Why Direct Recording Fails in Remote / Agent Sessions

Running `screencapture -V` or `osascript` directly from an agent shell often
fails or records blank desktop wallpaper:

- **Background session context**: `launchctl managername` returns `Background`
  instead of `Aqua` when running inside SSH, background workers, or detached
  `tmux` servers (`PPID=1`).
- **TCC inheritance breaks**: macOS Transparency, Consent, and Control (TCC)
  grants (`Screen Recording`, `Accessibility`) belong to the GUI host app (such
  as Ghostty or Terminal.app). Processes spawned under a detached `tmux` or
  `Background` Mach bootstrap namespace do not inherit those grants.

## Solution: Pre-Flight + Terminal.app Aqua Delegation

1. Run a pre-flight check in the current shell.
2. If the caller lacks Screen Recording permission or is outside an `Aqua`
   session, delegate capture (and any optional GUI `System Events` actions) to
   `Terminal.app` via AppleScript:

   ```applescript
   tell application "Terminal" to do script "..."
   ```

   `Terminal.app` runs in the user's desktop `Aqua` GUI session and uses its own
   TCC permissions.

## Pre-Flight Checklist

Always inspect the host state before recording (`scripts/mac-record.sh check`):

1. **OS check**: Confirm `uname -s` is `Darwin`.
2. **Lock screen check**: Query `CGSessionCopyCurrentDictionary()` and check
   `CGSSessionScreenIsLocked`. If the screen is locked, stop and ask the user
   to unlock it.
3. **Permission checks**:
   - `CGPreflightScreenCaptureAccess()` — Screen Recording permission.
   - `AXIsProcessTrusted()` — Accessibility permission (required if also
     automating UI via `System Events`).
4. **Open System Settings if missing**:
   - Screen Recording:
     `open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"`
   - Accessibility:
     `open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"`
   - **Tip for the user**: Recommend authorizing **`Terminal.app`**
     (`/System/Applications/Utilities/Terminal.app`) rather than hunting for
     `/opt/homebrew/bin/tmux`. In the macOS file picker, press
     `Cmd+Shift+G` (Go to Folder) or `Cmd+Shift+.` (Show Hidden Files) if
     navigating to system paths.

## Recording Workflow

Use `scripts/mac-record.sh` for lifecycle management (`PID` and paths tracked in
`/tmp/mac-record.state`):

### 1. Pre-flight check

```bash
scripts/mac-record.sh check
# Open System Settings panes automatically if permissions are missing:
scripts/mac-record.sh check --open-settings
```

### 2. Start recording

```bash
scripts/mac-record.sh start -o /tmp/demo.mp4
# Optional display, region, and microphone audio:
scripts/mac-record.sh start -o /tmp/demo.mp4 --display 1 --rect 0,0,1440,900 --audio
```

If the caller lacks Screen Recording access, `start` automatically delegates to
`Terminal.app` in the `Aqua` session.

### 3. Check status

```bash
scripts/mac-record.sh status
```

### 4. Stop recording gracefully

```bash
scripts/mac-record.sh stop
```

- Sends **`kill -INT`** (`SIGINT`) to `screencapture` — **never `SIGKILL`**
  (`kill -9`), so QuickTime finalizes the `.mov` `moov` atom cleanly.
- If the target output ends in `.mp4`, transcodes the raw `.mov` to H.264 MP4:
  - Video filter: `scale='min(1920,iw)':-2`
  - Pixel format: `yuv420p`
  - Web streaming flag: `+faststart`
  - Removes the intermediate raw `.mov` once transcoding succeeds.

### 5. Post-recording verification

After `stop` completes, always verify both container metadata and visual content,
then clean up temporary frames:

```bash
# 1. Inspect streams, duration, and resolution
ffprobe -v error -show_entries format=duration,size -show_entries stream=codec_name,width,height -of default=noprint_wrappers=1 /tmp/demo.mp4

# 2. Extract 1-2 sample frames to verify real app windows (not blank wallpaper)
ffmpeg -y -ss 1 -i /tmp/demo.mp4 -frames:v 1 /tmp/verify-frame-1.png
ffmpeg -y -sseof -1 -i /tmp/demo.mp4 -frames:v 1 /tmp/verify-frame-2.png

# 3. Inspect the PNGs, then delete temporary frames
rm -f /tmp/verify-frame-1.png /tmp/verify-frame-2.png
```

## Strict Safety Rules

- **Never** bypass TCC prompts, lock screens, or macOS authentication dialogs.
- **Never** send `SIGKILL` (`kill -9`) to `screencapture` — it corrupts the
  `.mov` `moov` atom.
- **Never** proceed with recording when `CGSSessionScreenIsLocked` is true; ask
  the user to unlock the screen first.
- Always clean up temporary verification frames after inspecting the recording.
