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

CREAMLINUX_SUBDIR="creamlinux"
CREAMLINUX_FILES=(cream.sh lib32Creamlinux.so lib64Creamlinux.so cream_api.ini)

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
        title) echo "Stellaris DLC Unlocker" ;;
        menu_header) echo "MAIN MENU" ;;
        m_status) echo "Status" ;;
        m_install) echo "Install / Update" ;;
        fetching_dlc_info) echo "Fetching DLC info:" ;;
        fetching_file) echo "  -> In progress:" ;;
        m_steam_launch) echo "Set Steam launch options" ;;
        m_lang) echo "Language" ;;
        m_log) echo "Log" ;;
        m_exit) echo "Exit" ;;
        choose) echo "> " ;;
        steam_found) echo "Steam:" ;;
        steam_not_found) echo "Steam not found." ;;
        game_found) echo "Stellaris:" ;;
        game_not_found) echo "Stellaris not found." ;;
        native_build) echo "Native Linux build." ;;
        not_native) echo "Not a native Linux build. Use the Proton unlocker instead." ;;
        downloading) echo "Downloading" ;;
        fetching_dlc_list) echo "Fetching DLC list..." ;;
        dlc_list_ok) echo "DLC list loaded." ;;
        dlc_list_fail) echo "Failed to fetch DLC list." ;;
        fetching_creamlinux) echo "Downloading CreamLinux files..." ;;
        creamlinux_ok) echo "CreamLinux files ready." ;;
        copying_files) echo "Copying files to game folder..." ;;
        to_download) echo "DLC to download:" ;;
        unpacking) echo "Unpacking..." ;;
        updating_ini) echo "Updating cream_api.ini..." ;;
        ini_updated) echo "cream_api.ini: added" ;;
        ini_skip) echo "SteamCMD unavailable, skipped." ;;
        install_done) echo "Done." ;;
        patch_launch_header) echo "Steam launch options" ;;
        patch_userdata_not_found) echo "Steam userdata folder not found." ;;
        patch_localconfig_not_found) echo "localconfig.vdf not found." ;;
        patch_backup) echo "Backup:" ;;
        patch_done) echo "Launch options set." ;;
        steam_running_prompt) echo "Steam is running and must be closed to apply launch options. Close it now? [Y/n]: " ;;
        steam_closing) echo "Closing Steam..." ;;
        steam_close_ok) echo "Steam closed." ;;
        steam_close_fail) echo "Could not close Steam, aborting." ;;
        abort_steam_running) echo "Skipped: Steam is still running." ;;
        press_enter) echo "Press Enter to continue..." ;;
        enter_game_path) echo "Game path (or Enter to cancel): " ;;
        invalid_game_path) echo "Path does not exist." ;;
        enter_steam_path) echo "Steam not auto-detected. Enter Steam folder path (or Enter to cancel): " ;;
        invalid_steam_path) echo "Not a valid Steam folder (no 'steamapps' inside)." ;;
        invalid_choice) echo "Invalid choice." ;;
        log_empty) echo "Log is empty." ;;
        confirm_install) echo "Proceed? [Y/n]: " ;;
        cancelled) echo "Cancelled." ;;
        no_dlc_to_download) echo "All DLC up to date." ;;
        hashes_skip) echo "Could not fetch hashes.json, skipping integrity check." ;;
        dlc_outdated) echo "Outdated content, will re-download:" ;;
        flatpak_steam) echo "(Flatpak)" ;;
        *) echo "$1" ;;
    esac
}

