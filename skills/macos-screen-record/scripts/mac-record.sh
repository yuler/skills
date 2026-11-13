#!/usr/bin/env bash
# Manage macOS screen recording with Aqua Terminal.app delegation and MP4 transcoding.
set -euo pipefail

STATE_FILE="/tmp/mac-record.state"
LOG_FILE="/tmp/mac-record.log"
DELEGATE_STATUS_FILE="/tmp/mac-record.delegate.status"
SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

usage() {
  cat <<'EOF'
Usage: mac-record.sh <command> [options]

Commands:
  check     Run pre-flight checks (OS, launchctl session, lock screen, TCC, tools)
  start     Start screen recording (delegates to Terminal.app if caller lacks TCC)
  stop      Stop active recording with SIGINT and transcode to MP4 if requested
  status    Show current recording status

Check options:
  --open-settings       Open System Settings TCC panes when permissions are denied
  --strict              Exit non-zero if screen is locked or Screen Recording is denied

Start options:
  -o, --output <path>   Output file (.mp4 or .mov; default: /tmp/mac-record-<ts>.mp4)
  -d, --display <id>    Display ID passed to screencapture -D<id>
  -r, --rect <x,y,w,h>  Capture region passed to screencapture -R<x,y,w,h>
  -a, --audio           Record default audio input (screencapture -g)
  --open-settings       Open System Settings if Terminal.app also lacks permission
  --no-delegate         Fail instead of delegating to Terminal.app

Global options:
  -h, --help            Show this help message
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

require_darwin() {
  local os
  os="$(uname -s)"
  if [[ "$os" != "Darwin" ]]; then
    die "Unsupported OS '$os'. macOS (Darwin) is required."
  fi
}

query_macos_security_state() {
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import ctypes

cg = ctypes.CDLL("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")
cf = ctypes.CDLL("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")
app = ctypes.CDLL("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices")

cg.CGPreflightScreenCaptureAccess.restype = ctypes.c_bool
app.AXIsProcessTrusted.restype = ctypes.c_bool
cg.CGSessionCopyCurrentDictionary.restype = ctypes.c_void_p

cf.CFStringCreateWithCString.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_uint32]
cf.CFStringCreateWithCString.restype = ctypes.c_void_p
cf.CFDictionaryGetValue.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
cf.CFDictionaryGetValue.restype = ctypes.c_void_p
cf.CFBooleanGetValue.argtypes = [ctypes.c_void_p]
cf.CFBooleanGetValue.restype = ctypes.c_bool
cf.CFRelease.argtypes = [ctypes.c_void_p]

locked = False
session_dict = cg.CGSessionCopyCurrentDictionary()
if session_dict:
    key = cf.CFStringCreateWithCString(None, b"CGSSessionScreenIsLocked", 0x08000100)
    val = cf.CFDictionaryGetValue(session_dict, key)
    if val:
        locked = bool(cf.CFBooleanGetValue(val))
    cf.CFRelease(key)
    cf.CFRelease(session_dict)

sc = bool(cg.CGPreflightScreenCaptureAccess())
ax = bool(app.AXIsProcessTrusted())
print(f"LOCKED={'true' if locked else 'false'}")
print(f"SCREEN_CAPTURE={'true' if sc else 'false'}")
print(f"ACCESSIBILITY={'true' if ax else 'false'}")
PY
    return 0
  fi

  if command -v swift >/dev/null 2>&1; then
    swift -e '
import CoreGraphics
import ApplicationServices
let d = CGSessionCopyCurrentDictionary() as? [String: Any]
let locked = (d?["CGSSessionScreenIsLocked"] as? Bool) ?? false
let sc = CGPreflightScreenCaptureAccess()
let ax = AXIsProcessTrusted()
print("LOCKED=\(locked)")
print("SCREEN_CAPTURE=\(sc)")
print("ACCESSIBILITY=\(ax)")
'
    return 0
  fi

  die "Either python3 or swift is required to inspect macOS session and TCC state."
}

load_security_state() {
  local output
  output="$(query_macos_security_state)"
  LOCKED="false"
  SCREEN_CAPTURE="false"
  ACCESSIBILITY="false"
  while IFS='=' read -r k v; do
    case "$k" in
      LOCKED) LOCKED="$v" ;;
      SCREEN_CAPTURE) SCREEN_CAPTURE="$v" ;;
      ACCESSIBILITY) ACCESSIBILITY="$v" ;;
    esac
  done <<<"$output"
}

open_privacy_pane() {
  local pane="$1"
  open "x-apple.systempreferences:com.apple.preference.security?${pane}" >/dev/null 2>&1 || true
}

