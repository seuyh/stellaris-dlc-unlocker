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
SERVER_URL="pub-0f87be5fdd68492c8328b66998eb46ad.r2.dev"
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
        title) echo "Stellaris DLC Unlocker — Linux Edition" ;;
        menu_header) echo "MAIN MENU" ;;
        m_status) echo "Status & paths" ;;
        m_install) echo "Install / Update DLC unlocker" ;;
        m_steam_launch) echo "Patch Steam launch options" ;;
        m_lang) echo "Change language" ;;
        m_log) echo "Show log" ;;
        m_exit) echo "Exit" ;;
        choose) echo "Choose an option: " ;;
        detect_steam) echo "Detecting Steam installation..." ;;
        steam_found) echo "Steam found:" ;;
        steam_not_found) echo "Steam installation not found." ;;
        detect_game) echo "Detecting Stellaris installation..." ;;
        game_found) echo "Stellaris found:" ;;
        game_not_found) echo "Stellaris installation not found." ;;
        native_build) echo "Native Linux build detected — CreamLinux is compatible." ;;
        not_native) echo "Native Linux build NOT detected (no 'stellaris' ELF binary). CreamLinux requires the native build, not Proton/Wine." ;;
        downloading) echo "Downloading" ;;
        fetching_dlc_list) echo "Fetching DLC list..." ;;
        dlc_list_ok) echo "DLC list loaded." ;;
        dlc_list_fail) echo "Failed to fetch DLC list from GitHub and jsDelivr." ;;
        fetching_creamlinux) echo "Downloading CreamLinux..." ;;
        creamlinux_ok) echo "CreamLinux files ready." ;;
        copying_files) echo "Copying CreamLinux files into game folder..." ;;
        checking_hashes) echo "Checking file integrity (hashes.json)..." ;;
        to_download) echo "DLC archives to download:" ;;
        unpacking) echo "Unpacking archives..." ;;
        updating_ini) echo "Updating cream_api.ini via SteamCMD API..." ;;
        ini_updated) echo "cream_api.ini updated, added DLC:" ;;
        ini_skip) echo "SteamCMD API unavailable, skipped." ;;
        install_done) echo "Installation complete!" ;;
        patch_launch_header) echo "Patching Steam launch options" ;;
        patch_userdata_not_found) echo "Could not find Steam userdata folder." ;;
        patch_localconfig_not_found) echo "localconfig.vdf not found for any user." ;;
        patch_backup) echo "Backup created:" ;;
        patch_done) echo "Launch options set to: sh ./cream.sh %command%" ;;
        patch_already) echo "Launch options already set correctly." ;;
        patch_steam_running_warn) echo "WARNING: Steam appears to be running. Close Steam fully before/after patching, otherwise it may overwrite the change." ;;
        press_enter) echo "Press Enter to continue..." ;;
        enter_game_path) echo "Enter Stellaris game path manually (or press Enter to skip): " ;;
        invalid_choice) echo "Invalid choice." ;;
        lang_set) echo "Language set to English." ;;
        log_empty) echo "Log is empty." ;;
        confirm_install) echo "Proceed with installation? [y/N]: " ;;
        cancelled) echo "Cancelled." ;;
        no_dlc_to_download) echo "All DLC are up to date." ;;
        flatpak_steam) echo "(Flatpak)" ;;
        *) echo "$1" ;;
    esac
}