_t_ru() {
    case "$1" in
        title) echo "Stellaris DLC Unlocker" ;;
        menu_header) echo "ГЛАВНОЕ МЕНЮ" ;;
        m_status) echo "Статус" ;;
        m_install) echo "Установить / обновить" ;;
        fetching_dlc_info) echo "Запрос данных DLC:" ;;
        fetching_file) echo "  -> В процессе:" ;;
        m_steam_launch) echo "Прописать параметры запуска Steam" ;;
        m_lang) echo "Язык" ;;
        m_log) echo "Лог" ;;
        m_exit) echo "Выход" ;;
        choose) echo "> " ;;
        steam_found) echo "Steam:" ;;
        steam_not_found) echo "Steam не найден." ;;
        game_found) echo "Stellaris:" ;;
        game_not_found) echo "Stellaris не найден." ;;
        native_build) echo "Нативная Linux-версия." ;;
        not_native) echo "Не нативная Linux-версия. Используйте анлокер для Proton." ;;
        downloading) echo "Скачивание" ;;
        fetching_dlc_list) echo "Получение списка DLC..." ;;
        dlc_list_ok) echo "Список DLC загружен." ;;
        dlc_list_fail) echo "Не удалось получить список DLC." ;;
        fetching_creamlinux) echo "Скачивание файлов CreamLinux..." ;;
        creamlinux_ok) echo "Файлы CreamLinux готовы." ;;
        copying_files) echo "Копирование файлов в папку игры..." ;;
        to_download) echo "DLC к скачиванию:" ;;
        unpacking) echo "Распаковка..." ;;
        updating_ini) echo "Обновление cream_api.ini..." ;;
        ini_updated) echo "cream_api.ini: добавлено" ;;
        ini_skip) echo "SteamCMD недоступен, пропущено." ;;
        install_done) echo "Готово." ;;
        patch_launch_header) echo "Параметры запуска Steam" ;;
        patch_userdata_not_found) echo "Папка userdata Steam не найдена." ;;
        patch_localconfig_not_found) echo "localconfig.vdf не найден." ;;
        patch_backup) echo "Бэкап:" ;;
        patch_done) echo "Параметры запуска установлены." ;;
        steam_running_prompt) echo "Steam запущен, для применения параметров запуска его нужно закрыть. Закрыть сейчас? [Y/n]: " ;;
        steam_closing) echo "Закрытие Steam..." ;;
        steam_close_ok) echo "Steam закрыт." ;;
        steam_close_fail) echo "Не удалось закрыть Steam, отмена." ;;
        abort_steam_running) echo "Пропущено: Steam всё ещё запущен." ;;
        press_enter) echo "Нажмите Enter для продолжения..." ;;
        enter_game_path) echo "Путь к игре (или Enter, чтобы отменить): " ;;
        invalid_game_path) echo "Такого пути не существует." ;;
        enter_steam_path) echo "Steam не найден автоматически. Введите путь к папке Steam (или Enter, чтобы отменить): " ;;
        invalid_steam_path) echo "Это не папка Steam (внутри нет 'steamapps')." ;;
        invalid_choice) echo "Неверный выбор." ;;
        log_empty) echo "Лог пуст." ;;
        confirm_install) echo "Продолжить? [Y/n]: " ;;
        cancelled) echo "Отменено." ;;
        no_dlc_to_download) echo "Все DLC актуальны." ;;
        hashes_skip) echo "Не удалось получить hashes.json, проверка целостности пропущена." ;;
        dlc_outdated) echo "Контент устарел, будет перекачан:" ;;
        flatpak_steam) echo "(Flatpak)" ;;
        *) echo "$1" ;;
    esac
}

