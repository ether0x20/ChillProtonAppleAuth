# Chill with You: Lo-Fi Story 苹果 ID 登录完整教程（Linux + Proton）

本教程将指导你在 Linux Mint 22.3（同样适用于其他 Linux 发行版）中，通过 Steam Proton 运行《Chill with You: Lo-Fi Story》时，顺利完成 Apple ID 绑定，并实现 **浏览器回调自动注入**，告别每次手动复制链接的麻烦。

---

## 一、问题背景

- 游戏依赖 Apple ID OAuth 登录，会调用浏览器打开苹果认证页面。
- 登录成功后，浏览器会尝试打开 `chill.oauth://...` 链接，将授权信息传回游戏。
- Proton 环境无法自动处理这类自定义 URL 协议，导致游戏永远收不到回调，登录卡死。
- 本教程将教会你两个方法：
  - **方法A（手动）**：一次性复制 URL，用命令注入游戏，快速登录。
  - **方法B（自动化·推荐）**：编写脚本 + 系统协议注册，以后每次登录全自动，丝般顺滑。

---

## 二、准备工作（一次设定）

### 1. 确认 AppID
在 Steam 库中右键游戏 → 属性 → 更新，找到 AppID（本文以 `3548580` 为例）。  
或查看目录名：
```bash
ls ~/.steam/steam/steamapps/compatdata/
```
最近修改的数字文件夹即为游戏的 AppID。

### 2. 确认 Proton 版本与 wine 路径
游戏所用 Proton 版本可在 Steam 游戏属性 → 兼容性中查看。本例为 **Proton 9.0 (Beta)**，其 `wine` 可执行文件位于：
```
~/.steam/steam/steamapps/common/Proton 9.0 (Beta)/files/bin/wine
```
如果路径不同，请相应替换。

### 3. 找到游戏主程序（Windows 内部路径）
游戏主程序通常位于 Steam 库中，文件名为 `Chill With You.exe`。  
在终端查看：
```bash
find ~/.steam/steam/steamapps/common/ -name "Chill With You.exe"
```
输出示例：
```
/home/ethan/.steam/steam/steamapps/common/Chill with You Lo-Fi Story/Chill With You.exe
```
Wine 内部使用 `Z:\` 映射 Linux 根目录，因此对应的 Wine 路径为：
```
Z:\home\ethan\.steam\steam\steamapps\common\Chill with You Lo-Fi Story\Chill With You.exe
```
（注意使用反斜杠 `\`，并用双引号包裹以防空格）

### 4. 必须设置的环境变量
- `WINEPREFIX`：指向游戏的 Proton 容器  
  `~/.steam/steam/steamapps/compatdata/3548580/pfx`
- `WINEFSYNC`：必须设为 `1`，与游戏运行的同步模式匹配，否则注入时会报错。
- `WINE`：Proton 的 wine 路径（见上）。

在后续所有命令中，请先设置：
```bash
export WINEPREFIX="$HOME/.steam/steam/steamapps/compatdata/3548580/pfx"
export WINEFSYNC=1
WINE="$HOME/.steam/steam/steamapps/common/Proton 9.0 (Beta)/files/bin/wine"
```

---

## 三、方法A：手动注入（应急使用，1 分钟完成）

适用场景：只需临时登录一次，或不想折腾自动化。

### 步骤 1：启动游戏并进入登录界面
通过 Steam 正常启动游戏，直到出现“使用 Apple ID 登录”的界面，保持游戏运行。

### 步骤 2：完成浏览器认证，复制回调 URL
点击游戏内登录按钮，系统浏览器会跳转到 Apple ID 登录页。  
正常登录并授权后，浏览器会试图跳转到一个类似 `chill.oauth://oauth2/apple?code=...&state=...` 的地址。  
**此时页面可能显示“无法连接”或空白，这很正常。**  
在浏览器地址栏中**全选并复制**整个 URL（以 `chill.oauth:` 开头）。

### 步骤 3：注入到游戏
打开终端，**粘贴你复制的 URL** 到下面的命令中（替换 `YOUR_URL`）：
```bash
export WINEPREFIX="$HOME/.steam/steam/steamapps/compatdata/3548580/pfx"
export WINEFSYNC=1
WINE="$HOME/.steam/steam/steamapps/common/Proton 9.0 (Beta)/files/bin/wine"

"$WINE" "Z:\home\ethan\.steam\steam\steamapps\common\Chill with You Lo-Fi Story\Chill With You.exe" "这里粘贴你复制的完整URL"
```
按回车后，游戏会立刻收到登录信息并跳转完成。**搞定！**

---

## 四、方法B：全自动方案（推荐，一劳永逸）

编写一个 Python 脚本作为 `chill.oauth` 协议的默认处理程序，浏览器跳转时自动触发注入，无需手动复制。

### 4.1 创建desktop入口
```bash
[Desktop Entry]
Type=Application
Name=Chill OAuth Handler
Exec=/home/ethan/.local/bin/chill_oauth_handler.sh %u
MimeType=x-scheme-handler/chill.oauth;
NoDisplay=true
```
### 4.2 创建URL回调脚本
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
### 4.3 创建一键安装脚本
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

echo "安装完成。"
echo "  - 脚本: $BIN_DIR/chill_oauth_handler.sh"
echo "  - 桌面入口: $APP_DIR/chill-oauth-handler.desktop"
```

## 五、常见问题与排查

### Q1: 执行注入命令时报错 `Server is running with WINEFSYNC but this process is not`
**A:** 未设置 `WINEFSYNC=1` 环境变量。请确认命令中已包含 `export WINEFSYNC=1`，或在 Python 脚本中已设置 `env["WINEFSYNC"]="1"`。

### Q2: 注入后游戏没反应
- 检查 URL 是否完整复制（必须包含 `chill.oauth:` 开头以及所有参数）。
- 确认游戏主程序路径完全正确（Wine 内部用反斜杠 `\`，且大小写敏感）。
- 尝试关闭所有 Wine 进程后重试：`wineserver -k`，然后重新启动游戏并注入。

### Q3: 浏览器跳转后没有自动调用脚本
- 检查 MIME 关联：  
  ```bash
  xdg-mime query default x-scheme-handler/chill.oauth
  ```
  应返回 `chill-oauth-handler.desktop`。若不正确，重新执行注册步骤。
- 某些浏览器（如 Flatpak 版 Firefox）有沙盒限制，无法调用系统协议。请使用系统仓库版浏览器，或在浏览器设置中允许外部协议。

### Q4: 游戏启动后，手动注入时出现 `wineserver` 冲突
- 确保 `WINEFSYNC=1` 已设置。
- 不要同时运行多个不同 Wine 前缀的程序。

### Q5: 想恢复为手动方式
- 删除或重命名 `~/.local/share/applications/chill-oauth-handler.desktop`，并重新运行 `update-desktop-database` 即可解除协议关联。

---

## 六、总结

你现在有两种方式完成 Apple ID 登录：
- **手动注入**：适合偶尔使用，快速可靠。
- **全自动脚本**：一次配置，终身受益，体验如同原生 Windows 一样点击即玩。

两种方案都**绕开了在 Proton 中安装内嵌浏览器的不稳定性**，直接利用游戏主程序接收回调 URL 的原理，干净高效。

如果你更换了 Proton 版本或游戏安装位置，请相应修改脚本中的路径和 AppID。若遇其他问题，欢迎参考本文排查解决。祝你游戏愉快！