print_tcc_tip() {
  cat >&2 <<'EOF'
Tip: Grant permission to Terminal.app (/System/Applications/Utilities/Terminal.app)
rather than hunting for /opt/homebrew/bin/tmux.
In the macOS file picker: Cmd+Shift+G opens Go to Folder, Cmd+Shift+. shows hidden files.
EOF
}

get_session_manager() {
  launchctl managername 2>/dev/null || echo "unknown"
}

is_pid_running() {
  local pid="$1"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

read_state_file() {
  STATE_PID=""
  STATE_RAW_OUTPUT=""
  STATE_TARGET_OUTPUT=""
  STATE_STARTED_AT=""
  STATE_DELEGATED=""
  # shellcheck disable=SC1090
  source "$STATE_FILE"
}

write_state_file() {
  local pid="$1"
  local raw_output="$2"
  local target_output="$3"
  local started_at="$4"
  local delegated="$5"
  {
    printf 'STATE_PID=%q\n' "$pid"
    printf 'STATE_RAW_OUTPUT=%q\n' "$raw_output"
    printf 'STATE_TARGET_OUTPUT=%q\n' "$target_output"
    printf 'STATE_STARTED_AT=%q\n' "$started_at"
    printf 'STATE_DELEGATED=%q\n' "$delegated"
  } >"$STATE_FILE"
}

to_abs_path() {
  local p="$1"
  local dir
  dir="$(dirname "$p")"
  mkdir -p "$dir"
  printf '%s/%s\n' "$(cd "$dir" && pwd)" "$(basename "$p")"
}

cmd_check() {
  local open_settings=false
  local strict=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --open-settings) open_settings=true; shift ;;
      --strict) strict=true; shift ;;
      -h|--help) usage; exit 0 ;;
      *) die "Unknown option for check: $1" ;;
    esac
  done

  require_darwin
  load_security_state

  local session_mgr
  session_mgr="$(get_session_manager)"

  echo "OS:                Darwin ($(sw_vers -productVersion 2>/dev/null || uname -r))"
  echo "Launchctl session: ${session_mgr}"
  echo "Screen locked:     ${LOCKED}"
  echo "Screen Recording:  $([[ "$SCREEN_CAPTURE" == "true" ]] && echo "granted" || echo "denied (current process)")"
  echo "Accessibility:     $([[ "$ACCESSIBILITY" == "true" ]] && echo "granted" || echo "denied (current process)")"

  local tool
  for tool in screencapture ffmpeg ffprobe osascript; do
    if command -v "$tool" >/dev/null 2>&1; then
      echo "Tool ${tool}: $(command -v "$tool")"
    else
      echo "Tool ${tool}: MISSING"
    fi
  done

  if [[ "$LOCKED" == "true" ]]; then
    echo "Warning: Screen is currently locked. Unlock macOS before recording." >&2
  fi

  if [[ "$SCREEN_CAPTURE" != "true" || "$ACCESSIBILITY" != "true" ]]; then
    if [[ "$session_mgr" != "Aqua" ]]; then
      echo "Note: Current session is '${session_mgr}'. Direct TCC checks may be denied here; 'start' will delegate to Terminal.app (Aqua)."
    fi
    if [[ "$open_settings" == "true" ]]; then
      [[ "$SCREEN_CAPTURE" != "true" ]] && open_privacy_pane "Privacy_ScreenCapture"
      [[ "$ACCESSIBILITY" != "true" ]] && open_privacy_pane "Privacy_Accessibility"
      print_tcc_tip
    fi
  fi

  if [[ "$strict" == "true" ]] && [[ "$LOCKED" == "true" || "$SCREEN_CAPTURE" != "true" ]]; then
    exit 1
  fi
}

launch_capture_here() {
  local target_output="$1"
  local display_id="$2"
  local rect="$3"
  local record_audio="$4"
  local foreground="$5"
  local delegated="$6"

  local lower_target raw_output
  lower_target="$(printf '%s' "$target_output" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lower_target" == *.mov ]]; then
    raw_output="$target_output"
  else
    raw_output="/tmp/mac-record-raw-$$.mov"
  fi

  local -a cmd=(screencapture -v -x)
  [[ -n "$display_id" ]] && cmd+=("-D${display_id}")
  [[ -n "$rect" ]] && cmd+=("-R${rect}")
  [[ "$record_audio" == "true" ]] && cmd+=(-g)
  cmd+=("$raw_output")

  : >"$LOG_FILE"
  "${cmd[@]}" </dev/null >>"$LOG_FILE" 2>&1 &
  local rec_pid=$!

  sleep 0.6
  if ! is_pid_running "$rec_pid"; then
    if [[ "$delegated" == "true" ]]; then
      echo "FAILED" >"$DELEGATE_STATUS_FILE"
    fi
    echo "screencapture failed to stay running. Log output:" >&2
    cat "$LOG_FILE" >&2 || true
    exit 1
  fi

  local started_at
  started_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  write_state_file "$rec_pid" "$raw_output" "$target_output" "$started_at" "$delegated"

  if [[ "$delegated" == "true" ]]; then
    echo "OK" >"$DELEGATE_STATUS_FILE"
  fi

  echo "Recording started (PID: ${rec_pid}, output: ${target_output})"

  if [[ "$foreground" == "true" ]]; then
    # Keep Terminal.app as the parent process so TCC attribution holds until SIGINT.
    wait "$rec_pid" || true
  fi
}

