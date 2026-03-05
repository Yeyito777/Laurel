#!/bin/sh
# test-friend-mode.sh — simulate a fresh friend install
# Backs up your config and drops you into setup as a new user.

CONF_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/laurel"

echo "Backing up current config..."
cp "$CONF_DIR/config.sh" "$CONF_DIR/config.sh.bak" 2>/dev/null
cp "$CONF_DIR/ident" "$CONF_DIR/ident.bak" 2>/dev/null
rm -f "$CONF_DIR/config.sh" "$CONF_DIR/ident"

echo "Stopping current service..."
laurel stop 2>/dev/null

echo ""
echo "Starting fresh setup (pick option 2 → clips.yeyito.dev)..."
echo ""
laurel