_t_ru() {
    case "$1" in
        title) echo "Stellaris DLC Unlocker — версия для Linux" ;;
        menu_header) echo "ГЛАВНОЕ МЕНЮ" ;;
        m_status) echo "Статус и пути" ;;
        m_install) echo "Установить / обновить разблокировщик DLC" ;;
        m_steam_launch) echo "Прописать параметры запуска в Steam" ;;
        m_lang) echo "Сменить язык" ;;
        m_log) echo "Показать лог" ;;
        m_exit) echo "Выход" ;;
        choose) echo "Выберите пункт: " ;;
        detect_steam) echo "Поиск установки Steam..." ;;
        steam_found) echo "Steam найден:" ;;
        steam_not_found) echo "Установка Steam не найдена." ;;
        detect_game) echo "Поиск установки Stellaris..." ;;
        game_found) echo "Stellaris найден:" ;;
        game_not_found) echo "Установка Stellaris не найдена." ;;
        native_build) echo "Обнаружена нативная Linux-версия — CreamLinux подходит." ;;
        not_native) echo "Нативная Linux-версия не обнаружена (нет ELF-файла 'stellaris'). CreamLinux работает только с нативной версией, не с Proton/Wine." ;;
        downloading) echo "Скачивание" ;;
        fetching_dlc_list) echo "Получение списка DLC..." ;;
        dlc_list_ok) echo "Список DLC загружен." ;;
        dlc_list_fail) echo "Не удалось получить список DLC ни с GitHub, ни с jsDelivr." ;;
        fetching_creamlinux) echo "Скачивание CreamLinux..." ;;
        creamlinux_ok) echo "Файлы CreamLinux готовы." ;;
        copying_files) echo "Копирование файлов CreamLinux в папку игры..." ;;
        checking_hashes) echo "Проверка целостности файлов (hashes.json)..." ;;
        to_download) echo "Архивов DLC к скачиванию:" ;;
        unpacking) echo "Распаковка архивов..." ;;
        updating_ini) echo "Обновление cream_api.ini через SteamCMD API..." ;;
        ini_updated) echo "cream_api.ini обновлён, добавлено DLC:" ;;
        ini_skip) echo "SteamCMD API недоступен, пропущено." ;;
        install_done) echo "Установка завершена!" ;;
        patch_launch_header) echo "Прописывание параметров запуска Steam" ;;
        patch_userdata_not_found) echo "Не удалось найти папку userdata Steam." ;;
        patch_localconfig_not_found) echo "Файл localconfig.vdf не найден ни для одного пользователя." ;;
        patch_backup) echo "Создана резервная копия:" ;;
        patch_done) echo "Параметры запуска установлены: sh ./cream.sh %command%" ;;
        patch_already) echo "Параметры запуска уже выставлены верно." ;;
        patch_steam_running_warn) echo "ВНИМАНИЕ: похоже, Steam запущен. Полностью закройте Steam до/после патчинга, иначе он может перезаписать изменение." ;;
        press_enter) echo "Нажмите Enter для продолжения..." ;;
        enter_game_path) echo "Введите путь к игре Stellaris вручную (или Enter, чтобы пропустить): " ;;
        invalid_choice) echo "Неверный выбор." ;;
        lang_set) echo "Язык переключён на русский." ;;
        log_empty) echo "Лог пуст." ;;
        confirm_install) echo "Продолжить установку? [y/N]: " ;;
        cancelled) echo "Отменено." ;;
        no_dlc_to_download) echo "Все DLC актуальны." ;;
        flatpak_steam) echo "(Flatpak)" ;;
        *) echo "$1" ;;
    esac
}