delegate_to_terminal() {
  local target_output="$1"
  local display_id="$2"
  local rect="$3"
  local record_audio="$4"
  local open_settings="$5"

  command -v osascript >/dev/null 2>&1 || die "osascript is required to delegate to Terminal.app."

  local -a inner_args=("$SELF_PATH" start --foreground --no-delegate -o "$target_output")
  [[ -n "$display_id" ]] && inner_args+=(-d "$display_id")
  [[ -n "$rect" ]] && inner_args+=(-r "$rect")
  [[ "$record_audio" == "true" ]] && inner_args+=(-a)
  [[ "$open_settings" == "true" ]] && inner_args+=(--open-settings)

  local quoted_cmd="MAC_RECORD_DELEGATED=1"
  local arg
  for arg in "${inner_args[@]}"; do
    quoted_cmd+=" $(printf '%q' "$arg")"
  done

  rm -f "$DELEGATE_STATUS_FILE"
  : >"$LOG_FILE"

  osascript - "$quoted_cmd" <<'APPLESCRIPT' >/dev/null
on run argv
    tell application "Terminal"
        do script (item 1 of argv)
    end tell
end run
APPLESCRIPT

  local attempts=0
  local max_attempts=50
  while (( attempts < max_attempts )); do
    if [[ -f "$DELEGATE_STATUS_FILE" ]]; then
      local status
      status="$(tr -d '[:space:]' <"$DELEGATE_STATUS_FILE")"
      case "$status" in
        OK)
          read_state_file
          echo "Recording started via Terminal.app Aqua delegation (PID: ${STATE_PID}, output: ${STATE_TARGET_OUTPUT})"
          return 0
          ;;
        DENIED)
          cat "$LOG_FILE" >&2 || true
          die "Terminal.app lacks Screen Recording permission. Grant it in System Settings > Privacy & Security > Screen Recording."
          ;;
        FAILED)
          cat "$LOG_FILE" >&2 || true
          die "Delegated screencapture failed to start."
          ;;
      esac
    fi
    sleep 0.2
    attempts=$((attempts + 1))
  done

  die "Timed out waiting for Terminal.app to start recording. Check Automation/TCC prompts on the desktop and $LOG_FILE."
}

cmd_start() {
  local output=""
  local display_id=""
  local rect=""
  local record_audio=false
  local open_settings=false
  local allow_delegate=true
  local foreground=false
  local delegated="${MAC_RECORD_DELEGATED:-0}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output)
        [[ $# -ge 2 ]] || die "Missing value for $1"
        output="$2"
        shift 2
        ;;
      -d|--display)
        [[ $# -ge 2 ]] || die "Missing value for $1"
        display_id="$2"
        shift 2
        ;;
      -r|--rect)
        [[ $# -ge 2 ]] || die "Missing value for $1"
        rect="$2"
        shift 2
        ;;
      -a|--audio) record_audio=true; shift ;;
      --open-settings) open_settings=true; shift ;;
      --no-delegate) allow_delegate=false; shift ;;
      --foreground) foreground=true; shift ;;
      -h|--help) usage; exit 0 ;;
      *) die "Unknown option for start: $1" ;;
    esac
  done

  require_darwin
  command -v screencapture >/dev/null 2>&1 || die "screencapture binary not found."

  if [[ -f "$STATE_FILE" ]]; then
    read_state_file
    if is_pid_running "$STATE_PID"; then
      die "Recording already in progress (PID: ${STATE_PID}, output: ${STATE_TARGET_OUTPUT}). Run 'stop' first."
    fi
    rm -f "$STATE_FILE"
  fi

  if [[ -z "$output" ]]; then
    output="/tmp/mac-record-$(date '+%Y%m%d-%H%M%S').mp4"
  fi
  output="$(to_abs_path "$output")"

  load_security_state
  if [[ "$LOCKED" == "true" ]]; then
    [[ "$delegated" == "1" ]] && echo "FAILED" >"$DELEGATE_STATUS_FILE"
    die "Screen is locked (CGSSessionScreenIsLocked=true). Ask the user to unlock macOS first."
  fi

  local session_mgr
  session_mgr="$(get_session_manager)"

  if [[ "$SCREEN_CAPTURE" != "true" ]]; then
    if [[ "$allow_delegate" == "true" && "$delegated" != "1" ]]; then
      echo "Caller lacks Screen Recording access (session: ${session_mgr}); delegating to Terminal.app..."
      delegate_to_terminal "$output" "$display_id" "$rect" "$record_audio" "$open_settings"
      return 0
    fi

    if [[ "$delegated" == "1" ]]; then
      {
        echo "Error: Terminal.app lacks Screen Recording permission."
        print_tcc_tip
      } >>"$LOG_FILE"
      [[ "$open_settings" == "true" ]] && open_privacy_pane "Privacy_ScreenCapture"
      echo "DENIED" >"$DELEGATE_STATUS_FILE"
      exit 1
    fi

    if [[ "$open_settings" == "true" ]]; then
      open_privacy_pane "Privacy_ScreenCapture"
      print_tcc_tip
    fi
    die "Screen Recording permission is denied and delegation is disabled."
  fi

  local is_delegated_flag="false"
  [[ "$delegated" == "1" ]] && is_delegated_flag="true"
  launch_capture_here "$output" "$display_id" "$rect" "$record_audio" "$foreground" "$is_delegated_flag"
}

