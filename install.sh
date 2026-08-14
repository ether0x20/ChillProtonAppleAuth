#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

mkdir -p "$BIN_DIR" "$APP_DIR"

cp "$SCRIPT_DIR/chill_auth_handler.sh" "$BIN_DIR/chill_auth_handler.sh"
chmod +x "$BIN_DIR/chill_auth_handler.sh"

cp "$SCRIPT_DIR/chill_auth_handler.desktop" "$APP_DIR/chill_auth_handler.desktop"

update-desktop-database "$APP_DIR" 2>/dev/null || true
xdg-mime default chill_auth_handler.desktop x-scheme-handler/chill.oauth

echo "Install Complete"
echo "  - Script: $BIN_DIR/chill_auth_handler.sh"
echo "  - Desktop File: $APP_DIR/chill_auth_handler.desktop"
