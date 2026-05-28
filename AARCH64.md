# HyDE on aarch64 (ARM64)

This branch (`aarch64-support`) adapts HyDE to run on aarch64 Linux (e.g. Asahi Linux on Apple Silicon, Arch Linux ARM, Pi 4/5, Ampere/Graviton servers).

## What changed vs `master`

| Component | Change |
|---|---|
| `Configs/.local/bin/hydectl` | Replaced x86_64 binary with `hydectl-26.0.0-linux-arm64` from upstream releases. |
| `Configs/.local/bin/hyde-ipc` | Replaced x86_64 binary with `hyde-ipc-0.1.6-linux-aarch64` from upstream releases. |
| `Configs/.local/bin/hyq` | Removed. No upstream aarch64 release exists; build from source via `Scripts/build_hyq.sh`. |
| `Scripts/build_hyq.sh` | New. Clones `HyDE-Project/hyprquery` and builds `hyq` into `~/.local/bin/hyq`. |
| `Scripts/hydevm/hydevm.sh` | Now architecture-aware via `HYDEVM_ARCH` (defaults to `uname -m`). On aarch64 uses `qemu-system-aarch64`, `-machine virt`, UEFI firmware, and `cortex-a72` TCG fallback. |

## Setup on an aarch64 machine

```bash
# 1. Clone this branch
git clone -b aarch64-support https://github.com/HyDE-Project/HyDE.git
cd HyDE

# 2. Run the regular installer
./Scripts/install.sh

# 3. Build hyq (requires git, cmake, make, pkg-config, g++)
./Scripts/build_hyq.sh
```

## Keeping binaries up to date

When upstream releases new versions, refresh manually:

```bash
# hydectl (Go, statically linked)
gh release download --repo HyDE-Project/hydectl --pattern '*linux-arm64*' -O - \
  | tar -xz -C Configs/.local/bin/
# (rename extracted file to `hydectl` if needed)

# hyde-ipc
gh release download --repo HyDE-Project/hyde-ipc --pattern '*linux-aarch64.tar.gz' -O - \
  | tar -xz --strip-components=1 -C Configs/.local/bin/ '*/hyde-ipc'

# hyq — always rebuild from source
./Scripts/build_hyq.sh
```

## hydevm on aarch64

Working but caveat-laden. There is no official Arch Linux cloud `qcow2` for aarch64. Provide your own image:

```bash
HYDEVM_IMAGE_URL='https://example.com/my-aarch64-cloud.qcow2' hydevm
```

Required dependencies (Arch Linux ARM): `qemu-system-aarch64`, `edk2-aarch64`.

## Known limitations

- AUR packages without aarch64 PKGBUILDs may fail during install. Check each in `Scripts/pkg_*.lst` if you hit a build error.
- `steam`, `spotify`, and other closed-source packages have no aarch64 builds in Arch repos — they will simply not install.