cmd_stop() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      *) die "Unknown option for stop: $1" ;;
    esac
  done

  require_darwin
  [[ -f "$STATE_FILE" ]] || die "No active recording state found at $STATE_FILE."

  read_state_file
  [[ -n "$STATE_PID" ]] || die "Invalid state file: missing PID."

  if is_pid_running "$STATE_PID"; then
    # Use SIGINT only (never SIGKILL) so screencapture writes the .mov moov atom cleanly.
    kill -INT "$STATE_PID"
    local attempts=0
    local max_attempts=75
    while is_pid_running "$STATE_PID" && (( attempts < max_attempts )); do
      sleep 0.2
      attempts=$((attempts + 1))
    done
    if is_pid_running "$STATE_PID"; then
      die "screencapture (PID: ${STATE_PID}) did not exit after SIGINT; refusing to send SIGKILL to avoid corrupting .mov."
    fi
  else
    echo "Warning: screencapture process ${STATE_PID} was already stopped; attempting to finalize output." >&2
  fi

  if [[ ! -s "$STATE_RAW_OUTPUT" ]]; then
    rm -f "$STATE_FILE"
    die "Recorded file is missing or empty: $STATE_RAW_OUTPUT"
  fi

  local lower_target
  lower_target="$(printf '%s' "$STATE_TARGET_OUTPUT" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lower_target" == *.mp4 ]]; then
    command -v ffmpeg >/dev/null 2>&1 || die "ffmpeg is required to transcode '$STATE_RAW_OUTPUT' to MP4."
    mkdir -p "$(dirname "$STATE_TARGET_OUTPUT")"
    ffmpeg -y -loglevel error -i "$STATE_RAW_OUTPUT" \
      -vf "scale='min(1920,iw)':-2" \
      -c:v libx264 -pix_fmt yuv420p -movflags +faststart \
      -c:a aac \
      "$STATE_TARGET_OUTPUT"
    [[ -s "$STATE_TARGET_OUTPUT" ]] || die "MP4 transcoding produced an empty file: $STATE_TARGET_OUTPUT"
    if [[ "$STATE_RAW_OUTPUT" != "$STATE_TARGET_OUTPUT" ]]; then
      rm -f "$STATE_RAW_OUTPUT"
    fi
  fi

  rm -f "$STATE_FILE" "$DELEGATE_STATUS_FILE"
  echo "Recording saved: ${STATE_TARGET_OUTPUT}"
}

cmd_status() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      *) die "Unknown option for status: $1" ;;
    esac
  done

  if [[ ! -f "$STATE_FILE" ]]; then
    echo "status: idle"
    return 0
  fi

  read_state_file
  if is_pid_running "$STATE_PID"; then
    echo "status:     recording"
    echo "pid:        ${STATE_PID}"
    echo "output:     ${STATE_TARGET_OUTPUT}"
    echo "raw_output: ${STATE_RAW_OUTPUT}"
    echo "started_at: ${STATE_STARTED_AT}"
    echo "delegated:  ${STATE_DELEGATED}"
  else
    echo "status:     stale (PID ${STATE_PID} is not running)"
    echo "output:     ${STATE_TARGET_OUTPUT}"
    echo "raw_output: ${STATE_RAW_OUTPUT}"
    echo "started_at: ${STATE_STARTED_AT}"
  fi
}

main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  local subcommand="$1"
  shift
  case "$subcommand" in
    check) cmd_check "$@" ;;
    start) cmd_start "$@" ;;
    stop) cmd_stop "$@" ;;
    status) cmd_status "$@" ;;
    -h|--help|help) usage; exit 0 ;;
    *) die "Unknown command '$subcommand'. Run with --help for usage." ;;
  esac
}

main "$@"
