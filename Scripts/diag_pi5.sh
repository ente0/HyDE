#!/usr/bin/env bash
# Pi 5 / Hyprland diagnostic dump.
# Prints everything needed to debug renderer/DRM issues. Safe and read-only.

set -u

hdr() { printf "\n\033[1;36m=== %s ===\033[0m\n" "$*"; }

hdr "Model & kernel"
cat /sys/firmware/devicetree/base/model 2>/dev/null; echo
uname -r

hdr "DRM devices"
ls -la /dev/dri/ 2>&1

hdr "Kernel modules (vc4 / v3d / brcm)"
lsmod | grep -E "v3d|vc4|brcm" || echo "(none loaded)"

hdr "User groups"
id

hdr "boot config dtoverlay/gpu_mem"
grep -E "dtoverlay|gpu_mem" /boot/firmware/config.txt 2>/dev/null \
    || grep -E "dtoverlay|gpu_mem" /boot/config.txt 2>/dev/null \
    || echo "(config.txt not found)"

hdr "EGL device probe"
if command -v eglinfo >/dev/null; then
    eglinfo -B 2>&1 | head -25
else
    echo "eglinfo missing. Install with: sudo pacman -S mesa-utils"
fi

hdr "Renderer env in current Hyprland process"
HYPR_PID="$(pgrep -x Hyprland | head -1 || true)"
if [ -n "$HYPR_PID" ]; then
    echo "Hyprland PID: $HYPR_PID"
    tr '\0' '\n' < "/proc/$HYPR_PID/environ" | grep -E "^(AQ_|WLR_|GBM_|XDG_RUNTIME|HYPRLAND_)" | sort
else
    echo "Hyprland is not running."
fi

hdr "Aquamarine errors in current Hyprland log (top 10 patterns)"
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
HIS="$(ls -t "$RUNTIME/hypr/" 2>/dev/null | head -1 || true)"
if [ -n "$HIS" ] && [ -f "$RUNTIME/hypr/$HIS/hyprland.log" ]; then
    grep -E "\[ERR\]|\[CRITICAL\]" "$RUNTIME/hypr/$HIS/hyprland.log" \
        | sed -E 's/[0-9]+/N/g' \
        | sort | uniq -c | sort -rn | head -10
else
    echo "No Hyprland log found at $RUNTIME/hypr/"
fi

hdr "uwsm env-hyprland.d files"
ls -la "$HOME/.config/uwsm/env-hyprland.d/" 2>/dev/null || echo "(directory not present)"

echo
echo "Done."