_t_zh() {
    case "$1" in
        title) echo "Stellaris DLC Unlocker" ;;
        menu_header) echo "主菜单" ;;
        m_status) echo "状态" ;;
        m_install) echo "安装 / 更新" ;;
        fetching_dlc_info) echo "正在获取 DLC 信息:" ;;
        fetching_file) echo "  -> 正在处理:" ;;
        m_steam_launch) echo "设置 Steam 启动选项" ;;
        m_lang) echo "语言" ;;
        m_log) echo "日志" ;;
        m_exit) echo "退出" ;;
        choose) echo "> " ;;
        steam_found) echo "Steam:" ;;
        steam_not_found) echo "未找到 Steam。" ;;
        game_found) echo "Stellaris:" ;;
        game_not_found) echo "未找到 Stellaris。" ;;
        native_build) echo "原生 Linux 版本。" ;;
        not_native) echo "非原生 Linux 版本。请使用 Proton 解锁器。" ;;
        downloading) echo "下载中" ;;
        fetching_dlc_list) echo "正在获取 DLC 列表..." ;;
        dlc_list_ok) echo "DLC 列表已加载。" ;;
        dlc_list_fail) echo "获取 DLC 列表失败。" ;;
        fetching_creamlinux) echo "正在下载 CreamLinux 文件..." ;;
        creamlinux_ok) echo "CreamLinux 文件已就绪。" ;;
        copying_files) echo "正在复制文件到游戏目录..." ;;
        to_download) echo "待下载 DLC:" ;;
        unpacking) echo "正在解压..." ;;
        updating_ini) echo "正在更新 cream_api.ini..." ;;
        ini_updated) echo "cream_api.ini: 已添加" ;;
        ini_skip) echo "SteamCMD 不可用，已跳过。" ;;
        install_done) echo "完成。" ;;
        patch_launch_header) echo "Steam 启动选项" ;;
        patch_userdata_not_found) echo "未找到 Steam userdata 目录。" ;;
        patch_localconfig_not_found) echo "未找到 localconfig.vdf。" ;;
        patch_backup) echo "备份:" ;;
        patch_done) echo "启动选项已设置。" ;;
        steam_running_prompt) echo "Steam 正在运行，需关闭后才能应用启动选项。现在关闭吗？[Y/n]: " ;;
        steam_closing) echo "正在关闭 Steam..." ;;
        steam_close_ok) echo "Steam 已关闭。" ;;
        steam_close_fail) echo "无法关闭 Steam，已中止。" ;;
        abort_steam_running) echo "已跳过：Steam 仍在运行。" ;;
        press_enter) echo "按 Enter 继续..." ;;
        enter_game_path) echo "游戏路径（直接 Enter 取消）: " ;;
        invalid_game_path) echo "路径不存在。" ;;
        enter_steam_path) echo "未自动检测到 Steam。请输入 Steam 文件夹路径（直接 Enter 取消）: " ;;
        invalid_steam_path) echo "不是有效的 Steam 文件夹（内部没有 'steamapps'）。" ;;
        invalid_choice) echo "无效选择。" ;;
        log_empty) echo "日志为空。" ;;
        confirm_install) echo "继续？[Y/n]: " ;;
        cancelled) echo "已取消。" ;;
        no_dlc_to_download) echo "所有 DLC 均为最新。" ;;
        hashes_skip) echo "无法获取 hashes.json，跳过完整性检查。" ;;
        dlc_outdated) echo "内容已过期，将重新下载:" ;;
        flatpak_steam) echo "(Flatpak)" ;;
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

