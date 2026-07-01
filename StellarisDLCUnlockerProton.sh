#!/bin/bash
set -uo pipefail

APPID="281990"
APP_DIR="$HOME/.local/share/StellarisDLCUnlocker"
CACHE_DIR="$APP_DIR/cache"
LOG_FILE="$APP_DIR/unlocker.log"
CONFIG_FILE="$APP_DIR/config.ini"

REPO_GITHUB_RAW="https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main"
REPO_JSDELIVR="https://cdn.jsdelivr.net/gh/seuyh/stellaris-dlc-unlocker@main"

GITHUB_DLC_URL="$REPO_GITHUB_RAW/dlc_data.json"
JSDELIVR_DLC_URL="$REPO_JSDELIVR/dlc_data.json"
GITHUB_HASHES_URL="$REPO_GITHUB_RAW/hashes.json"
JSDELIVR_HASHES_URL="$REPO_JSDELIVR/hashes.json"
SERVER_URL="yblocker.xyz"
STEAMCMD_API="https://api.steamcmd.net/v1/info"

STEAM_FILES=(Emulator64.dll LinkNeverDie_Com_64.dll SWLoader.txt SWconfig.ini cream_api.ini steam_api64_org_game.dll steam_api64_org_launcher.dll)
LAUNCHER_FILES=(cream_api.ini sdkencryptedappticket64.dll steam_api64.dll steam_api64_o.dll)
ALT_LAUNCHERS=("launcher-installer-windows_2024.14.msi" "launcher-installer-windows_2024.13.msi" "launcher-installer-windows_2024.8.msi")
CREAMLINUX_PROTON_SUBDIR="creamlinux-proton"
CREAMLINUX_PROTON_FILES=(creamlinux.json steam_api64.dll)

mkdir -p "$APP_DIR" "$CACHE_DIR"

C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'
C_RED=$'\e[31m'; C_GREEN=$'\e[32m'; C_YELLOW=$'\e[33m'
C_BLUE=$'\e[34m'; C_MAGENTA=$'\e[35m'; C_CYAN=$'\e[36m'; C_WHITE=$'\e[97m'

LANGUAGE="en"

t() {
    local key="$1"
    case "$LANGUAGE" in
        ru) _t_ru "$key" ;;
        zh) _t_zh "$key" ;;
        *)  _t_en "$key" ;;
    esac
}

_t_en() {
    case "$1" in
        title) echo "Stellaris DLC Unlocker (Proton)" ;;
        menu_header) echo "MAIN MENU" ;;
        m_status) echo "Status" ;;
        m_install) echo "Install / Update" ;;
        fetching_dlc_info) echo "Fetching DLC info:" ;;
        fetching_file) echo "  -> In progress:" ;;
        m_lang) echo "Language" ;;
        m_log) echo "Log" ;;
        m_exit) echo "Exit" ;;
        choose) echo "> " ;;
        steam_found) echo "Steam:" ;;
        steam_not_found) echo "Steam not found." ;;
        game_found) echo "Stellaris:" ;;
        game_not_found) echo "Stellaris not found." ;;
        proton_build) echo "Windows executable found (Proton/Wine)." ;;
        not_proton) echo "Not a Windows build. Use the Native Linux unlocker instead." ;;
        downloading) echo "Downloading" ;;
        fetching_dlc_list) echo "Fetching DLC list..." ;;
        dlc_list_ok) echo "DLC list loaded." ;;
        dlc_list_fail) echo "Failed to fetch DLC list." ;;
        fetching_creamapi) echo "Downloading CreamAPI files..." ;;
        creamapi_ok) echo "CreamAPI files ready." ;;
        patching_launcher) echo "Patching Paradox Launcher..." ;;
        copying_files) echo "Copying files to game folder..." ;;
        to_download) echo "DLC to download:" ;;
        unpacking) echo "Unpacking archives..." ;;
        updating_ini) echo "Updating cream_api.ini..." ;;
        ini_updated) echo "cream_api.ini: added" ;;
        ini_skip) echo "SteamCMD unavailable, skipped." ;;
        install_done) echo "Done! Launch Stellaris via Steam." ;;
        press_enter) echo "Press Enter to continue..." ;;
        enter_game_path) echo "Game path (or Enter to cancel): " ;;
        invalid_game_path) echo "Path does not exist." ;;
        enter_steam_path) echo "Steam not auto-detected. Enter Steam folder path (or Enter to cancel): " ;;
        invalid_steam_path) echo "Not a valid Steam folder (no 'steamapps' inside)." ;;
        enter_prefix_path) echo "Proton prefix not found. Enter path to 'pfx' folder (e.g. .../compatdata/281990/pfx) or Enter to cancel: " ;;
        invalid_prefix_path) echo "Invalid prefix path (no 'drive_c' found inside)." ;;
        invalid_choice) echo "Invalid choice." ;;
        log_empty) echo "Log is empty." ;;
        confirm_install) echo "Proceed? [Y/n]: " ;;
        cancelled) echo "Cancelled." ;;
        no_dlc_to_download) echo "All DLC up to date." ;;
        hashes_skip) echo "Could not fetch hashes.json, skipping integrity check." ;;
        dlc_outdated) echo "Outdated content, will re-download:" ;;
        flatpak_steam) echo "(Flatpak)" ;;
        opt_reinstall) echo "Reinstall Paradox Launcher? [Y/n]: " ;;
        opt_ver) echo "Select launcher version (0=Default, 1=2024.14, 2=2024.13, 3=2024.8): " ;;
        opt_noupdate) echo "Disable launcher auto-update (recommended)? [Y/n]: " ;;
        opt_full) echo "Full reinstall (deletes saves and settings)? [y/N] (Default: No): " ;;
        launcher_default) echo "Default (From game folder)" ;;
        *) echo "$1" ;;
    esac
}

