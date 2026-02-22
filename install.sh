#!/bin/sh
# Install Laurel locally
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
DATA_DIR="${HOME}/.local/share/laurel"
SERVICE_DIR="${HOME}/.config/systemd/user"

echo "==> Installing gpu-screen-recorder"
sudo pacman -S --needed --noconfirm gpu-screen-recorder

echo "==> Compiling laurel-hotkey"
make -C "$SCRIPT_DIR" laurel-hotkey

echo "==> Installing scripts and binary to ${BIN_DIR}"
mkdir -p "$BIN_DIR"
cp "${SCRIPT_DIR}/laurel-replay" "${BIN_DIR}/laurel-replay"
cp "${SCRIPT_DIR}/laurel-clip" "${BIN_DIR}/laurel-clip"
cp "${SCRIPT_DIR}/laurel-hotkey" "${BIN_DIR}/laurel-hotkey"
chmod +x "${BIN_DIR}/laurel-replay" "${BIN_DIR}/laurel-clip" "${BIN_DIR}/laurel-hotkey"

echo "==> Installing config and template to ${DATA_DIR}"
mkdir -p "$DATA_DIR"
cp "${SCRIPT_DIR}/config.sh" "${DATA_DIR}/config.sh"
cp "${SCRIPT_DIR}/server/clip-template.html" "${DATA_DIR}/clip-template.html"

echo "==> Installing systemd user service"
mkdir -p "$SERVICE_DIR"
cp "${SCRIPT_DIR}/laurel-replay.service" "${SERVICE_DIR}/laurel-replay.service"
systemctl --user daemon-reload
systemctl --user enable laurel-replay.service
echo "    Service enabled. Start with: systemctl --user start laurel-replay"

echo "==> Creating clip cache directory"
mkdir -p "${XDG_CACHE_HOME:-${HOME}/.cache}/laurel"

echo ""
echo "Done. Hotkey (Super+G) is handled by laurel-hotkey — no dwm config needed."
