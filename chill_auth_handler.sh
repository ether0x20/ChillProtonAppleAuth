#!/usr/bin/env bash
set -euo pipefail

APPID="3548580"
PROTON_DIR="$HOME/.steam/steam/steamapps/common/Proton 9.0 (Beta)"
WINE="$PROTON_DIR/files/bin/wine"
WINESERVER="$PROTON_DIR/files/bin/wineserver"
WINEPREFIX="$HOME/.steam/steam/steamapps/compatdata/$APPID/pfx"
GAME_EXE="Z:\\home\\ethan\\.steam\\steam\\steamapps\\common\\Chill with You Lo-Fi Story\\Chill With You.exe"

INJECT_URL="${1:-}"

if [[ -z "$INJECT_URL" ]]; then
    echo "Error: No OAuth URL provided." >&2
    exit 1
fi

if [[ ! "$INJECT_URL" =~ ^chill\.oauth: ]]; then
    echo "Error: Not a chill.oauth URL: $INJECT_URL" >&2
    exit 1
fi

export WINEPREFIX
export WINEFSYNC=1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Received OAuth callback: $INJECT_URL" >&2

is_game_running() {
    if "$WINESERVER" -p "$WINEPREFIX" &>/dev/null; then
        return 0
    fi
    if pgrep -f "Chill With You" &>/dev/null; then
        return 0
    fi
    return 1
}

if ! is_game_running; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Game is not running. Try again." >&2
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Injecting OAuth URL into game..." >&2
"$WINE" "$GAME_EXE" "$INJECT_URL"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Injection complete." >&2