_t_ru() {
    case "$1" in
        title) echo "Stellaris DLC Unlocker (Proton)" ;;
        menu_header) echo "ГЛАВНОЕ МЕНЮ" ;;
        m_status) echo "Статус" ;;
        m_install) echo "Установить / обновить" ;;
        fetching_dlc_info) echo "Запрос данных DLC:" ;;
        fetching_file) echo "  -> В процессе:" ;;
        m_lang) echo "Язык" ;;
        m_log) echo "Лог" ;;
        m_exit) echo "Выход" ;;
        choose) echo "> " ;;
        steam_found) echo "Steam:" ;;
        steam_not_found) echo "Steam не найден." ;;
        game_found) echo "Stellaris:" ;;
        game_not_found) echo "Stellaris не найден." ;;
        proton_build) echo "Найден Windows-исполняемый файл (Proton)." ;;
        not_proton) echo "Не Windows-версия. Используйте нативный Linux-анлокер." ;;
        downloading) echo "Скачивание" ;;
        fetching_dlc_list) echo "Получение списка DLC..." ;;
        dlc_list_ok) echo "Список DLC загружен." ;;
        dlc_list_fail) echo "Не удалось получить список DLC." ;;
        fetching_creamapi) echo "Скачивание файлов CreamAPI..." ;;
        creamapi_ok) echo "Файлы CreamAPI готовы." ;;
        patching_launcher) echo "Патчинг Paradox Launcher..." ;;
        copying_files) echo "Копирование файлов в папку игры..." ;;
        to_download) echo "DLC к скачиванию:" ;;
        unpacking) echo "Распаковка архивов..." ;;
        updating_ini) echo "Обновление cream_api.ini..." ;;
        ini_updated) echo "cream_api.ini: добавлено" ;;
        ini_skip) echo "SteamCMD недоступен, пропущено." ;;
        install_done) echo "Готово! Запускайте Stellaris через Steam." ;;
        press_enter) echo "Нажмите Enter для продолжения..." ;;
        enter_game_path) echo "Путь к игре (или Enter, чтобы отменить): " ;;
        invalid_game_path) echo "Такого пути не существует." ;;
        enter_steam_path) echo "Steam не найден автоматически. Введите путь к папке (или Enter, чтобы отменить): " ;;
        invalid_steam_path) echo "Это не папка Steam (внутри нет 'steamapps')." ;;
        enter_prefix_path) echo "Префикс Proton не найден. Введите путь к папке 'pfx' (например .../compatdata/281990/pfx) или Enter для отмены: " ;;
        invalid_prefix_path) echo "Неверный путь к префиксу (внутри нет 'drive_c')." ;;
        invalid_choice) echo "Неверный выбор." ;;
        log_empty) echo "Лог пуст." ;;
        confirm_install) echo "Продолжить? [Y/n]: " ;;
        cancelled) echo "Отменено." ;;
        no_dlc_to_download) echo "Все DLC актуальны." ;;
        hashes_skip) echo "Не удалось получить hashes.json, проверка целостности пропущена." ;;
        dlc_outdated) echo "Контент устарел, будет перекачан:" ;;
        flatpak_steam) echo "(Flatpak)" ;;
        opt_reinstall) echo "Переустановить Paradox Launcher? [Y/n]: " ;;
        opt_ver) echo "Выберите версию лаунчера (0=По умолчанию, 1=2024.14, 2=2024.13, 3=2024.8): " ;;
        opt_noupdate) echo "Отключить авто-обновление лаунчера (рекомендуется)? [Y/n]: " ;;
        opt_full) echo "Полная очистка DLC и сохранений? [y/N] (По умолчанию: Нет): " ;;
        launcher_default) echo "По умолчанию (Из папки с игрой)" ;;
        *) echo "$1" ;;
    esac
}

_t_zh() {
    case "$1" in
        title) echo "Stellaris DLC Unlocker (Proton)" ;;
        menu_header) echo "主菜单" ;;
        m_status) echo "状态" ;;
        m_install) echo "安装 / 更新" ;;
        fetching_dlc_info) echo "正在获取 DLC 信息:" ;;
        fetching_file) echo "  -> 正在处理:" ;;
        m_lang) echo "语言" ;;
        m_log) echo "日志" ;;
        m_exit) echo "退出" ;;
        choose) echo "> " ;;
        steam_found) echo "Steam:" ;;
        steam_not_found) echo "未找到 Steam。" ;;
        game_found) echo "Stellaris:" ;;
        game_not_found) echo "未找到 Stellaris。" ;;
        proton_build) echo "检测到 Windows 执行文件 (Proton)。" ;;
        not_proton) echo "非 Windows 版本。请使用原生 Linux 解锁器。" ;;
        downloading) echo "下载中" ;;
        fetching_dlc_list) echo "正在获取 DLC 列表..." ;;
        dlc_list_ok) echo "DLC 列表已加载。" ;;
        dlc_list_fail) echo "获取 DLC 列表失败。" ;;
        fetching_creamapi) echo "正在下载 CreamAPI 文件..." ;;
        creamapi_ok) echo "CreamAPI 文件已就绪。" ;;
        patching_launcher) echo "正在修补 Paradox Launcher..." ;;
        copying_files) echo "正在复制文件到游戏目录..." ;;
        to_download) echo "待下载 DLC:" ;;
        unpacking) echo "正在解压..." ;;
        updating_ini) echo "正在更新 cream_api.ini..." ;;
        ini_updated) echo "cream_api.ini: 已添加" ;;
        ini_skip) echo "SteamCMD 不可用，已跳过。" ;;
        install_done) echo "完成！请通过 Steam 启动 Stellaris。" ;;
        press_enter) echo "按 Enter 继续..." ;;
        enter_game_path) echo "游戏路径（直接 Enter 取消）: " ;;
        invalid_game_path) echo "路径不存在。" ;;
        enter_steam_path) echo "未自动检测到 Steam。请输入 Steam 文件夹路径（直接 Enter 取消）: " ;;
        invalid_steam_path) echo "不是有效的 Steam 文件夹（内部没有 'steamapps'）。" ;;
        enter_prefix_path) echo "未找到 Proton 前缀。请输入 'pfx' 文件夹路径 (例如 .../compatdata/281990/pfx) 或直接 Enter 取消: " ;;
        invalid_prefix_path) echo "无效的前缀路径 (未找到 'drive_c')。" ;;
        invalid_choice) echo "无效选择。" ;;
        log_empty) echo "日志为空。" ;;
        confirm_install) echo "继续？[Y/n]: " ;;
        cancelled) echo "已取消。" ;;
        no_dlc_to_download) echo "所有 DLC 均为最新。" ;;
        hashes_skip) echo "无法获取 hashes.json，跳过完整性检查。" ;;
        dlc_outdated) echo "内容已过期，将重新下载:" ;;
        flatpak_steam) echo "(Flatpak)" ;;
        opt_reinstall) echo "重装 Paradox Launcher？[Y/n]: " ;;
        opt_ver) echo "选择启动器版本 (0=默认, 1=2024.14, 2=2024.13, 3=2024.8): " ;;
        opt_noupdate) echo "禁用启动器自动更新（推荐）？[Y/n]: " ;;
        opt_full) echo "完整重装（将删除存档和设置）？[y/N] (默认: 否): " ;;
        launcher_default) echo "默认 (来自游戏目录)" ;;
        *) echo "$1" ;;
    esac
}

