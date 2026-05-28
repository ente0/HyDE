#!/usr/bin/env bash
# Pi 5 first-run setup.
# Idempotent: safe to re-run. Run after `Scripts/install.sh`.

set -euo pipefail

CONFIGS_DIR="$(cd "$(dirname "$0")/.." && pwd)/Configs"

say() { printf "\n\033[1;36m==> %s\033[0m\n" "$*"; }
warn() { printf "\033[1;33m!! %s\033[0m\n" "$*"; }

# ── 1. Confirm we are on a Pi ────────────────────────────────────────────
if ! grep -q "Raspberry Pi" /sys/firmware/devicetree/base/model 2>/dev/null; then
    warn "This machine doesn't look like a Raspberry Pi. Continuing anyway."
fi

# ── 2. dtoverlay sanity check ────────────────────────────────────────────
CONFIG_TXT=""
for p in /boot/firmware/config.txt /boot/config.txt; do
    [ -f "$p" ] && CONFIG_TXT="$p" && break
done

if [ -z "$CONFIG_TXT" ]; then
    warn "Couldn't find config.txt — skipping dtoverlay check."
else
    if ! grep -qE "^\s*dtoverlay=vc4-kms-v3d" "$CONFIG_TXT"; then
        say "Adding dtoverlay=vc4-kms-v3d to $CONFIG_TXT"
        echo "dtoverlay=vc4-kms-v3d" | sudo tee -a "$CONFIG_TXT" >/dev/null
        warn "Reboot required for dtoverlay to take effect."
    else
        say "dtoverlay=vc4-kms-v3d already present in $CONFIG_TXT"
    fi
fi

# ── 3. Group membership (video / render) ─────────────────────────────────
for grp in video render; do
    if ! id -nG "$USER" | grep -qw "$grp"; then
        say "Adding $USER to group $grp"
        sudo usermod -aG "$grp" "$USER"
        REBOOT_NEEDED=1
    fi
done

# ── 4. Install uwsm env-hyprland.d/01-pi5.sh ─────────────────────────────
TGT="$HOME/.config/uwsm/env-hyprland.d"
mkdir -p "$TGT"
install -m644 "$CONFIGS_DIR/.config/uwsm/env-hyprland.d/01-pi5.sh" "$TGT/01-pi5.sh"
say "Installed $TGT/01-pi5.sh"

# ── 5. Install pi5.conf and ensure it's sourced ──────────────────────────
HYPR_DIR="$HOME/.config/hypr"
install -m644 "$CONFIGS_DIR/.config/hypr/pi5.conf" "$HYPR_DIR/pi5.conf"
say "Installed $HYPR_DIR/pi5.conf"

if ! grep -q "pi5.conf" "$HYPR_DIR/hyprland.conf"; then
    echo "source = ./pi5.conf" >> "$HYPR_DIR/hyprland.conf"
    say "Wired pi5.conf into hyprland.conf"
fi

# ── 6. Verify GPU stack ──────────────────────────────────────────────────
if ! command -v eglinfo >/dev/null; then
    warn "mesa-utils not installed (eglinfo missing). Install with: sudo pacman -S mesa-utils"
fi

if [ ! -e /dev/dri/card1 ]; then
    warn "/dev/dri/card1 does not exist. V3D driver not loaded?"
    warn "Check: lsmod | grep v3d"
fi

# ── 7. Summary ───────────────────────────────────────────────────────────
echo
say "Done."
if [ -n "${REBOOT_NEEDED:-}" ]; then
    warn "Reboot to pick up group changes."
else
    echo "Log out of your Hyprland session and back in to apply uwsm env changes."
fi
echo "Diagnose with: Scripts/diag_pi5.sh"
