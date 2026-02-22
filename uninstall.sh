#!/bin/sh
# Uninstall Laurel locally
set -e

BIN_DIR="${HOME}/.local/bin"
DATA_DIR="${HOME}/.local/share/laurel"
SERVICE_DIR="${HOME}/.config/systemd/user"

echo "==> Stopping and disabling service"
systemctl --user stop laurel-replay.service 2>/dev/null || true
systemctl --user disable laurel-replay.service 2>/dev/null || true
rm -f "${SERVICE_DIR}/laurel-replay.service"
systemctl --user daemon-reload

echo "==> Removing scripts and binary"
rm -f "${BIN_DIR}/laurel-replay"
rm -f "${BIN_DIR}/laurel-clip"
rm -f "${BIN_DIR}/laurel-hotkey"

echo "==> Removing data"
rm -rf "$DATA_DIR"

echo ""
echo "Note: gpu-screen-recorder was NOT uninstalled."
echo "To remove it: sudo pacman -Rs gpu-screen-recorder"
echo "Done."