progress_bar() {
    local current="$1" total="$2" label="$3"
    local width=30
    local pct=0
    [ "$total" -gt 0 ] && pct=$(( current * 100 / total ))
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    printf "\r${C_CYAN}[%-${width}s]${C_RESET} %3d%% %s" \
        "$(printf '#%.0s' $(seq 1 $filled) 2>/dev/null)$(printf '.%.0s' $(seq 1 $empty) 2>/dev/null)" \
        "$pct" "$label"
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
IS_FLATPAK_STEAM=0

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

is_native_build() {
    [ -f "$GAME_DIR/stellaris" ] && file "$GAME_DIR/stellaris" 2>/dev/null | grep -qi "ELF"
}

resolve_steam_dir() {
    if [ -n "$STEAM_DIR" ]; then
        return 0
    fi
    if find_steam_dir; then
        return 0
    fi
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
    if find_game_dir; then
        return 0
    fi
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

is_steam_running() {
    pgrep -x steam >/dev/null 2>&1 && return 0
    pgrep -f "com.valvesoftware.Steam" >/dev/null 2>&1 && return 0
    return 1
}

close_steam() {
    log INFO "$(t steam_closing)"
    if [ "$IS_FLATPAK_STEAM" = 1 ] && command -v flatpak >/dev/null 2>&1; then
        flatpak kill com.valvesoftware.Steam >/dev/null 2>&1
    fi
    command -v steam >/dev/null 2>&1 && steam -shutdown >/dev/null 2>&1 &
    pkill -x steam >/dev/null 2>&1

    local waited=0
    while is_steam_running && [ "$waited" -lt 15 ]; do
        sleep 1
        waited=$((waited+1))
    done

    if is_steam_running; then
        pkill -9 -x steam >/dev/null 2>&1
        sleep 1
    fi

    if is_steam_running; then
        log ERROR "$(t steam_close_fail)"
        return 1
    fi
    log OK "$(t steam_close_ok)"
    return 0
}

ensure_steam_closed() {
    if ! is_steam_running; then
        return 0
    fi
    ask "$(t steam_running_prompt)" ans
    [ -z "$ans" ] && ans="y"
    if [[ "$ans" =~ ^[yYдД]$ ]]; then
        close_steam || return 1
        return 0
    fi
    log WARN "$(t abort_steam_running)"
    return 1
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

fetch_creamlinux() {
    local dest_dir="$CACHE_DIR/$CREAMLINUX_SUBDIR"
    log INFO "$(t fetching_creamlinux)"
    local ok=1
    for f in "${CREAMLINUX_FILES[@]}"; do
        download_with_fallback "$CREAMLINUX_SUBDIR/$f" "$dest_dir/$f" "$f" || ok=0
    done
    if [ "$ok" -eq 1 ]; then
        log OK "$(t creamlinux_ok)"
        return 0
    fi
    return 1
}

copy_creamlinux_to_game() {
    local src_dir="$CACHE_DIR/$CREAMLINUX_SUBDIR"
    log INFO "$(t copying_files)"
    for f in cream.sh lib32Creamlinux.so lib64Creamlinux.so; do
        if [ -f "$src_dir/$f" ]; then
            cp -f "$src_dir/$f" "$GAME_DIR/$f"
        else
            log WARN "Missing in CreamLinux package: $f"
        fi
    done
    chmod +x "$GAME_DIR/cream.sh" 2>/dev/null
    log OK "CreamLinux files copied to: $GAME_DIR"
}

update_cream_ini() {
    local ini_path="$GAME_DIR/cream_api.ini"
    local cached_ini="$CACHE_DIR/$CREAMLINUX_SUBDIR/cream_api.ini"

    if [ -f "$cached_ini" ]; then
        cp -f "$cached_ini" "$ini_path"
        sed -i 's/\r$//' "$ini_path"
    else
        : > "$ini_path"
    fi

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

    if [ -s "$ini_path" ] && [ -n "$(tail -c1 "$ini_path")" ]; then
        printf '\n' >> "$ini_path"
    fi

    local added=0
    IFS=',' read -ra ids <<< "$csv"
    for id in "${ids[@]}"; do
        id="$(echo "$id" | xargs)"
        [ -z "$id" ] && continue
        grep -q "^$id " "$ini_path" 2>/dev/null && continue
        printf "\r${C_DIM}$(t fetching_dlc_info) %s...${C_RESET}      " "$id"
        local name="$id"
        local dlc_info
        dlc_info=$(http_get "$STEAMCMD_API/$id" 2>/dev/null) || true
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
        log OK "$(t ini_updated) +$added"
    fi
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
            log OK "Unpacked: $base"
        else
            log ERROR "Unzip error: $base"
        fi
    done
}

patch_launch_options_core() {
    resolve_steam_dir || { log ERROR "$(t steam_not_found)"; return 1; }

    ensure_steam_closed || return 1

    local userdata_dir="$STEAM_DIR/userdata"
    if [ ! -d "$userdata_dir" ]; then
        log ERROR "$(t patch_userdata_not_found)"
        return 1
    fi

    local patched_any=0
    for user_dir in "$userdata_dir"/*/; do
        local vdf="${user_dir}config/localconfig.vdf"
        [ -f "$vdf" ] || continue

        local backup="${vdf}.bak.$(date +%Y%m%d%H%M%S)"
        cp -f "$vdf" "$backup"
        log INFO "$(t patch_backup) $backup"

        local desired='sh ./cream.sh %command%'
        local tmp
        tmp=$(mktemp)

        awk -v appid="\"$APPID\"" -v opt="$desired" '
            BEGIN { in_block=0; depth=0; done=0 }
            {
                line=$0
                trimmed=line
                gsub(/^[ \t]+|[ \t]+$/, "", trimmed)

                if (!in_block && trimmed == appid) {
                    in_block=1
                    print line
                    next
                }

                if (in_block && depth==0 && trimmed == "{") {
                    depth=1
                    print line
                    next
                }

                if (in_block && depth==1) {
                    if (trimmed ~ /^"LaunchOptions"/) {
                        sub(/"LaunchOptions".*/, "\"LaunchOptions\"\t\t\"" opt "\"", line)
                        print line
                        done=1
                        next
                    }
                    if (trimmed == "{") { depth++; print line; next }
                    if (trimmed == "}") {
                        if (!done) {
                            print "\t\t\t\"LaunchOptions\"\t\t\"" opt "\""
                            done=1
                        }
                        in_block=0
                        depth=0
                        print line
                        next
                    }
                }

                if (in_block && depth>1) {
                    if (trimmed == "{") depth++
                    if (trimmed == "}") depth--
                }

                print line
            }
        ' "$vdf" > "$tmp"

        if grep -q "$APPID" "$tmp"; then
            mv "$tmp" "$vdf"
            patched_any=1
            log OK "$(t patch_done)"
        else
            rm -f "$tmp"
            log WARN "AppID $APPID not found in $vdf"
        fi
    done

    if [ "$patched_any" -eq 0 ]; then
        log ERROR "$(t patch_localconfig_not_found)"
        return 1
    fi
    return 0
}

