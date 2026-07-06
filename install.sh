#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

mkdir -p "$BIN_DIR" "$APP_DIR"

cp "$SCRIPT_DIR/chill_oauth_handler.sh" "$BIN_DIR/chill_oauth_handler.sh"
chmod +x "$BIN_DIR/chill_oauth_handler.sh"

cp "$SCRIPT_DIR/chill-oauth-handler.desktop" "$APP_DIR/chill-oauth-handler.desktop"

update-desktop-database "$APP_DIR" 2>/dev/null || true
xdg-mime default chill-oauth-handler.desktop x-scheme-handler/chill.oauth

echo "安装完成。"
echo "  - 脚本: $BIN_DIR/chill_oauth_handler.sh"
echo "  - 桌面入口: $APP_DIR/chill-oauth-handler.desktop"