log() {
    local level="$1"; shift
    local msg="$*"
    local color="$C_WHITE"
    case "$level" in
        OK)   color="$C_GREEN" ;;
        WARN) color="$C_YELLOW" ;;
        ERROR) color="$C_RED" ;;
        INFO) color="$C_CYAN" ;;
    esac
    echo -e "${color}[$level]${C_RESET} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $msg" >> "$LOG_FILE"
}

hr() { printf "${C_DIM}%s${C_RESET}\n" "------------------------------------------------------------"; }

header() {
    clear
    echo -e "${C_BOLD}${C_MAGENTA}=============================================================${C_RESET}"
    echo -e "${C_BOLD}${C_WHITE}  $(t title)${C_RESET}"
    echo -e "${C_BOLD}${C_MAGENTA}=============================================================${C_RESET}"
    echo
}

pause() {
    echo
    ask "$(t press_enter)" _dummy
}

download_file() {
    local url="$1" dest="$2" label="${3:-$1}"
    mkdir -p "$(dirname "$dest")"
    echo -e "${C_CYAN}$(t downloading):${C_RESET} $label"
    if ! curl -L --fail --retry 3 --connect-timeout 15 -o "$dest" \
        --progress-bar "$url"; then
        log ERROR "Failed to download: $url"
        return 1
    fi
    return 0
}

http_get() {
    curl -sL --fail --retry 1 --connect-timeout 5 --max-time 10 -A "StellarisDLCUnlocker-sh/1.0" "$1"
}

http_get_fast() {
    curl -sL --fail --connect-timeout 3 --max-time 3 -A "StellarisDLCUnlocker-sh/1.0" "$1"
}

download_with_fallback() {
    local rel="$1" dest="$2" label="${3:-$1}"
    mkdir -p "$(dirname "$dest")"
    echo -e "${C_DIM}$(t fetching_file) ${C_WHITE}$label${C_RESET}"
    if curl -fsSL --retry 2 --connect-timeout 10 -o "$dest" "$REPO_GITHUB_RAW/$rel" 2>>"$LOG_FILE"; then
        log OK "  (GitHub) $label"
        return 0
    fi
    log WARN "  GitHub failed for $label, trying jsDelivr..."
    if curl -fsSL --retry 2 --connect-timeout 10 -o "$dest" "$REPO_JSDELIVR/$rel" 2>>"$LOG_FILE"; then
        log OK "  (jsDelivr) $label"
        return 0
    fi
    log ERROR "  Failed to fetch $label from GitHub and jsDelivr."
    return 1
}

get_github_dir_shas() {
    local subdir="$1"
    local api_url="https://api.github.com/repos/seuyh/stellaris-dlc-unlocker/contents/$subdir"
    http_get "$api_url" 2>/dev/null || true
}

get_manifest_shas() {
    local subdir="$1"
    local manifest
    manifest=$(http_get "$REPO_GITHUB_RAW/$subdir/manifest.json" 2>/dev/null) || true
    if [ -z "$manifest" ]; then
        manifest=$(http_get "$REPO_JSDELIVR/$subdir/manifest.json" 2>/dev/null) || true
    fi
    echo "$manifest"
}

get_remote_sha() {
    local filename="$1" api_json="$2" manifest_json="$3"
    local sha=""
    if command -v jq >/dev/null 2>&1; then
        [ -n "$api_json" ] && sha=$(echo "$api_json" | jq -r --arg f "$filename" '.[] | select(.name==$f) | .sha // empty' 2>/dev/null)
        if [ -z "$sha" ] && [ -n "$manifest_json" ]; then
            sha=$(echo "$manifest_json" | jq -r --arg f "$filename" '.[$f] // empty' 2>/dev/null)
        fi
    else
        if [ -n "$api_json" ]; then
            sha=$(echo "$api_json" | grep -A5 "\"name\": \"$filename\"" | grep -oP '"sha":\s*"\K[a-f0-9]+' | head -1)
        fi
        if [ -z "$sha" ] && [ -n "$manifest_json" ]; then
            sha=$(echo "$manifest_json" | grep -oP "\"$filename\":\\s*\"\\K[a-f0-9]+" | head -1)
        fi
    fi
    echo "$sha"
}