patch_launch_options() {
    header
    echo -e "${C_BOLD}$(t patch_launch_header)${C_RESET}"
    hr
    patch_launch_options_core
    pause
}

do_install() {
    header
    echo -e "${C_BOLD}$(t m_install)${C_RESET}"
    hr

    resolve_steam_dir
    if [ -z "$STEAM_DIR" ]; then
        log ERROR "$(t steam_not_found)"
        pause; return 1
    fi
    log OK "$(t steam_found) $STEAM_DIR $([ "$IS_FLATPAK_STEAM" = 1 ] && t flatpak_steam)"

    resolve_game_dir
    if [ -z "$GAME_DIR" ]; then
        log ERROR "$(t game_not_found)"
        pause; return 1
    fi
    log OK "$(t game_found) $GAME_DIR"

    if is_native_build; then
        log OK "$(t native_build)"
    else
        log ERROR "$(t not_native)"
        pause; return 1
    fi

    echo
    ask "$(t confirm_install)" confirm
    [ -z "$confirm" ] && confirm="y"
    if [[ ! "$confirm" =~ ^[yYдД]$ ]]; then
        log INFO "$(t cancelled)"
        pause; return 0
    fi

    fetch_dlc_data || { pause; return 1; }
    fetch_creamlinux || { pause; return 1; }
    copy_creamlinux_to_game
    mkdir -p "$GAME_DIR/dlc"
    update_cream_ini
    download_dlc_content

    echo
    echo -e "${C_BOLD}$(t patch_launch_header)${C_RESET}"
    patch_launch_options_core

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
        if is_native_build; then
            echo -e "${C_GREEN}$(t native_build)${C_RESET}"
        else
            echo -e "${C_RED}$(t not_native)${C_RESET}"
        fi
        if [ -f "$GAME_DIR/cream.sh" ]; then
            echo -e "${C_GREEN}cream.sh:${C_RESET} installed"
        else
            echo -e "${C_YELLOW}cream.sh:${C_RESET} not installed"
        fi
        if [ -f "$GAME_DIR/cream_api.ini" ]; then
            local cnt
            cnt=$(grep -c "=" "$GAME_DIR/cream_api.ini" 2>/dev/null || echo 0)
            echo -e "${C_GREEN}cream_api.ini:${C_RESET} $cnt DLC entries"
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
        echo "Install them with your package manager, e.g.: sudo apt install ${missing[*]}"
        exit 1
    fi
    command -v jq >/dev/null 2>&1 || log WARN "jq not found — falling back to grep/sed JSON parsing (less robust). Install jq for best reliability."
}

main_menu() {
    while true; do
        header
        echo -e "${C_BOLD}$(t menu_header)${C_RESET}"
        hr
        echo -e "  ${C_CYAN}1)${C_RESET} $(t m_status)"
        echo -e "  ${C_CYAN}2)${C_RESET} $(t m_install)"
        echo -e "  ${C_CYAN}3)${C_RESET} $(t m_steam_launch)"
        echo -e "  ${C_CYAN}4)${C_RESET} $(t m_lang)"
        echo -e "  ${C_CYAN}5)${C_RESET} $(t m_log)"
        echo -e "  ${C_CYAN}0)${C_RESET} $(t m_exit)"
        hr
        ask "$(t choose)" choice
        case "$choice" in
            1) show_status ;;
            2) do_install ;;
            3) patch_launch_options ;;
            4) change_language ;;
            5) show_log ;;
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