_t_zh() {
    case "$1" in
        title) echo "Stellaris DLC 解锁器 — Linux 版" ;;
        menu_header) echo "主菜单" ;;
        m_status) echo "状态与路径" ;;
        m_install) echo "安装 / 更新 DLC 解锁器" ;;
        m_steam_launch) echo "设置 Steam 启动选项" ;;
        m_lang) echo "切换语言" ;;
        m_log) echo "查看日志" ;;
        m_exit) echo "退出" ;;
        choose) echo "请选择: " ;;
        detect_steam) echo "正在检测 Steam 安装..." ;;
        steam_found) echo "已找到 Steam:" ;;
        steam_not_found) echo "未找到 Steam 安装。" ;;
        detect_game) echo "正在检测 Stellaris 安装..." ;;
        game_found) echo "已找到 Stellaris:" ;;
        game_not_found) echo "未找到 Stellaris 安装。" ;;
        native_build) echo "检测到原生 Linux 版本 — CreamLinux 兼容。" ;;
        not_native) echo "未检测到原生 Linux 版本（缺少 'stellaris' ELF 文件）。CreamLinux 仅支持原生版本，不支持 Proton/Wine。" ;;
        downloading) echo "下载中" ;;
        fetching_dlc_list) echo "正在获取 DLC 列表..." ;;
        dlc_list_ok) echo "DLC 列表已加载。" ;;
        dlc_list_fail) echo "从 GitHub 和 jsDelivr 获取 DLC 列表均失败。" ;;
        fetching_creamlinux) echo "正在下载 CreamLinux..." ;;
        creamlinux_ok) echo "CreamLinux 文件已就绪。" ;;
        copying_files) echo "正在将 CreamLinux 文件复制到游戏目录..." ;;
        checking_hashes) echo "正在校验文件完整性 (hashes.json)..." ;;
        to_download) echo "待下载的 DLC 压缩包:" ;;
        unpacking) echo "正在解压..." ;;
        updating_ini) echo "正在通过 SteamCMD API 更新 cream_api.ini..." ;;
        ini_updated) echo "cream_api.ini 已更新，新增 DLC:" ;;
        ini_skip) echo "SteamCMD API 不可用，已跳过。" ;;
        install_done) echo "安装完成！" ;;
        patch_launch_header) echo "设置 Steam 启动选项" ;;
        patch_userdata_not_found) echo "未找到 Steam userdata 目录。" ;;
        patch_localconfig_not_found) echo "未找到任何用户的 localconfig.vdf。" ;;
        patch_backup) echo "已创建备份:" ;;
        patch_done) echo "启动选项已设置为: sh ./cream.sh %command%" ;;
        patch_already) echo "启动选项已正确设置。" ;;
        patch_steam_running_warn) echo "警告: Steam 似乎正在运行。请在修改前后完全关闭 Steam，否则更改可能被覆盖。" ;;
        press_enter) echo "按 Enter 继续..." ;;
        enter_game_path) echo "请手动输入 Stellaris 游戏路径（直接按 Enter 跳过）: " ;;
        invalid_choice) echo "无效选择。" ;;
        lang_set) echo "语言已切换为中文。" ;;
        log_empty) echo "日志为空。" ;;
        confirm_install) echo "是否继续安装？[y/N]: " ;;
        cancelled) echo "已取消。" ;;
        no_dlc_to_download) echo "所有 DLC 均为最新。" ;;
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
    curl -sL --fail --retry 2 --connect-timeout 10 -A "StellarisDLCUnlocker-sh/1.0" "$1"
}

download_with_fallback() {
    local rel="$1" dest="$2" label="${3:-$1}"
    mkdir -p "$(dirname "$dest")"
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

    if [ "$added" -gt 0 ]; then
        log OK "$(t ini_updated) +$added"
    fi
}

download_dlc_content() {
    local dlc_dir="$GAME_DIR/dlc"
    mkdir -p "$dlc_dir"

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

patch_launch_options() {
    header
    echo -e "${C_BOLD}$(t patch_launch_header)${C_RESET}"
    hr

    if [ -z "$STEAM_DIR" ]; then
        find_steam_dir || { log ERROR "$(t steam_not_found)"; pause; return 1; }
    fi

    if pgrep -x steam >/dev/null 2>&1 || pgrep -f "com.valvesoftware.Steam" >/dev/null 2>&1; then
        log WARN "$(t patch_steam_running_warn)"
    fi

    local userdata_dir="$STEAM_DIR/userdata"
    if [ ! -d "$userdata_dir" ]; then
        log ERROR "$(t patch_userdata_not_found)"
        pause; return 1
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
            log OK "$(t patch_done)  ($user_dir)"
        else
            rm -f "$tmp"
            log WARN "AppID $APPID not found in $vdf (game never launched from this Steam account?)"
        fi
    done

    if [ "$patched_any" -eq 0 ]; then
        log ERROR "$(t patch_localconfig_not_found)"
    fi

    pause
}

do_install() {
    header
    echo -e "${C_BOLD}$(t m_install)${C_RESET}"
    hr

    find_steam_dir
    if [ -z "$STEAM_DIR" ]; then
        log ERROR "$(t steam_not_found)"
        pause; return 1
    fi
    log OK "$(t steam_found) $STEAM_DIR $([ "$IS_FLATPAK_STEAM" = 1 ] && t flatpak_steam)"

    find_game_dir
    if [ -z "$GAME_DIR" ]; then
        log WARN "$(t game_not_found)"
        ask "$(t enter_game_path)" manual_path
        if [ -n "$manual_path" ] && [ -d "$manual_path" ]; then
            GAME_DIR="$manual_path"
        else
            pause; return 1
        fi
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
    log OK "$(t install_done)"
    echo -e "${C_DIM}sh ./cream.sh %command%${C_RESET}"
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
    log OK "$(t lang_set)"
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

[ -f "$CONFIG_FILE" ] && LANGUAGE="$(cat "$CONFIG_FILE")"
check_deps
main_menu