download_with_cache() {
    local rel="$1" dest="$2" label="${3:-$1}" remote_sha="${4:-}"
    local sha_file="${dest}.sha"
    if [ -n "$remote_sha" ] && [ -f "$dest" ] && [ -f "$sha_file" ]; then
        local cached_sha
        cached_sha=$(cat "$sha_file")
        if [ "$cached_sha" = "$remote_sha" ]; then
            log OK "  (cached) $label"
            return 0
        fi
    fi
    download_with_fallback "$rel" "$dest" "$label" || return 1
    [ -n "$remote_sha" ] && echo "$remote_sha" > "$sha_file"
    return 0
}

ask() {
    local prompt="$1" __var="$2" __val=""
    if [ -r /dev/tty ]; then
        read -rp "$prompt" __val </dev/tty
    else
        read -rp "$prompt" __val
    fi
    printf -v "$__var" '%s' "$__val"
}

STEAM_DIR=""
GAME_DIR=""
PREFIX_DIR=""
IS_FLATPAK_STEAM=0
PROTON_WINE=""

find_steam_dir() {
    local candidates=(
        "$HOME/.steam/steam"
        "$HOME/.local/share/Steam"
        "$HOME/.var/app/com.valvesoftware.Steam/data/Steam"
        "$HOME/snap/steam/common/.local/share/Steam"
    )
    for c in "${candidates[@]}"; do
        if [ -d "$c/steamapps" ]; then
            STEAM_DIR="$c"
            [[ "$c" == *".var/app/com.valvesoftware.Steam"* ]] && IS_FLATPAK_STEAM=1
            [[ "$c" == *"snap/steam"* ]] && IS_FLATPAK_STEAM=1
            return 0
        fi
    done
    return 1
}

find_game_dir() {
    [ -z "$STEAM_DIR" ] && return 1
    local lib_vdf="$STEAM_DIR/steamapps/libraryfolders.vdf"
    local libs=("$STEAM_DIR")

    if [ -f "$lib_vdf" ]; then
        while IFS= read -r p; do
            [ -n "$p" ] && libs+=("$p")
        done < <(grep -oP '"path"\s*"\K[^"]+' "$lib_vdf" 2>/dev/null)
    fi

    for lib in "${libs[@]}"; do
        local candidate="$lib/steamapps/common/Stellaris"
        if [ -d "$candidate" ]; then
            GAME_DIR="$candidate"
            return 0
        fi
    done
    return 1
}

find_prefix_dir() {
    [ -z "$GAME_DIR" ] && return 1

    local lib_dir
    lib_dir="$(dirname "$(dirname "$(dirname "$GAME_DIR")")")"
    local candidate1="$lib_dir/steamapps/compatdata/$APPID/pfx"
    local candidate2="$STEAM_DIR/steamapps/compatdata/$APPID/pfx"

    if [ -d "$candidate1/drive_c" ]; then
        PREFIX_DIR="$candidate1"
        return 0
    elif [ -d "$candidate2/drive_c" ]; then
        PREFIX_DIR="$candidate2"
        return 0
    fi
    return 1
}

is_proton_build() {
    [ -f "$GAME_DIR/stellaris.exe" ]
}

resolve_steam_dir() {
    [ -n "$STEAM_DIR" ] && return 0
    find_steam_dir && return 0
    while true; do
        ask "$(t enter_steam_path)" manual
        [ -z "$manual" ] && return 1
        manual="${manual%/}"
        if [ -d "$manual/steamapps" ]; then
            STEAM_DIR="$manual"
            [[ "$manual" == *".var/app/com.valvesoftware.Steam"* || "$manual" == *"flatpak"* || "$manual" == *"snap/steam"* ]] && IS_FLATPAK_STEAM=1
            return 0
        fi
        log ERROR "$(t invalid_steam_path)"
    done
}

resolve_game_dir() {
    [ -n "$GAME_DIR" ] && return 0
    find_game_dir && return 0
    while true; do
        ask "$(t enter_game_path)" manual
        [ -z "$manual" ] && return 1
        manual="${manual%/}"
        if [ -d "$manual" ]; then
            GAME_DIR="$manual"
            return 0
        fi
        log ERROR "$(t invalid_game_path)"
    done
}

resolve_prefix_dir() {
    [ -n "$PREFIX_DIR" ] && return 0
    find_prefix_dir && return 0
    while true; do
        ask "$(t enter_prefix_path)" manual
        [ -z "$manual" ] && return 1
        manual="${manual%/}"
        if [ -d "$manual/drive_c" ]; then
            PREFIX_DIR="$manual"
            return 0
        fi
        log ERROR "$(t invalid_prefix_path)"
    done
}

get_launcher_bases() {
    if [ -n "$PREFIX_DIR" ]; then
        local pointer_file="$PREFIX_DIR/drive_c/users/steamuser/AppData/Local/Paradox Interactive/launcherpath"
        if [ -f "$pointer_file" ]; then
            local win_path
            win_path=$(cat "$pointer_file" | tr -d '\r\n')
            local lin_path="${win_path//\\//}"
            lin_path="${lin_path/[Cc]:/$PREFIX_DIR/drive_c}"

            if [ -d "$lin_path" ]; then
                echo "$lin_path"
            fi
        fi

        echo "$PREFIX_DIR/drive_c/users/steamuser/AppData/Local/Programs/Paradox Interactive/launcher"
        echo "$PREFIX_DIR/drive_c/Program Files/Paradox Interactive/launcher"
        echo "$PREFIX_DIR/drive_c/Program Files (x86)/Paradox Interactive/launcher"
    fi
}

