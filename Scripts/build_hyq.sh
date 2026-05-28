#!/usr/bin/env bash
# Build hyq (hyprquery) from source.
# Needed on architectures without an upstream prebuilt binary (e.g. aarch64).
# Installs the resulting binary into ~/.local/bin/hyq.

set -euo pipefail

REPO_URL="https://github.com/HyDE-Project/hyprquery.git"
REF="${HYQ_REF:-main}"
BUILD_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hyde/hyprquery-build"
INSTALL_BIN="$HOME/.local/bin/hyq"

need() { command -v "$1" >/dev/null || { echo "missing: $1"; exit 1; }; }
need git
need cmake
need make
need pkg-config
need g++

echo "==> Cloning hyprquery ($REF) into $BUILD_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$(dirname "$BUILD_DIR")"
git clone --depth 1 --branch "$REF" "$REPO_URL" "$BUILD_DIR"

echo "==> Configuring"
cmake -S "$BUILD_DIR" -B "$BUILD_DIR/build" -DCMAKE_BUILD_TYPE=Release

echo "==> Building"
cmake --build "$BUILD_DIR/build" -j"$(nproc)"

echo "==> Installing to $INSTALL_BIN"
mkdir -p "$(dirname "$INSTALL_BIN")"
install -m755 "$BUILD_DIR/build/hyq" "$INSTALL_BIN"

echo "==> Done. $($INSTALL_BIN --version 2>/dev/null || echo 'hyq installed')"
