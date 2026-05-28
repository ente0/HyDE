#!/usr/bin/env bash
# Quick log helpers for the current Hyprland session.
# Usage:
#   hyprlog.sh           # tail -f the live log
#   hyprlog.sh path      # print the log path
#   hyprlog.sh count     # count ERR/CRITICAL lines
#   hyprlog.sh top       # top error patterns (grouped, freq-sorted)
#   hyprlog.sh errors    # all ERR/CRITICAL lines

set -euo pipefail

RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
HIS="$(ls -t "$RUNTIME/hypr/" 2>/dev/null | head -1 || true)"
[ -z "$HIS" ] && { echo "No active Hyprland session in $RUNTIME/hypr/" >&2; exit 1; }
LOG="$RUNTIME/hypr/$HIS/hyprland.log"
[ -f "$LOG" ] || { echo "Log not found: $LOG" >&2; exit 1; }

case "${1:-tail}" in
    path)    echo "$LOG" ;;
    count)   grep -cE "\[ERR\]|\[CRITICAL\]" "$LOG" ;;
    errors)  grep -E "\[ERR\]|\[CRITICAL\]" "$LOG" ;;
    top)     grep -E "\[ERR\]|\[CRITICAL\]" "$LOG" \
                | sed -E 's/[0-9]+/N/g; s|/run/user/[0-9]+/[^ ]+||g' \
                | sort | uniq -c | sort -rn | head -30 ;;
    tail|*)  tail -f "$LOG" ;;
esac