run_wine() {
    export WINEPREFIX="$PREFIX_DIR"
    export WINEDEBUG=-all

    if [ -z "$PROTON_WINE" ]; then
        local p_paths=()
        while IFS= read -r line; do p_paths+=("$line"); done < <(ls -d "$STEAM_DIR/steamapps/common/Proton "* 2>/dev/null | sort -rV)
        for p in "${p_paths[@]}"; do
            if [ -x "$p/files/bin/wine" ]; then
                PROTON_WINE="$p/files/bin/wine"
                break
            fi
        done
    fi

    if [ -n "$PROTON_WINE" ] && [ -x "$PROTON_WINE" ]; then
        "$PROTON_WINE" "$@"
    elif command -v wine >/dev/null 2>&1; then
        wine "$@"
    else
        log ERROR "Proton wine binary not found. Try running the game once via Steam."
        return 1
    fi
}

DLC_DATA_JSON=""

fetch_dlc_data() {
    log INFO "$(t fetching_dlc_list)"
    DLC_DATA_JSON=$(http_get "$GITHUB_DLC_URL" 2>/dev/null) || true
    if [ -z "$DLC_DATA_JSON" ]; then
        log WARN "GitHub failed, trying jsDelivr..."
        DLC_DATA_JSON=$(http_get "$JSDELIVR_DLC_URL" 2>/dev/null) || true
    fi
    if [ -z "$DLC_DATA_JSON" ]; then
        log ERROR "$(t dlc_list_fail)"
        return 1
    fi
    log OK "$(t dlc_list_ok)"
    return 0
}

dlc_folders() {
    if command -v jq >/dev/null 2>&1; then
        echo "$DLC_DATA_JSON" | jq -r '.[].dlc_folder // empty'
    else
        echo "$DLC_DATA_JSON" | grep -oP '"dlc_folder"\s*:\s*"\K[^"]+'
    fi
}

fetch_creamapi() {
    mkdir -p "$CACHE_DIR/creamapi_steam_files" "$CACHE_DIR/creamapi_launcher_files" "$CACHE_DIR/$CREAMLINUX_PROTON_SUBDIR"
    log INFO "$(t fetching_creamapi)"

    local api_steam manifest_steam api_launcher manifest_launcher api_proton manifest_proton
    api_steam=$(get_github_dir_shas "creamapi_steam_files")
    manifest_steam=$(get_manifest_shas "creamapi_steam_files")
    api_launcher=$(get_github_dir_shas "creamapi_launcher_files")
    manifest_launcher=$(get_manifest_shas "creamapi_launcher_files")
    api_proton=$(get_github_dir_shas "$CREAMLINUX_PROTON_SUBDIR")
    manifest_proton=$(get_manifest_shas "$CREAMLINUX_PROTON_SUBDIR")

    local ok=1
    for f in "${STEAM_FILES[@]}"; do
        local sha; sha=$(get_remote_sha "$f" "$api_steam" "$manifest_steam")
        download_with_cache "creamapi_steam_files/$f" "$CACHE_DIR/creamapi_steam_files/$f" "$f" "$sha" || ok=0
    done
    for f in "${LAUNCHER_FILES[@]}"; do
        local sha; sha=$(get_remote_sha "$f" "$api_launcher" "$manifest_launcher")
        download_with_cache "creamapi_launcher_files/$f" "$CACHE_DIR/creamapi_launcher_files/$f" "$f" "$sha" || ok=0
    done
    for f in "${CREAMLINUX_PROTON_FILES[@]}"; do
        local sha; sha=$(get_remote_sha "$f" "$api_proton" "$manifest_proton")
        download_with_cache "$CREAMLINUX_PROTON_SUBDIR/$f" "$CACHE_DIR/$CREAMLINUX_PROTON_SUBDIR/$f" "$f" "$sha" || ok=0
    done

    if [ "$ok" -eq 1 ]; then
        log OK "$(t creamapi_ok)"
        return 0
    fi
    return 1
}

