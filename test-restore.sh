#!/bin/sh
# test-restore.sh — restore your real config after testing friend mode.

CONF_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/laurel"

if [ ! -f "$CONF_DIR/config.sh.bak" ]; then
    echo "No backup found — nothing to restore."
    exit 1
fi

echo "Stopping test service..."
laurel stop 2>/dev/null

echo "Restoring config..."
cp "$CONF_DIR/config.sh.bak" "$CONF_DIR/config.sh"
cp "$CONF_DIR/ident.bak" "$CONF_DIR/ident"
rm -f "$CONF_DIR/config.sh.bak" "$CONF_DIR/ident.bak"

echo "Starting service..."
laurel start

echo ""
echo "Restored. Current status:"
laurel
