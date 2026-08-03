# Chill with You: Lo-Fi Story Apple ID Login on Linux + Proton platform

This tutorial will guide you through binding your Apple ID while running *Chill with You: Lo-Fi Story* via Steam Proton on Linux Mint 22.3 (also applicable to other Linux distributions), and implement **automatic browser callback injection** so you never have to manually copy a link again.

---

## 1. Background

- The game relies on Apple ID OAuth login, which opens the browser to Apple's authentication page.
- After a successful login, the browser tries to open a `chill.oauth://...` link to pass the authorization info back to the game.
- Proton cannot handle such custom URL protocols automatically, so the game never receives the callback and the login hangs.
- This tutorial covers two methods:
  - **Method A (Manual)**: Copy the URL once and inject it via a command for a quick login.
  - **Method B (Automated, Recommended)**: Write a script + register a system protocol handler for fully automatic logins every time.

---

## 2. Preparation (One-Time Setup)

### 2.1 Find the AppID
Right-click the game in your Steam library → Properties → Updates and find the AppID (this guide uses `3548580` as an example).  
Or check the directory list:
```bash
ls ~/.steam/steam/steamapps/compatdata/
```
The most recently modified numbered folder is the game's AppID.

### 2.2 Identify the Proton Version and Wine Path
The Proton version used by the game can be found in Steam → Game Properties → Compatibility. This example uses **Proton 9.0 (Beta)**, whose `wine` binary is located at:
```
~/.steam/steam/steamapps/common/Proton 9.0 (Beta)/files/bin/wine
```
If your path differs, adjust accordingly.

### 2.3 Locate the Game Executable (Windows Internal Path)
The game executable is typically named `Chill With You.exe` inside your Steam library.  
Run in a terminal:
```bash
find ~/.steam/steam/steamapps/common/ -name "Chill With You.exe"
```
Example output:
```
/home/ethan/.steam/steam/steamapps/common/Chill with You Lo-Fi Story/Chill With You.exe
```
Wine maps the Linux root directory as `Z:\`, so the corresponding Wine path is:
```
Z:\home\ethan\.steam\steam\steamapps\common\Chill with You Lo-Fi Story\Chill With You.exe
```
(Use backslashes `\` and wrap in double quotes to handle spaces.)

### 2.4 Required Environment Variables
- `WINEPREFIX`: Points to the game's Proton container  
  `~/.steam/steam/steamapps/compatdata/3548580/pfx`
- `WINEFSYNC`: Must be set to `1` to match the game's sync mode, otherwise injection will fail.
- `WINE`: The Proton wine path (see above).

Set these before running any of the commands below:
```bash
export WINEPREFIX="$HOME/.steam/steam/steamapps/compatdata/3548580/pfx"
export WINEFSYNC=1
WINE="$HOME/.steam/steam/steamapps/common/Proton 9.0 (Beta)/files/bin/wine"
```

---

## 3. Method A: Manual Injection (Quick & Dirty, ~1 min)

Use this when you only need to log in once or don't want to bother with automation.

### Step 1: Launch the Game and Go to the Login Screen
Start the game normally through Steam until you see the "Sign in with Apple ID" screen; keep the game running.

### Step 2: Complete Browser Authentication and Copy the Callback URL
Click the in-game login button; your system browser will open the Apple ID login page.  
Sign in and authorize; the browser will try to navigate to a URL like `chill.oauth://oauth2/apple?code=...&state=...`.  
**The page may show "Cannot connect" or a blank page — that's normal.**  
**Select and copy** the entire URL from the address bar (starting with `chill.oauth:`).

### Step 3: Inject into the Game
Open a terminal, **paste the copied URL** into the command below (replace `YOUR_URL`):
```bash
export WINEPREFIX="$HOME/.steam/steam/steamapps/compatdata/3548580/pfx"
export WINEFSYNC=1
WINE="$HOME/.steam/steam/steamapps/common/Proton 9.0 (Beta)/files/bin/wine"

"$WINE" "Z:\home\ethan\.steam\steam\steamapps\common\Chill with You Lo-Fi Story\Chill With You.exe" "paste-the-full-URL-here"
```
Press Enter and the game will immediately receive the login info and complete the flow. **Done!**

---

## 4. Method B: Fully Automatic Solution (Recommended, Set Once & Forget)

Create a Python script as the default handler for the `chill.oauth` protocol, so the browser automatically triggers injection on every redirect — no manual copying needed.

### 4.1 Create a Desktop Entry
```bash
[Desktop Entry]
Type=Application
Name=Chill OAuth Handler
Exec=/home/ethan/.local/bin/chill_oauth_handler.sh %u
MimeType=x-scheme-handler/chill.oauth;
NoDisplay=true
```

### 4.2 Create the OAuth Callback Script
```bash
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
```

### 4.3 Create a One-Click Install Script
```bash
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

echo "Installation complete."
echo "  - Script: $BIN_DIR/chill_oauth_handler.sh"
echo "  - Desktop entry: $APP_DIR/chill-oauth-handler.desktop"
```

---

## 5. FAQ & Troubleshooting

### Q1: Injection command fails with `Server is running with WINEFSYNC but this process is not`
**A:** The `WINEFSYNC=1` environment variable is not set. Make sure `export WINEFSYNC=1` is included in your command, or that `env["WINEFSYNC"]="1"` is set in your Python script.

### Q2: Game does not react after injection
- Check that the URL was copied fully (must start with `chill.oauth:` and include all parameters).
- Verify the game executable path is correct (use backslashes `\` inside Wine paths; paths are case-sensitive).
- Try killing all Wine processes and retry: `wineserver -k`, then restart the game and inject again.

### Q3: Browser redirect does not trigger the script automatically
- Check the MIME association:  
  ```bash
  xdg-mime query default x-scheme-handler/chill.oauth
  ```
  Should return `chill-oauth-handler.desktop`. If not, redo the registration steps.
- Some browsers (e.g., Flatpak Firefox) have sandbox restrictions and cannot invoke system protocol handlers. Use the system repository version of your browser, or allow external protocol handlers in your browser settings.

### Q4: `wineserver` conflict when doing manual injection while the game is running
- Ensure `WINEFSYNC=1` is set.
- Do not run multiple programs with different Wine prefixes simultaneously.

### Q5: How to revert to the manual method
- Delete or rename `~/.local/share/applications/chill-oauth-handler.desktop` and re-run `update-desktop-database` to remove the protocol association.

---

## 6. Summary

You now have two ways to complete Apple ID login:

- **Manual injection**: Great for occasional use — quick and reliable.
- **Fully automatic script**: Configure once and enjoy hassle-free logins forever, just like clicking "Sign In" on native Windows.

Both methods **avoid the instability of installing an embedded browser inside Proton** and instead leverage the game's own ability to receive callback URLs — clean and efficient.

If you change your Proton version or game installation path, update the paths and AppID in the scripts accordingly. If you run into other issues, refer to this guide for troubleshooting. Happy gaming!