update_cream_ini() {
    log INFO "$(t updating_ini)"
    local info
    info=$(http_get "$STEAMCMD_API/$APPID" 2>/dev/null) || true
    if [ -z "$info" ]; then
        log WARN "$(t ini_skip)"
        return 0
    fi

    local csv
    if command -v jq >/dev/null 2>&1; then
        csv=$(echo "$info" | jq -r ".data[\"$APPID\"].extended.listofdlc // empty")
    else
        csv=$(echo "$info" | grep -oP '"listofdlc"\s*:\s*"\K[^"]+')
    fi
    if [ -z "$csv" ]; then
        log WARN "$(t ini_skip)"
        return 0
    fi

    for ini_path in "$CACHE_DIR/creamapi_steam_files/cream_api.ini" "$CACHE_DIR/creamapi_launcher_files/cream_api.ini"; do
        [ -f "$ini_path" ] || continue
        if [ -s "$ini_path" ] && [ -n "$(tail -c1 "$ini_path")" ]; then
            printf '\n' >> "$ini_path"
        fi

        local added=0
        local pending=()
        IFS=',' read -ra ids <<< "$csv"
        for id in "${ids[@]}"; do
            id="$(echo "$id" | xargs)"
            [ -z "$id" ] && continue
            grep -q "^$id " "$ini_path" 2>/dev/null && continue
            pending+=("$id")
        done

        local total=${#pending[@]}
        local current=0
        for id in "${pending[@]}"; do
            current=$((current+1))
            printf "\r${C_DIM}$(t fetching_dlc_info) [%d/%d] %s...${C_RESET}      " "$current" "$total" "$id"
            local name="$id"
            local dlc_info
            dlc_info=$(http_get_fast "$STEAMCMD_API/$id" 2>/dev/null) || true
            if [ -n "$dlc_info" ]; then
                if command -v jq >/dev/null 2>&1; then
                    local n
                    n=$(echo "$dlc_info" | jq -r ".data[\"$id\"].common.name // empty")
                    [ -n "$n" ] && name="$n"
                else
                    local n
                    n=$(echo "$dlc_info" | grep -oP '"name"\s*:\s*"\K[^"]+' | head -1)
                    [ -n "$n" ] && name="$n"
                fi
            fi
            echo "$id = $name" >> "$ini_path"
            added=$((added+1))
        done

        [ "$added" -gt 0 ] && echo ""
        if [ "$added" -gt 0 ]; then
            log OK "$(t ini_updated) +$added in $ini_path"
        fi
        sed -i 's/\r$//; s/$/\r/' "$ini_path"
    done
}

DLC_HASHES_JSON=""

fetch_dlc_hashes() {
    DLC_HASHES_JSON=$(http_get "$GITHUB_HASHES_URL" 2>/dev/null) || true
    if [ -z "$DLC_HASHES_JSON" ]; then
        DLC_HASHES_JSON=$(http_get "$JSDELIVR_HASHES_URL" 2>/dev/null) || true
    fi
    [ -n "$DLC_HASHES_JSON" ]
}

dlc_hash_entries() {
    if command -v jq >/dev/null 2>&1; then
        echo "$DLC_HASHES_JSON" | jq -r 'to_entries[] | "\(.key)\t\(.value)"'
    else
        echo "$DLC_HASHES_JSON" | grep -oP '"[^"]+"\s*:\s*"[a-fA-F0-9]{32}"' \
            | sed -E 's/^"([^"]+)"[[:space:]]*:[[:space:]]*"([a-fA-F0-9]{32})"$/\1\t\2/'
    fi
}

mark_stale_dlc_folders() {
    local dlc_dir="$1"
    fetch_dlc_hashes || { log WARN "$(t hashes_skip)"; return; }

    declare -A expected_hash=()
    while IFS=$'\t' read -r relpath md5; do
        [ -n "$relpath" ] && expected_hash["$relpath"]="$md5"
    done < <(dlc_hash_entries)

    [ ${#expected_hash[@]} -eq 0 ] && return

    local stale_folders=()
    local key
    for key in "${!expected_hash[@]}"; do
        local folder="${key%%/*}"
        local already=0
        local sf
        for sf in "${stale_folders[@]:-}"; do
            [ "$sf" = "$folder" ] && already=1 && break
        done
        [ "$already" -eq 1 ] && continue
        [ -d "$dlc_dir/$folder" ] || continue

        local localfile="$dlc_dir/$key"
        if [ ! -f "$localfile" ]; then
            stale_folders+=("$folder")
            continue
        fi
        local actual
        actual=$(md5sum "$localfile" 2>/dev/null | awk '{print $1}')
        if [ "$actual" != "${expected_hash[$key]}" ]; then
            stale_folders+=("$folder")
        fi
    done

    for sf in "${stale_folders[@]}"; do
        log WARN "$(t dlc_outdated) $sf"
        rm -rf "$dlc_dir/$sf"
    done
}

download_dlc_content() {
    local dlc_dir="$GAME_DIR/dlc"
    mkdir -p "$dlc_dir"

    mark_stale_dlc_folders "$dlc_dir"

    local folders=()
    while IFS= read -r f; do
        [ -n "$f" ] && folders+=("$f")
    done < <(dlc_folders)

    local total=${#folders[@]}
    local queue=()
    for f in "${folders[@]}"; do
        local dir="$dlc_dir/$f"
        local zip="$dlc_dir/$f.zip"
        if [ -d "$dir" ]; then continue; fi
        if [ -f "$zip" ]; then
            unzip -tq "$zip" >/dev/null 2>&1 && continue
            rm -f "$zip"
        fi
        queue+=("$f")
    done

    if [ ${#queue[@]} -eq 0 ]; then
        log OK "$(t no_dlc_to_download)"
        return 0
    fi

    log INFO "$(t to_download) ${#queue[@]} / $total"
    local i=0
    for f in "${queue[@]}"; do
        i=$((i+1))
        local url="https://$SERVER_URL/unlocker/$f.zip"
        local dest="$dlc_dir/$f.zip"
        echo
        log INFO "[$i/${#queue[@]}] $f"
        download_file "$url" "$dest" "$f" || continue
    done

    log INFO "$(t unpacking)"
    for z in "$dlc_dir"/*.zip; do
        [ -f "$z" ] || continue
        local base
        base="$(basename "$z" .zip)"
        if unzip -oq "$z" -d "$dlc_dir"; then
            rm -f "$z"
            log OK "  Unpacked: $base"
        else
            log ERROR "  Unzip error: $base"
        fi
    done
}

do_install() {
    header
    echo -e "${C_BOLD}$(t m_install)${C_RESET}"
    hr

    resolve_steam_dir || { log ERROR "$(t steam_not_found)"; pause; return 1; }
    log OK "$(t steam_found) $STEAM_DIR $([ "$IS_FLATPAK_STEAM" = 1 ] && t flatpak_steam)"

    resolve_game_dir || { log ERROR "$(t game_not_found)"; pause; return 1; }
    log OK "$(t game_found) $GAME_DIR"

    if is_proton_build; then
        log OK "$(t proton_build)"
    else
        log ERROR "$(t not_proton)"; pause; return 1;
    fi

    resolve_prefix_dir || { log ERROR "Proton prefix is required."; pause; return 1; }
    log OK "Proton prefix: $PREFIX_DIR"

    echo
    local reinstall_launcher=1
    local launcher_ver=0
    local no_update=1
    local full_reinstall=0

    ask "$(t opt_reinstall)" ans
    [[ "$ans" =~ ^[nNнН]$ ]] && reinstall_launcher=0

    if [ "$reinstall_launcher" -eq 1 ]; then
        echo "0) $(t launcher_default)"
        local idx=1
        for alt in "${ALT_LAUNCHERS[@]}"; do
            echo "$idx) $alt"
            idx=$((idx+1))
        done
        ask "$(t opt_ver)" launcher_ver
        [[ ! "$launcher_ver" =~ ^[0-3]$ ]] && launcher_ver=0
    fi

    ask "$(t opt_noupdate)" ans
    [[ "$ans" =~ ^[nNнН]$ ]] && no_update=0

    ask "$(t opt_full)" ans
    [[ "$ans" =~ ^[yYдД]$ ]] && full_reinstall=1

    echo
    ask "$(t confirm_install)" confirm
    [ -z "$confirm" ] && confirm="y"
    if [[ ! "$confirm" =~ ^[yYдД]$ ]]; then
        log INFO "$(t cancelled)"; pause; return 0
    fi

    fetch_dlc_data || { pause; return 1; }
    fetch_creamapi || { pause; return 1; }
    update_cream_ini

    if [ "$full_reinstall" -eq 1 ]; then
        log WARN "Full reinstall: removing Paradox Interactive Stellaris documents (saves and settings)..."
        rm -rf "$PREFIX_DIR/drive_c/users/steamuser/Documents/Paradox Interactive/Stellaris"
        rm -rf "$GAME_DIR/dlc"
    fi

    mkdir -p "$GAME_DIR/dlc"

    if [ "$reinstall_launcher" -eq 1 ]; then
        log INFO "Reinstalling Paradox Launcher (binary files only)..."
        local msi_path=""
        if [ "$launcher_ver" -gt 0 ]; then
            local alt_name="${ALT_LAUNCHERS[$((launcher_ver-1))]}"
            msi_path="$CACHE_DIR/$alt_name"
            if [ ! -f "$msi_path" ]; then
                download_file "https://$SERVER_URL/unlocker/$alt_name" "$msi_path" "$alt_name"
            fi
            log INFO "  Using alt launcher: $(basename "$msi_path")"
        else
            msi_path=$(ls -v "$GAME_DIR"/launcher-installer-windows*.msi 2>/dev/null | tail -n 1)
            [ -n "$msi_path" ] && log INFO "  MSI selected (latest): $(basename "$msi_path")"
        fi

        if [ -n "$msi_path" ] && [ -f "$msi_path" ]; then
            local pointer_file="$PREFIX_DIR/drive_c/users/steamuser/AppData/Local/Paradox Interactive/launcherpath"
            local pointer_backup=""
            if [ -f "$pointer_file" ]; then
                pointer_backup=$(cat "$pointer_file" | tr -d '\r\n')
            fi

            log INFO "  Removing old MSI registry keys (/uninstall)..."
            run_wine msiexec /uninstall "Z:${msi_path//\//\\}" /quiet /norestart >/dev/null 2>&1 || true
            sleep 2

            local cleaned_any=0
            while IFS= read -r l_base; do
                if [ -n "$l_base" ] && [ -d "$l_base" ]; then
                    log INFO "  Removing old binaries in: $l_base"
                    rm -rf "$l_base"
                    cleaned_any=1
                fi
            done < <(get_launcher_bases)

            [ "$cleaned_any" -eq 1 ] && sleep 1

            log INFO "  Running msiexec /package..."
            run_wine msiexec /package "Z:${msi_path//\//\\}" /quiet /norestart CREATE_DESKTOP_SHORTCUT=0
            sleep 2

            if [ -n "$pointer_backup" ] && [ ! -f "$pointer_file" ]; then
                mkdir -p "$(dirname "$pointer_file")"
                echo "$pointer_backup" > "$pointer_file"
                log INFO "  Restored launcherpath from backup."
            fi

            log OK "  Launcher reinstalled."
        else
            log WARN "  No MSI found — skipping launcher reinstall."
        fi
    else
        log INFO "Launcher reinstall skipped."
    fi

    log INFO "$(t patching_launcher)"
    local found_launcher=0
    local processed_bases=()

    while IFS= read -r l_base; do
        if [ -n "$l_base" ] && [ -d "$l_base" ]; then
            local skip=0
            for pb in "${processed_bases[@]}"; do
                if [ "$pb" == "$l_base" ]; then skip=1; break; fi
            done
            [ "$skip" -eq 1 ] && continue
            processed_bases+=("$l_base")

            for lf in "$l_base"/launcher-*; do
                [ -d "$lf" ] || continue
                found_launcher=1
                log INFO "  Processing: $(basename "$lf") in $(basename "$(dirname "$l_base")")"

                if [ "$no_update" -eq 1 ]; then
                    rm -f "$lf/xdelta3.exe"
                    log OK "    Removed xdelta3.exe (auto-update disabled)."
                fi

                local t1="$lf/resources/app.asar.unpacked/node_modules/greenworks/lib"
                local t2="$lf/resources/app/dist/main"
                local patched=0

                if [ -d "$t1" ]; then
                    cp -rf "$CACHE_DIR/creamapi_launcher_files/"* "$t1/"
                    patched=1
                fi
                if [ -d "$t2" ]; then
                    cp -rf "$CACHE_DIR/creamapi_launcher_files/"* "$t2/"
                    patched=1
                fi

                if [ "$patched" -eq 1 ]; then
                    log OK "    Patched resources."
                else
                    log WARN "    No patchable resources folder found in this version."
                fi
            done
        fi
    done < <(get_launcher_bases)

    if [ "$found_launcher" -eq 0 ]; then
        log WARN "  Launcher versions not found. Run the game once via Steam to initialize the launcher."
    fi

    log INFO "$(t copying_files)"
    cp -rf "$CACHE_DIR/creamapi_steam_files/"* "$GAME_DIR/"
    log OK "  Steam files copied."

    if [ -f "$GAME_DIR/steam_api64.dll" ] && [ ! -f "$GAME_DIR/steam_api64_o.dll" ]; then
        mv -f "$GAME_DIR/steam_api64.dll" "$GAME_DIR/steam_api64_o.dll"
        log OK "  Original steam_api64.dll backed up to steam_api64_o.dll."
    fi
    cp -f "$CACHE_DIR/$CREAMLINUX_PROTON_SUBDIR/creamlinux.json" "$GAME_DIR/creamlinux.json"
    cp -f "$CACHE_DIR/$CREAMLINUX_PROTON_SUBDIR/steam_api64.dll" "$GAME_DIR/steam_api64.dll"
    log OK "  creamlinux.json / steam_api64.dll copied."

    download_dlc_content

    echo
    log OK "$(t install_done)"
    pause
}

show_status() {
    header
    echo -e "${C_BOLD}$(t m_status)${C_RESET}"
    hr

    find_steam_dir
    if [ -n "$STEAM_DIR" ]; then
        echo -e "${C_GREEN}$(t steam_found)${C_RESET} $STEAM_DIR $([ "$IS_FLATPAK_STEAM" = 1 ] && t flatpak_steam)"
    else
        echo -e "${C_RED}$(t steam_not_found)${C_RESET}"
    fi

    find_game_dir
    if [ -n "$GAME_DIR" ]; then
        echo -e "${C_GREEN}$(t game_found)${C_RESET} $GAME_DIR"
        if is_proton_build; then
            echo -e "${C_GREEN}$(t proton_build)${C_RESET}"
        else
            echo -e "${C_RED}$(t not_proton)${C_RESET}"
        fi

        find_prefix_dir
        if [ -n "$PREFIX_DIR" ]; then
            echo -e "${C_GREEN}Proton Prefix:${C_RESET} $PREFIX_DIR"

            local launcher_found=0
            while IFS= read -r l_base; do
                if [ -n "$l_base" ] && [ -d "$l_base" ]; then
                    for lf in "$l_base"/launcher-*; do
                        if [ -d "$lf" ]; then
                            launcher_found=1
                            break 2
                        fi
                    done
                fi
            done < <(get_launcher_bases)

            if [ "$launcher_found" -eq 1 ]; then
                echo -e "${C_GREEN}Paradox Launcher:${C_RESET} Installed"
            else
                echo -e "${C_YELLOW}Paradox Launcher:${C_RESET} Not found in prefix"
            fi
        else
            echo -e "${C_YELLOW}Proton Prefix:${C_RESET} Not found (will ask during install)"
        fi

        if [ -f "$GAME_DIR/cream_api.ini" ]; then
            local cnt
            cnt=$(grep -c "=" "$GAME_DIR/cream_api.ini" 2>/dev/null || echo 0)
            echo -e "${C_GREEN}cream_api.ini:${C_RESET} $cnt DLC entries"
        else
            echo -e "${C_YELLOW}cream_api.ini:${C_RESET} not installed"
        fi
    else
        echo -e "${C_RED}$(t game_not_found)${C_RESET}"
    fi
    pause
}

show_log() {
    header
    echo -e "${C_BOLD}$(t m_log)${C_RESET}"
    hr
    if [ -s "$LOG_FILE" ]; then
        tail -n 50 "$LOG_FILE"
    else
        echo "$(t log_empty)"
    fi
    pause
}

change_language() {
    header
    echo "1) English"
    echo "2) Русский"
    echo "3) 中文"
    ask "$(t choose)" l
    case "$l" in
        1) LANGUAGE="en" ;;
        2) LANGUAGE="ru" ;;
        3) LANGUAGE="zh" ;;
    esac
    echo "$LANGUAGE" > "$CONFIG_FILE"
    log OK "$LANGUAGE"
    pause
}

check_deps() {
    local missing=()
    for c in curl unzip grep awk; do
        command -v "$c" >/dev/null 2>&1 || missing+=("$c")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${C_RED}Missing required tools: ${missing[*]}${C_RESET}"
        echo "Install them with your package manager."
        exit 1
    fi
    command -v jq >/dev/null 2>&1 || log WARN "jq not found — falling back to grep JSON parsing."
}

main_menu() {
    while true; do
        header
        echo -e "${C_BOLD}$(t menu_header)${C_RESET}"
        hr
        echo -e "  ${C_CYAN}1)${C_RESET} $(t m_status)"
        echo -e "  ${C_CYAN}2)${C_RESET} $(t m_install)"
        echo -e "  ${C_CYAN}3)${C_RESET} Language / Язык / 中文"
        echo -e "  ${C_CYAN}4)${C_RESET} $(t m_log)"
        echo -e "  ${C_CYAN}0)${C_RESET} $(t m_exit)"
        hr
        ask "$(t choose)" choice
        case "$choice" in
            1) show_status ;;
            2) do_install ;;
            3) change_language ;;
            4) show_log ;;
            0) exit 0 ;;
            *) log WARN "$(t invalid_choice)"; sleep 1 ;;
        esac
    done
}

detect_system_lang() {
    local loc="${LANG:-en}"
    loc="$(echo "$loc" | tr '[:upper:]' '[:lower:]')"
    case "$loc" in
        ru*) echo ru ;;
        zh*) echo zh ;;
        *) echo en ;;
    esac
}

if [ -f "$CONFIG_FILE" ]; then
    LANGUAGE="$(cat "$CONFIG_FILE")"
else
    LANGUAGE="$(detect_system_lang)"
fi
check_deps
main_menu
