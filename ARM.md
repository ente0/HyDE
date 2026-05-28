# HyDE on ARM (aarch64 / Raspberry Pi)

This branch (`raspberry`) adapts HyDE for aarch64 Linux in general, and for **Raspberry Pi 5** specifically.

Tested on: Raspberry Pi 5 (16 GB), Arch Linux ARM, kernel 6.x, Hyprland.

## What changed vs `master`

| Component | Change |
|---|---|
| `Configs/.local/bin/hydectl` | Replaced with `hydectl-26.0.0-linux-arm64` (upstream). |
| `Configs/.local/bin/hyde-ipc` | Replaced with `hyde-ipc-0.1.6-linux-aarch64` (upstream). |
| `Configs/.local/bin/hyq` | Removed (no upstream aarch64 prebuilt). Build via `Scripts/build_hyq.sh`. |
| `Scripts/build_hyq.sh` | New. Compiles hyq from source into `~/.local/bin/hyq`. |
| `Scripts/hydevm/hydevm.sh` | Architecture-aware via `HYDEVM_ARCH` (defaults to `uname -m`). |
| `Configs/.config/uwsm/env-hyprland.d/01-pi5.sh` | New. Exports `AQ_DRM_DEVICES=/dev/dri/card1`, `WLR_NO_HARDWARE_CURSORS`, `WLR_DRM_NO_ATOMIC`, etc. *before* Hyprland starts. Gated on Broadcom V3D detection. |
| `Configs/.config/hypr/pi5.conf` | New. Lightweight decorations (no blur, no shadow, simple animations). No `env =` — those don't work for renderer init. |
| `Configs/.config/hypr/hyprland.conf` | Sources `pi5.conf`. |
| `Scripts/firstrun_pi5.sh` | New. Idempotent installer: adds `dtoverlay`, joins `video`/`render` groups, deploys `01-pi5.sh` and `pi5.conf` into `~/.config/`. |
| `Scripts/diag_pi5.sh` | New. One-shot diagnostic dump (DRM nodes, kernel modules, EGL probe, Hyprland env, top errors). |
| `Configs/.config/zsh/user.zsh` | Unrelated bugfix — orphan `elif` left from upstream regression. |

## Raspberry Pi 5 specifics

### The renderer trap

Pi 5 exposes two DRM nodes:

- `/dev/dri/card0` → VC4 (display controller, **no 3D**)
- `/dev/dri/card1` → V3D (the actual GL ES renderer)

Aquamarine picks `card0` by default and dies with `Can't create renderer, no matching devices found`. The fix is to export `AQ_DRM_DEVICES=/dev/dri/card1` **before Hyprland starts** — Hyprland's own `env =` directive runs *after* the renderer has already initialised and is therefore useless for this. We do it in [Configs/.config/uwsm/env-hyprland.d/01-pi5.sh](Configs/.config/uwsm/env-hyprland.d/01-pi5.sh), which uwsm sources before exec'ing Hyprland.

### What we disable on Pi 5

- **Blur**: 3-pass blur on every frame is unaffordable on V3D ES.
- **Shadows**: cheap, but off by default in the theme anyway.
- **Screen shader** (the wallbash colour shader): runs every frame.
- **Hardware cursors**: VC4 cursor planes are unreliable — software cursors are smoother.
- **VRR**: VC4 doesn't support it.
- Animation curves trimmed to a single `bezier` and short durations.
- `misc:vfr = true` to drop GPU load when nothing is moving.

### What still works fine

- Tiling, windowrules, keybindings, workspaces.
- Wallbash colour generation (CPU work, not GPU).
- Waybar (still readable without blur).
- hypridle, hyprlock (without blur layouts).

### What you may want to disable further

- **CAVA in waybar**: heavy CPU.
- **Animated wallpapers** via swww with video: skips frames.
- **hyprlock blur**: edit `~/.config/hypr/hyprlock/theme.conf` and turn `blur_size`/`blur_passes` to 0 in the background block.

## Setup on a Pi 5 (or any aarch64 box)

```bash
git clone -b raspberry https://github.com/ente0/HyDE.git
cd HyDE
./Scripts/install.sh

# Pi 5: install the renderer env, dtoverlay, group membership, etc.
./Scripts/firstrun_pi5.sh

# Build hyq from source — requires git cmake make gcc pkg-config
./Scripts/build_hyq.sh

# Verify everything before logging into Hyprland
./Scripts/diag_pi5.sh
```

If `diag_pi5.sh` shows only `card0` under `/dev/dri/`, the V3D driver isn't loaded. Confirm `dtoverlay=vc4-kms-v3d` is in `/boot/firmware/config.txt` and reboot.

### Quick recovery after a Hyprland session

If you change anything in `~/.config/uwsm/env-hyprland.d/`, log fully out of Hyprland and back in (or reboot). Hyprland's own `hyprctl reload` does **not** pick up renderer env changes — they're only read when Hyprland is exec'd.

## Keeping binaries up to date

```bash
gh release download --repo HyDE-Project/hydectl  --pattern '*linux-arm64*'  -O - | tar -xz -C Configs/.local/bin/
gh release download --repo HyDE-Project/hyde-ipc --pattern '*linux-aarch64.tar.gz' -O - \
  | tar -xz --strip-components=1 -C Configs/.local/bin/ '*/hyde-ipc'
./Scripts/build_hyq.sh   # hyq always built from source
```

## hydevm on aarch64

Works with `qemu-system-aarch64`. No official Arch Linux cloud qcow2 for ARM — provide your own image:

```bash
HYDEVM_IMAGE_URL='https://example.com/aarch64.qcow2' hydevm
```

Required: `qemu-system-aarch64`, `edk2-aarch64`.

## Known limitations

- AUR packages without aarch64 PKGBUILDs may fail (`spotify`, `steam`, etc.) — these have no ARM builds in Arch repos and will simply not install.
- Hyprland on Pi is functional but not buttery — expect occasional frame drops with many windows.
