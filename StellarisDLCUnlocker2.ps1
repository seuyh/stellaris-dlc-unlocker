#Requires -Version 5.1
Set-StrictMode -Version 5.1
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

Add-Type @'
using System;
using System.Runtime.InteropServices;
namespace Picker {
    [ComImport, Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IShellItem {
        void BindToHandler(IntPtr pbc, [In] ref Guid bhid, [In] ref Guid riid, out IntPtr ppv);
        void GetParent(out IShellItem ppsi);
        void GetDisplayName(uint sigdn, [MarshalAs(UnmanagedType.LPWStr)] out string ppszName);
        void GetAttributes(uint mask, out uint attribs);
        void Compare(IShellItem psi, uint hint, out int order);
    }
    [ComImport, Guid("42F85136-DB7E-439C-85F1-E4075D135FC8"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IFileDialog {
        [PreserveSig] int Show(IntPtr hwnd);
        void SetFileTypes(uint c, IntPtr types);
        void SetFileTypeIndex(uint i);
        void GetFileTypeIndex(out uint i);
        void Advise(IntPtr sink, out uint cookie);
        void Unadvise(uint cookie);
        void SetOptions(uint fos);
        void GetOptions(out uint fos);
        void SetDefaultFolder(IShellItem psi);
        void SetFolder(IShellItem psi);
        void GetFolder(out IShellItem ppsi);
        void GetCurrentSelection(out IShellItem ppsi);
        void SetFileName([MarshalAs(UnmanagedType.LPWStr)] string name);
        void GetFileName([MarshalAs(UnmanagedType.LPWStr)] out string name);
        void SetTitle([MarshalAs(UnmanagedType.LPWStr)] string title);
        void SetOkButtonLabel([MarshalAs(UnmanagedType.LPWStr)] string text);
        void SetFileNameLabel([MarshalAs(UnmanagedType.LPWStr)] string label);
        void GetResult(out IShellItem ppsi);
        void AddPlace(IShellItem psi, int fdap);
        void SetDefaultExtension([MarshalAs(UnmanagedType.LPWStr)] string ext);
        void Close(int hr);
        void SetClientGuid([In] ref Guid guid);
        void ClearClientData();
        void SetFilter(IntPtr filter);
    }
    public static class FolderDialog {
        static readonly Guid CLSID = new Guid("DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7");
        [DllImport("shell32.dll", CharSet=CharSet.Unicode, PreserveSig=false)]
        static extern void SHCreateItemFromParsingName(string path, IntPtr pbc,
            [In] ref Guid riid, [MarshalAs(UnmanagedType.Interface)] out IShellItem ppv);
        public static string Pick(string title, string initial = null) {
            var dlg = (IFileDialog)Activator.CreateInstance(Type.GetTypeFromCLSID(CLSID));
            try {
                uint opts; dlg.GetOptions(out opts);
                dlg.SetOptions(opts | 0x20); // FOS_PICKFOLDERS
                dlg.SetTitle(title);
                if (!string.IsNullOrEmpty(initial)) {
                    try {
                        var iid = new Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE");
                        IShellItem si;
                        SHCreateItemFromParsingName(initial, IntPtr.Zero, ref iid, out si);
                        dlg.SetFolder(si);
                    } catch {}
                }
                if (dlg.Show(IntPtr.Zero) != 0) return null;
                IShellItem res; dlg.GetResult(out res);
                string path; res.GetDisplayName(0x80028000, out path);
                return path;
            } finally { Marshal.ReleaseComObject(dlg); }
        }
    }
}
'@

Add-Type -AssemblyName System.IO.Compression.FileSystem

$STELLARIS_APP_ID  = '281990'
$APP_DIR           = Join-Path $env:LOCALAPPDATA 'StellarisDLCUnlocker'
$CACHE_DIR         = Join-Path $APP_DIR 'cache'
$LOG_FILE          = Join-Path $APP_DIR 'unlocker.log'
$ORIGIN_API        = 'https://api.github.com/repos/seuyh/stellaris-dlc-unlocker/contents'

$GITHUB_DLC_URL      = 'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/dlc_data.json'
$GITHUB_HASHES_URL   = 'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/hashes.json'

$JSDELIVR_DLC_URL    = 'https://cdn.jsdelivr.net/gh/seuyh/stellaris-dlc-unlocker@main/dlc_data.json'
$JSDELIVR_HASHES_URL = 'https://cdn.jsdelivr.net/gh/seuyh/stellaris-dlc-unlocker@main/hashes.json'

$SERVER_URL        = 'pub-0f87be5fdd68492c8328b66998eb46ad.r2.dev'
$ALT_LAUNCHERS     = @('launcher-installer-windows_2024.14.msi', 'launcher-installer-windows_2024.13.msi', 'launcher-installer-windows_2024.8.msi')

$STEAMCMD_API      = 'https://api.steamcmd.net/v1/info'

New-Item -ItemType Directory -Path $APP_DIR, $CACHE_DIR -Force | Out-Null

$script:dlcData         = $null
$script:serverUrl       = $null
$script:altLauncher     = $null
$script:outdatedFolders = @()
$script:L               = $null
$script:curLang         = 'en'
$script:Q               = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

$BUILTIN = @{
    en = @{
        title='STELLARIS DLC UNLOCKER'; path_label='STELLARIS PATH'; lbl_launcher_path='LAUNCHER PATH'; browse='Browse'
        status_label='STATUS'; options_label='OPTIONS'
        chk_full='Full reinstall (deletes saves and settings)'
        chk_skip='Skip Paradox Launcher reinstall'
        chk_no_update='Disable launcher auto-update (recommended)'
        confirm_no_update='Launcher auto-update may break DLC unlock functionality. Disable anyway?'
        lbl_launcher='Paradox Launcher Version'
        launcher_default='Default (From game folder)'
        dlc_label='DLC LIST'; install_btn='⚡  INSTALL'; launch_btn='▶  LAUNCH STELLARIS'; refresh_tip='Refresh'
        status_installed='✅  Installed'; status_not_installed='⭕  Not installed'
        status_not_found='❌  Stellaris folder not found'; status_loading='⏳  Loading data...'
        err_no_exe='stellaris.exe not found in selected folder.'
        err_loading='Server data is still loading. Please wait.'
        err_title='Error'; warn_title='Warning'; wait_title='Please wait'; confirm_title='Confirm'
        confirm_full='This will delete ALL Stellaris saves and settings. Continue?'
        dlc_ok='OK'; dlc_old='Outdated'; dlc_missing='Missing'
    }
    ru = @{
        title='STELLARIS DLC UNLOCKER'; path_label='ПУТЬ К STELLARIS'; lbl_launcher_path='ПУТЬ К ЛАУНЧЕРУ'; browse='Обзор'
        status_label='СТАТУС'; options_label='ОПЦИИ'
        chk_full='Полная переустановка (удалит сохранения и настройки)'
        chk_skip='Пропустить переустановку Paradox Launcher'
        chk_no_update='Отключить авто-обновление лаунчера (рекомендуется)'
        confirm_no_update='Авто-обновление лаунчера может нарушить работу разблокировки DLC. Всё равно отключить?'
        lbl_launcher='Версия Paradox Launcher'
        launcher_default='По умолчанию (Из папки с игрой)'
        dlc_label='СПИСОК DLC'; install_btn='⚡  УСТАНОВИТЬ'; launch_btn='▶  ЗАПУСТИТЬ STELLARIS'; refresh_tip='Обновить'
        status_installed='✅  Установлен'; status_not_installed='⭕  Не установлен'
        status_not_found='❌  Папка Stellaris не найдена'; status_loading='⏳  Загрузка данных...'
        err_no_exe='stellaris.exe не найден в указанной папке.'
        err_loading='Данные сервера ещё загружаются. Подождите.'
        err_title='Ошибка'; warn_title='Предупреждение'; wait_title='Подождите'; confirm_title='Подтверждение'
        confirm_full='Это удалит ВСЕ сохранения и настройки Stellaris. Продолжить?'
        dlc_ok='OK'; dlc_old='Устарел'; dlc_missing='Отсутствует'
    }
    zh = @{
        title='STELLARIS DLC UNLOCKER'; path_label='STELLARIS 路径'; lbl_launcher_path='启动器路径'; browse='浏览'
        status_label='状态'; options_label='选项'
        chk_full='完整重装（将删除存档和设置）'; chk_skip='跳过 Paradox Launcher 重装'
        chk_no_update='禁用启动器自动更新（推荐）'
        confirm_no_update='启动器自动更新可能导致 DLC 解锁功能异常。仍要禁用吗？'
        lbl_launcher='Paradox Launcher 版本'
        launcher_default='默认 (来自游戏目录)'
        dlc_label='DLC 列表'; install_btn='⚡  安装'; launch_btn='▶  启动 STELLARIS'; refresh_tip='刷新'
        status_installed='✅  已安装'; status_not_installed='⭕  未安装'
        status_not_found='❌  未找到 Stellaris 目录'; status_loading='⏳  正在加载数据...'
        err_no_exe='在所选文件夹中未找到 stellaris.exe。'
        err_loading='服务器数据仍在加载中，请稍候。'
        err_title='错误'; warn_title='警告'; wait_title='请稍候'; confirm_title='确认'
        confirm_full='这将删除所有 Stellaris 存档和设置。是否继续？'
        dlc_ok='OK'; dlc_old='已过时'; dlc_missing='缺失'
    }
}

function Write-Log([string]$msg, [string]$level = 'INFO') {
    Add-Content -Path $LOG_FILE -Value "[$(Get-Date -Format 'HH:mm:ss')][$level] $msg" -Encoding UTF8 -ErrorAction SilentlyContinue
}
function T([string]$key) { if ($script:L -and $script:L.ContainsKey($key)) { return $script:L[$key] }; return $key }
function Get-SystemLang {
    $ui = [System.Globalization.CultureInfo]::CurrentUICulture.Name.ToLower()
    if ($ui.StartsWith('ru')) { return 'ru' }
    if ($ui.StartsWith('zh')) { return 'zh' }
    return 'en'
}
function Set-LangBuiltin([string]$lang) {
    $script:curLang = $lang
    $script:L = if ($BUILTIN.ContainsKey($lang)) { $BUILTIN[$lang] } else { $BUILTIN['en'] }
}
function Find-SteamPath {
    foreach ($h in 'HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam') {
        $prop = Get-ItemProperty $h -ErrorAction SilentlyContinue
        $v = if ($null -ne $prop) { $prop.SteamPath } else { $null }
        if ($v -and (Test-Path $v)) { return $v }
    }
    foreach ($d in "$env:ProgramFiles(x86)\Steam","$env:ProgramFiles\Steam") { if (Test-Path $d) { return $d } }
    return $null
}
function Find-StellarisPath([string]$steamPath) {
    if (-not $steamPath) { return $null }
    $roots = @($steamPath)
    $vdf = Join-Path $steamPath 'steamapps\libraryfolders.vdf'
    if (Test-Path $vdf) {
        [regex]::Matches((Get-Content $vdf -Raw -ErrorAction SilentlyContinue), '"path"\s+"([^"]+)"') | ForEach-Object {
            $p = $_.Groups[1].Value -replace '\\\\','\'
            if (Test-Path $p) { $roots += $p }
        }
    }
    foreach ($r in $roots) { $c = Join-Path $r 'steamapps\common\Stellaris'; if (Test-Path $c) { return $c } }
    return $null
}
function Get-InstallStatus([string]$gp) {
    if ([string]::IsNullOrWhiteSpace($gp)) { return 'not_found' }
    try {
        if (-not (Test-Path (Join-Path $gp 'stellaris.exe'))) { return 'not_found' }
        if (Test-Path (Join-Path $gp 'cream_api.ini'))        { return 'installed' }
        return 'not_installed'
    } catch { return 'not_found' }
}
function Start-PSRunspace([scriptblock]$scr, [hashtable]$vars) {
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = [System.Threading.ApartmentState]::STA
    $rs.ThreadOptions  = [System.Management.Automation.Runspaces.PSThreadOptions]::UseNewThread
    $rs.Open()
    foreach ($kv in $vars.GetEnumerator()) { $rs.SessionStateProxy.SetVariable($kv.Key, $kv.Value) }
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs; $ps.AddScript($scr) | Out-Null; $ps.BeginInvoke() | Out-Null
}

$BG_COMMON = {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    function _Log([string]$msg, [string]$lvl='INFO') {
        $_Q.Enqueue([pscustomobject]@{ t='log'; msg="[$(Get-Date -Format 'HH:mm:ss')] $msg"; lvl=$lvl })
    }
    function _Http([string]$url) {
        $wc = [System.Net.WebClient]::new(); $wc.Headers.Add('User-Agent','StellarisDLCUnlocker-PS/1.0')
        try { return $wc.DownloadString($url) } finally { $wc.Dispose() }
    }
    function _Json([string]$url) { return (_Http $url) | ConvertFrom-Json }

    function _DownloadFile([string]$url, [string]$dest, [string]$label) {
        $req = [System.Net.HttpWebRequest]::Create($url)
        $req.UserAgent = 'Mozilla/5.0'
        $req.Timeout   = 30000
        $resp      = $req.GetResponse()
        $total     = $resp.ContentLength
        $stream    = $resp.GetResponseStream()
        $fs        = [System.IO.File]::OpenWrite($dest)
        $buf       = New-Object byte[] 65536
        $downloaded = 0L
        $startT    = [DateTime]::Now
        try {
            while ($true) {
                $read = $stream.Read($buf, 0, $buf.Length)
                if ($read -le 0) { break }
                $fs.Write($buf, 0, $read)
                $downloaded += $read
                $el  = ([DateTime]::Now - $startT).TotalSeconds
                $spd = if ($el -gt 0) { [Math]::Round($downloaded/1MB/$el,1) } else { 0 }
                $pct = if ($total -gt 0) { [Math]::Min(100,[int]($downloaded*100/$total)) } else { 0 }
                $_Q.Enqueue([pscustomobject]@{ t='progress'; pfile=$pct; speed="${spd} MB/s"; cur=$label })
            }
        } finally { $fs.Close(); $stream.Close(); $resp.Close() }
    }

    function _GetLauncherBase {
        $h   = "C:\Users\$env:USERNAME"
        $reg = try { (Get-ItemProperty 'HKCU:\Software\Paradox Interactive\Paradox Launcher v2' -ErrorAction Stop).LauncherInstallation } catch { $null }
        if ($reg -and [System.IO.Path]::GetPathRoot($reg+'') -ne $reg -and (Test-Path $reg)) { return $reg }
        return "$h\AppData\Local\Programs\Paradox Interactive\launcher"
    }
    function _GetLauncherDataFolders {
        $h   = "C:\Users\$env:USERNAME"
        $lp2 = try { (Get-ItemProperty 'HKCU:\Software\Paradox Interactive\Paradox Launcher v2' -ErrorAction Stop).LauncherPathFolder } catch { $null }
        if (-not $lp2 -or [System.IO.Path]::GetPathRoot($lp2+'') -eq $lp2) { $lp2 = "$h\AppData\Local\Paradox Interactive" }
        return @($lp2, "$h\AppData\Roaming\Paradox Interactive", "$h\AppData\Roaming\paradox-launcher-v2")
    }
}

$INIT_SCRIPT = [scriptblock]::Create($BG_COMMON.ToString() + @'

    _Log "Fetching DLC list from GitHub..."
    $dlc = $null
    try { $dlc = _Json $_GDLC; _Log "DLC data loaded from GitHub." 'OK' }
    catch {
        _Log "GitHub DLC failed, trying jsDelivr..." 'WARN'
        try { $dlc = _Json $_GDLC_FALL; _Log "DLC data loaded from jsDelivr." 'OK' }
        catch { _Log "Both GitHub and jsDelivr failed for DLC data." 'ERROR' }
    }
    if ($dlc) { $_Q.Enqueue([pscustomobject]@{ t='dlc_data'; data=$dlc }) }

    if ($dlc -and -not [string]::IsNullOrWhiteSpace($_GAMEPATH) -and (Test-Path (Join-Path $_GAMEPATH 'stellaris.exe'))) {
        _Log "Checking file integrity via hashes.json..."
        try {
            $hashJson = $null
            try { $hashJson = _Json $_GHASH }
            catch { _Log "GitHub hashes failed, trying jsDelivr..." 'WARN'; $hashJson = _Json $_GHASH_FALL }

            $out = @()
            $md5 = [System.Security.Cryptography.MD5]::Create()
            foreach ($prop in $hashJson.PSObject.Properties) {
                $relPath = $prop.Name -replace '/','\'
                $expected = $prop.Value
                $fld = ($relPath -split '\\')[0]
                $loc = Join-Path $_GAMEPATH "dlc\$relPath"

                if (Test-Path $loc) {
                    $s = [System.IO.File]::OpenRead($loc)
                    $h = ([System.BitConverter]::ToString($md5.ComputeHash($s)) -replace '-','').ToLower()
                    $s.Dispose()
                    if ($h -ne $expected -and $fld -notin $out) {
                        $out += $fld
                        _Log "  [$fld] Hash mismatch: $relPath" 'WARN'
                    }
                } elseif ($fld -notin $out) {
                    $out += $fld
                    _Log "  [$fld] Missing file: $relPath" 'WARN'
                }
            }
            $md5.Dispose()
            $_Q.Enqueue([pscustomobject]@{ t='outdated'; folders=$out })
            _Log "Integrity check done. Outdated/Missing DLCs: $($out.Count)." 'OK'
        } catch { _Log "Integrity check failed: $($_.Exception.Message)" 'WARN' }
    }

    _Log "Checking GitHub connection..."
    $ghOk = $false
    try { _Http 'https://api.github.com/repos/seuyh/stellaris-dlc-unlocker' | Out-Null; $ghOk=$true; _Log "GitHub: reachable." 'OK' }
    catch { _Log "GitHub unreachable: $($_.Exception.Message)" 'WARN' }
    $_Q.Enqueue([pscustomobject]@{ t='dot_gh'; ok=$ghOk })

    $srvOk = $false
    if ($_SERVERURL -and $_ALTLAUNCHERS.Count -gt 0) {
        _Log "Checking server connection..."
        try {
            $req = [System.Net.WebRequest]::Create("https://$_SERVERURL/unlocker/$($_ALTLAUNCHERS[0])")
            $req.Method = "HEAD"
            $req.Timeout = 3000
            $resp = $req.GetResponse()
            $resp.Close()
            $srvOk = $true
            _Log "Server: reachable." 'OK'
        } catch { _Log "Server unreachable: $($_.Exception.Message)" 'WARN' }
    }
    $_Q.Enqueue([pscustomobject]@{ t='dot_srv'; ok=$srvOk })
    _Log "Initialization complete." 'OK'
    $_Q.Enqueue([pscustomobject]@{ t='init_done' })
'@)

$INSTALL_SCRIPT = [scriptblock]::Create($BG_COMMON.ToString() + @'
    function _FileLog([string]$msg, [string]$lvl='INFO') {
        try { Add-Content -Path $_LOG_FILE -Value "[$(Get-Date -Format 'HH:mm:ss')][$lvl] $msg" -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
    }
    try {
    _Log "▶ Installation started."
    _Log "  Game folder: $_GAMEPATH"
    _Log "  Server: $_SERVERURL"
    _FileLog "▶ Installation started. Game: $_GAMEPATH  Server: $_SERVERURL"

    foreach ($p in @('stellaris','Paradox Launcher')) {
        try { Get-Process -Name $p -ErrorAction Stop | Stop-Process -Force; _Log "  Killed process: $p" 'WARN' } catch {}
    }

    _Log "  Removing stellaris.exe compatibility flags..."
    try {
        $regPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
        $exePath = Join-Path $_GAMEPATH 'stellaris.exe'
        if (Test-Path $regPath) {
            $prop = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            if ($prop -and $prop.PSObject.Properties.Name -contains $exePath) {
                Remove-ItemProperty -Path $regPath -Name $exePath -Force -ErrorAction SilentlyContinue
                _Log "  Compat flags removed." 'OK'
            } else { _Log "  No compat flags found on stellaris.exe." }
        }
    } catch { _Log "  Could not remove compat flags: $($_.Exception.Message)" 'WARN' }

    if ($_FULL) {
        _Log "  Full reinstall: removing Paradox Interactive Stellaris documents..." 'WARN'
        $doc = "C:\Users\$env:USERNAME\Documents\Paradox Interactive\Stellaris"
        if (Test-Path $doc) { Remove-Item $doc -Recurse -Force; _Log "  Removed: $doc" 'OK' }
        $dd = Join-Path $_GAMEPATH 'dlc'
        if (Test-Path $dd) { Remove-Item $dd -Recurse -Force; _Log "  Removed dlc\ folder." 'OK' }
    }

    $altPath = $null
    if ($_ALT -and $_ALTNAME -and $_SERVERURL) {
        _Log "⬇ Downloading alternative launcher..."
        $altPath = Join-Path $_CACHE_DIR $_ALTNAME
        if (-not (Test-Path $altPath)) {
            _DownloadFile "https://$_SERVERURL/unlocker/$_ALTNAME" $altPath $_ALTNAME
            _Log "  Alt launcher downloaded." 'OK'
        } else { _Log "  Alt launcher cached: $_ALTNAME" 'OK' }
    }

    New-Item -ItemType Directory -Path (Join-Path $_GAMEPATH 'dlc') -Force | Out-Null

    _Log "⬇ Syncing creamapi files from repo..."
    $steamCache  = Join-Path $_CACHE_DIR 'creamapi_steam_files'
    $launchCache = Join-Path $_CACHE_DIR 'creamapi_launcher_files'

    $fallbackFiles = @{
        'creamapi_steam_files' = @('Emulator64.dll', 'LinkNeverDie_Com_64.dll', 'SWLoader.txt', 'SWconfig.ini', 'cream_api.ini', 'steam_api64_org_game.dll', 'steam_api64_org_launcher.dll')
        'creamapi_launcher_files' = @('cream_api.ini', 'sdkencryptedappticket64.dll', 'steam_api64.dll', 'steam_api64_o.dll')
    }

    foreach ($pair in @(@{sub='creamapi_steam_files';dest=$steamCache},@{sub='creamapi_launcher_files';dest=$launchCache})) {
        New-Item -ItemType Directory -Path $pair.dest -Force | Out-Null
        $useJsDelivr = $false

        try {
            $wc2 = [System.Net.WebClient]::new(); $wc2.Headers.Add('User-Agent','StellarisDLCUnlocker-PS/1.0')
            $items = ($wc2.DownloadString("$_ORIGIN_API/$($pair.sub)") | ConvertFrom-Json)
            foreach ($item in $items) {
                if ($item.type -eq 'file') {
                    $dest2 = Join-Path $pair.dest $item.name
                    $hashFile = "$dest2.sha"
                    if (-not ((Test-Path $dest2) -and (Test-Path $hashFile) -and ((Get-Content $hashFile -Raw).Trim() -eq $item.sha))) {
                        $wc3 = [System.Net.WebClient]::new(); $wc3.Headers.Add('User-Agent','StellarisDLCUnlocker-PS/1.0')
                        $wc3.DownloadFile($item.download_url, $dest2); $wc3.Dispose()
                        $item.sha | Out-File -FilePath $hashFile -Encoding ascii -Force
                        _Log "  OK (GitHub): $($item.name)" 'OK'
                    }
                }
            }
            $wc2.Dispose()
        } catch {
            _Log "  GitHub API timeout/error, switching to jsDelivr for $($pair.sub)..." 'WARN'
            $useJsDelivr = $true
        }

        if ($useJsDelivr) {
            $baseUrl = "https://cdn.jsdelivr.net/gh/seuyh/stellaris-dlc-unlocker@main/$($pair.sub)"

            $manifest = $null
            try {
                $wc4 = [System.Net.WebClient]::new()
                $wc4.Headers.Add('User-Agent','StellarisDLCUnlocker-PS/1.0')
                $manifest = ($wc4.DownloadString("$baseUrl/manifest.json") | ConvertFrom-Json)
                $wc4.Dispose()
            } catch {
                _Log "  No manifest.json via jsDelivr for $($pair.sub), will re-download all." 'WARN'
            }

            foreach ($f in $fallbackFiles[$pair.sub]) {
                $dest2    = Join-Path $pair.dest $f
                $hashFile = "$dest2.sha"

                $remoteSha   = if ($manifest) { ($manifest | Where-Object { $_.name -eq $f }).sha } else { $null }
                $needDownload = $true
                if ($remoteSha -and (Test-Path $dest2) -and (Test-Path $hashFile) -and
                    ((Get-Content $hashFile -Raw).Trim() -eq $remoteSha)) {
                    $needDownload = $false
                }

                if ($needDownload) {
                    try {
                        $wc3 = [System.Net.WebClient]::new()
                        $wc3.Headers.Add('User-Agent','StellarisDLCUnlocker-PS/1.0')
                        $wc3.DownloadFile("$baseUrl/$f", $dest2)
                        $wc3.Dispose()
                        if ($remoteSha) { $remoteSha | Out-File -FilePath $hashFile -Encoding ascii -Force }
                        _Log "  OK (jsDelivr): $f" 'OK'
                    } catch {
                        _Log "  Failed to download via jsDelivr: $f" 'ERROR'
                    }
                } else {
                    _Log "  Cached (jsDelivr): $f" 'OK'
                }
            }
        }
    }
    _Log "⬇ Syncing creamapi_launcher_files from repo... done."

    _Log "🔄 Updating cream_api.ini via steamcmd..."
    foreach ($iniPath in @((Join-Path $steamCache 'cream_api.ini'),(Join-Path $launchCache 'cream_api.ini'))) {
        if (-not (Test-Path $iniPath)) { continue }
        try {
            $req = [System.Net.HttpWebRequest]::Create("$_STEAMCMD_API/$_APPID")
            $req.Timeout = 2500
            $req.ReadWriteTimeout = 2500
            $resp = $req.GetResponse()
            $stream = $resp.GetResponseStream()
            $reader = [System.IO.StreamReader]::new($stream)
            $data = ($reader.ReadToEnd() | ConvertFrom-Json)
            $reader.Dispose(); $stream.Dispose(); $resp.Dispose()

            $csv = $data.data."$_APPID".extended.listofdlc
            if ($csv) {
                $exist = Get-Content $iniPath -Raw
                $fs = [System.IO.File]::Open($iniPath,[System.IO.FileMode]::Append,[System.IO.FileAccess]::Write)
                $sw = [System.IO.StreamWriter]::new($fs,[System.Text.Encoding]::UTF8); $added = 0
                if ($exist -and -not $exist.EndsWith("`n")) { $sw.WriteLine() }

                foreach ($id in ($csv -split ',')) {
                    $id = $id.Trim(); if (-not $id -or $exist -match $id) { continue }
                    $name = $id
                    try {
                        $req2 = [System.Net.HttpWebRequest]::Create("$_STEAMCMD_API/$id")
                        $req2.Timeout = 1500; $req2.ReadWriteTimeout = 1500
                        $resp2 = $req2.GetResponse()
                        $reader2 = [System.IO.StreamReader]::new($resp2.GetResponseStream())
                        $name = ($reader2.ReadToEnd() | ConvertFrom-Json).data."$id".common.name
                        $reader2.Dispose(); $resp2.Close()
                    } catch {}
                    $sw.WriteLine("$id = $name"); $added++
                }
                $sw.Dispose(); $fs.Dispose()
                if ($added -gt 0) { _Log "  cream_api.ini updated: +$added DLC." 'OK' }
            }
        } catch {
            _Log "  SteamCMD is currently unavailable, skipped update." 'WARN'
        }
    }

    $dlcDir = Join-Path $_GAMEPATH 'dlc'; $queue = @(); $total = 0
    foreach ($dlc in $_DLCDATA) {
        $f = $dlc.dlc_folder; if (-not $f) { continue }; $total++
        $zip = Join-Path $dlcDir "$f.zip"; $dir = Join-Path $dlcDir $f
        if (Test-Path $dir) {
            if ($f -in $_OUTDATED) {
                _Log "  Removing outdated DLC for re-download: $f" 'WARN'
                Remove-Item $dir -Recurse -Force
            } else { continue }
        }
        if (Test-Path $zip) { try { [System.IO.Compression.ZipFile]::OpenRead($zip).Dispose(); continue } catch { Remove-Item $zip -Force } }
        $queue += @{ folder=$f; zip=$zip; url="https://$_SERVERURL/unlocker/$f.zip" }
    }

    _Log "📦 To download: $($queue.Count) of $total DLC"
    $doneD = 0
    foreach ($item in $queue) {
        _Log "⬇ [$($doneD+1)/$($queue.Count)] $($item.folder)"
        $_Q.Enqueue([pscustomobject]@{ t='cur'; text=$item.folder })
        _DownloadFile $item.url $item.zip $item.folder
        $doneD++
        $_Q.Enqueue([pscustomobject]@{ t='pbar'; val=[Math]::Round($doneD/$queue.Count*100) })
        _Log "  Downloaded: $($item.folder)" 'OK'
    }

    _Log "📂 Unpacking archives..."
    foreach ($z in (Get-ChildItem $dlcDir -Filter '*.zip' -ErrorAction SilentlyContinue)) {
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($z.FullName,$dlcDir)
            Remove-Item $z.FullName -Force
            _Log "  Unpacked: $($z.BaseName)" 'OK'
        } catch { _Log "  Unzip error $($z.Name): $($_.Exception.Message)" 'ERROR' }
    }

    if (-not $_SKIP) {
        _Log "🔧 Reinstalling Paradox Launcher..."
        $msiPath = $null
        if ($altPath -and (Test-Path $altPath)) {
            $msiPath = $altPath
            _Log "  Using alt launcher: $(Split-Path $msiPath -Leaf)"
        } else {
            $msiFiles = @(Get-ChildItem $_GAMEPATH -Filter 'launcher-installer-windows*.msi' -ErrorAction SilentlyContinue)
            if ($msiFiles.Count -gt 0) {
                $msiPath = ($msiFiles | Sort-Object {
                    if ($_.Name -match 'launcher-installer-windows[_.](\d+)[._](\d+)') {
                        [long]("$($Matches[1])$($Matches[2].PadLeft(6,'0'))")
                    } else { 0L }
                } -Descending)[0].FullName
                _Log "  MSI selected (latest): $(Split-Path $msiPath -Leaf)"
                if ($msiFiles.Count -gt 1) { _Log "  ($($msiFiles.Count) MSI files found, using newest)" 'WARN' }
            }
        }
        if ($msiPath) {
            $launcherBase = _GetLauncherBase
            foreach ($lp in @($launcherBase) + (_GetLauncherDataFolders)) {
                if ($lp -and (Test-Path $lp)) {
                    try { Remove-Item $lp -Recurse -Force; _Log "  Removed: $lp" }
                    catch { _Log "  Could not remove $lp" 'WARN' }
                }
            }
            _Log "  Running msiexec /uninstall..."
            $psi = [System.Diagnostics.ProcessStartInfo]::new('msiexec.exe', "/uninstall `"$msiPath`" /quiet /norestart")
            $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden; $psi.CreateNoWindow = $true
            $proc = [System.Diagnostics.Process]::Start($psi); $proc.WaitForExit()
            Start-Sleep -Seconds 1
            _Log "  Running msiexec /package..."
            $psi2 = [System.Diagnostics.ProcessStartInfo]::new('msiexec.exe', "/package `"$msiPath`" /quiet /norestart CREATE_DESKTOP_SHORTCUT=0")
            $psi2.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden; $psi2.CreateNoWindow = $true
            $proc2 = [System.Diagnostics.Process]::Start($psi2); $proc2.WaitForExit()
            _Log "  Launcher reinstalled." 'OK'
        } else { _Log "  No MSI found in game folder — skipping launcher reinstall." 'WARN' }
    } else { _Log "  Launcher reinstall skipped." }

    _Log "📋 Patching launcher folders..."
    $launcherBase = if (-not [string]::IsNullOrWhiteSpace($_LAUNCHERPATH) -and (Test-Path $_LAUNCHERPATH)) {
    $_LAUNCHERPATH
    } else {
        _Log "  Launcher path not set or not found, trying auto-detect..." 'WARN'
        _GetLauncherBase
    }
    _Log "  Launcher base: $launcherBase"
    if (Test-Path $launcherBase) {
        $lFolders = @(Get-ChildItem $launcherBase -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'launcher*' })
        _Log "  Found $($lFolders.Count) launcher folder(s)."
        foreach ($lf in $lFolders) {
            _Log "  Processing: $($lf.Name)"
            if ($_NO_UPDATE) {
                $xd = Join-Path $lf.FullName 'xdelta3.exe'
                if (Test-Path $xd) { Remove-Item $xd -Force; _Log "    Removed xdelta3.exe (auto-update disabled)." 'OK' }
            }
            $t1 = Join-Path $lf.FullName 'resources\app.asar.unpacked\node_modules\greenworks\lib'
            $t2 = Join-Path $lf.FullName 'resources\app\dist\main'
            $tgt = if (Test-Path $t1) { $t1 } elseif (Test-Path $t2) { $t2 } else { $null }
            if ($tgt) { Copy-Item "$launchCache\*" $tgt -Recurse -Force; _Log "    Patched: $tgt" 'OK' }
            else { _Log "    No patchable resources folder found." 'WARN' }
        }
    } else { _Log "  Launcher base not found: $launcherBase" 'WARN' }

    _Log "📋 Copying CreamAPI steam files to game folder..."
    Copy-Item "$steamCache\*" $_GAMEPATH -Recurse -Force
    _Log "  Steam files copied." 'OK'
    $_Q.Enqueue([pscustomobject]@{ t='speed_reset' })
    _Log ''
    _Log "✅ Done! Launch Stellaris via Steam." 'OK'
    _FileLog "✅ Installation completed successfully."
    $_Q.Enqueue([pscustomobject]@{ t='install_done' })

    } catch {
        $errMsg = "❌ Unhandled error: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
        _Log $errMsg 'ERROR'
        _FileLog $errMsg 'ERROR'
        $_Q.Enqueue([pscustomobject]@{ t='install_done' })
    }
'@)

[xml]$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Stellaris DLC Unlocker"
    Width="720" Height="900" MinWidth="600" MinHeight="820"
    WindowStartupLocation="CenterScreen" Background="#12121f" FontFamily="Segoe UI">
    <Window.Resources>
        <Style x:Key="Card" TargetType="Border">
            <Setter Property="Background" Value="#1c1c30"/><Setter Property="CornerRadius" Value="8"/>
            <Setter Property="Padding" Value="14"/><Setter Property="Margin" Value="0,0,0,10"/>
        </Style>
        <Style x:Key="SL" TargetType="TextBlock">
            <Setter Property="Foreground" Value="#55557a"/><Setter Property="FontSize" Value="10"/>
            <Setter Property="FontWeight" Value="Bold"/><Setter Property="Margin" Value="0,0,0,4"/>
        </Style>
        <Style x:Key="BB" TargetType="Button">
            <Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Opacity" Value="0.8"/></Trigger>
                            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="bd" Property="Opacity" Value="0.3"/></Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="BG"  TargetType="Button" BasedOn="{StaticResource BB}"><Setter Property="Background" Value="#1a7a3a"/><Setter Property="Padding" Value="22,9"/></Style>
        <Style x:Key="BLu" TargetType="Button" BasedOn="{StaticResource BB}"><Setter Property="Background" Value="#1a4a9a"/><Setter Property="Padding" Value="22,9"/></Style>
        <Style x:Key="BGh" TargetType="Button" BasedOn="{StaticResource BB}"><Setter Property="Background" Value="#2a2a45"/><Setter Property="Padding" Value="12,9"/></Style>
        <Style x:Key="BLng" TargetType="Button" BasedOn="{StaticResource BB}"><Setter Property="Background" Value="#2a2a45"/><Setter Property="Padding" Value="8,4"/><Setter Property="FontSize" Value="11"/></Style>
        <Style x:Key="CK" TargetType="CheckBox">
            <Setter Property="Foreground" Value="#8888aa"/><Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="0,4,0,0"/><Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style x:Key="DI" TargetType="ListBoxItem">
            <Setter Property="Padding" Value="6,2"/><Setter Property="Background" Value="Transparent"/><Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ListBoxItem">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="3" Padding="{TemplateBinding Padding}"><ContentPresenter/></Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="#22224a"/></Trigger>
                            <Trigger Property="IsSelected"  Value="True"><Setter TargetName="bd" Property="Background" Value="#22224a"/></Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="LI" TargetType="ListBoxItem">
            <Setter Property="Padding" Value="0,1"/><Setter Property="Background" Value="Transparent"/><Setter Property="BorderThickness" Value="0"/>
        </Style>
        <Style x:Key="CBx" TargetType="ComboBox">
        <Setter Property="Background"           Value="#1c1c30"/>
        <Setter Property="Foreground"           Value="#c8d6f0"/>
        <Setter Property="BorderBrush"          Value="#2a2a45"/>
        <Setter Property="BorderThickness"      Value="1"/>
        <Setter Property="Padding"              Value="6,4"/>
        <Setter Property="FontSize"             Value="11"/>
        <Setter Property="Cursor"               Value="Hand"/>
        <Setter Property="ItemContainerStyle">
            <Setter.Value>
                <Style TargetType="ComboBoxItem">
                    <Setter Property="Background" Value="#1c1c30"/>
                    <Setter Property="Foreground" Value="#c8d6f0"/>
                    <Setter Property="Padding"    Value="8,5"/>
                    <Style.Triggers>
                        <Trigger Property="IsMouseOver"  Value="True">
                            <Setter Property="Background" Value="#2a2a45"/>
                        </Trigger>
                        <Trigger Property="IsSelected"   Value="True">
                            <Setter Property="Background" Value="#1a5a9a"/>
                            <Setter Property="Foreground" Value="White"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
            </Setter.Value>
        </Setter>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="ComboBox">
                    <Grid>
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="24"/>
                                </Grid.ColumnDefinitions>
                                <ContentPresenter Grid.Column="0"
                                    Content="{TemplateBinding SelectionBoxItem}"
                                    ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                    Margin="{TemplateBinding Padding}"
                                    VerticalAlignment="Center"/>
                                <TextBlock Grid.Column="1" Text="▾" Foreground="#55557a"
                                           VerticalAlignment="Center" HorizontalAlignment="Center" FontSize="10"/>
                            </Grid>
                        </Border>
                        <Popup x:Name="PART_Popup" Placement="Bottom"
                       AllowsTransparency="True" Focusable="False"
                       IsOpen="{TemplateBinding IsDropDownOpen}"
                       PlacementTarget="{Binding RelativeSource={RelativeSource TemplatedParent}}">
                    <Border Background="#1c1c30" BorderBrush="#2a2a45" BorderThickness="1" CornerRadius="4"
                            MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource AncestorType=ComboBox}}"
                            HorizontalAlignment="Right">
                        <ScrollViewer MaxHeight="200">
                            <ItemsPresenter/>
                        </ScrollViewer>
                    </Border>
                    </Popup>
                        <ToggleButton Focusable="False" IsChecked="{Binding IsDropDownOpen, RelativeSource={RelativeSource TemplatedParent}}"
                                      Opacity="0"/>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    </Window.Resources>
    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="170"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,14">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0" HorizontalAlignment="Center">
                <TextBlock x:Name="TitleLbl" Foreground="#4d8fd4" FontSize="22" FontWeight="Bold" HorizontalAlignment="Center"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,6,0,0">
                    <StackPanel Orientation="Horizontal" Margin="0,0,16,0">
                        <Ellipse x:Name="DotGH"  Width="8" Height="8" Fill="#333355" Margin="0,0,5,0" VerticalAlignment="Center"/>
                        <TextBlock Text="GitHub" Foreground="#55557a" FontSize="11"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal">
                        <Ellipse x:Name="DotSrv" Width="8" Height="8" Fill="#333355" Margin="0,0,5,0" VerticalAlignment="Center"/>
                        <TextBlock Text="Server" Foreground="#55557a" FontSize="11"/>
                    </StackPanel>
                </StackPanel>
            </StackPanel>
            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Top">
                <Button x:Name="BtnEn" Content="EN" Style="{StaticResource BLng}" Margin="0,0,4,0"/>
                <Button x:Name="BtnRu" Content="RU" Style="{StaticResource BLng}" Margin="0,0,4,0"/>
                <Button x:Name="BtnZh" Content="ZH" Style="{StaticResource BLng}"/>
            </StackPanel>
        </Grid>

        <Border Grid.Row="1" Style="{StaticResource Card}">
            <StackPanel>
                <TextBlock x:Name="LblPath" Style="{StaticResource SL}"/>
                <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox x:Name="PathBox" Grid.Column="0" Background="#12121f" BorderBrush="#2a2a45" BorderThickness="1"
                             Foreground="#c8d6f0" FontSize="12" Padding="8,6" VerticalContentAlignment="Center"/>
                    <Button x:Name="BrowseBtn" Grid.Column="1" Style="{StaticResource BGh}" Margin="8,0,0,0" FontSize="11"/>
                </Grid>
            </StackPanel>
        </Border>

        <Border Grid.Row="2" Style="{StaticResource Card}">
            <StackPanel>
                <TextBlock x:Name="LblStatus" Style="{StaticResource SL}"/>
                <TextBlock x:Name="StatusLbl" Foreground="#f0a030" FontSize="13" FontWeight="SemiBold"/>
            </StackPanel>
        </Border>

        <Border Grid.Row="3" Style="{StaticResource Card}">
            <StackPanel>
                <TextBlock x:Name="LblOpts" Style="{StaticResource SL}"/>
                <CheckBox x:Name="ChkFull" Style="{StaticResource CK}"/>
                <CheckBox x:Name="ChkSkip" Style="{StaticResource CK}"/>
                <CheckBox x:Name="ChkNoUpdate" Style="{StaticResource CK}" IsChecked="True"/>
                <TextBlock x:Name="LblLauncher" Style="{StaticResource SL}" Margin="0,10,0,0"/>
                <ComboBox x:Name="CmbLauncher" Style="{StaticResource CBx}"/>
                <TextBlock x:Name="LblLauncherPath" Style="{StaticResource SL}" Margin="0,10,0,0"/>
                <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox x:Name="LauncherPathBox" Grid.Column="0" Background="#12121f" BorderBrush="#2a2a45" BorderThickness="1"
                             Foreground="#c8d6f0" FontSize="11" Padding="8,6" VerticalContentAlignment="Center"/>
                    <Button x:Name="LauncherBrowseBtn" Grid.Column="1" Style="{StaticResource BGh}" Margin="8,0,0,0" FontSize="11"/>
                </Grid>
            </StackPanel>
        </Border>

        <Border Grid.Row="4" Style="{StaticResource Card}" Margin="0,0,0,10">
            <Grid>
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                <Grid Grid.Row="0" Margin="0,0,0,6">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBlock x:Name="LblDlc" Grid.Column="0" Style="{StaticResource SL}" VerticalAlignment="Center" Margin="0"/>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                        <Ellipse Width="8" Height="8" Fill="#27ae60" Margin="0,0,4,0" VerticalAlignment="Center"/>
                        <TextBlock x:Name="LegOk"   Foreground="#55557a" FontSize="10" Margin="0,0,10,0"/>
                        <Ellipse Width="8" Height="8" Fill="#f39c12" Margin="0,0,4,0" VerticalAlignment="Center"/>
                        <TextBlock x:Name="LegOld"  Foreground="#55557a" FontSize="10" Margin="0,0,10,0"/>
                        <Ellipse Width="8" Height="8" Fill="#e74c3c" Margin="0,0,4,0" VerticalAlignment="Center"/>
                        <TextBlock x:Name="LegMiss" Foreground="#55557a" FontSize="10"/>
                    </StackPanel>
                </Grid>
                <ListBox x:Name="DlcList" Grid.Row="1" Background="Transparent" BorderThickness="0"
                         ScrollViewer.HorizontalScrollBarVisibility="Disabled" ItemContainerStyle="{StaticResource DI}"/>
            </Grid>
        </Border>

        <Border Grid.Row="5" Style="{StaticResource Card}" Margin="0,0,0,12">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <Grid Grid.Row="0" Margin="0,0,0,3">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBlock x:Name="CurLbl"   Grid.Column="0" Foreground="#8888aa" FontSize="11" VerticalAlignment="Center"/>
                    <TextBlock x:Name="SpeedLbl" Grid.Column="1" Foreground="#4d8fd4" FontSize="11" VerticalAlignment="Center"/>
                </Grid>
                <ProgressBar x:Name="PBarFile" Grid.Row="1" Height="4" Margin="0,0,0,5" Background="#2a2a45" Foreground="#4d8fd4" BorderThickness="0" Maximum="100"/>
                <ProgressBar x:Name="PBar"     Grid.Row="2" Height="8" Margin="0,0,0,8" Background="#2a2a45" Foreground="#1a9a5a" BorderThickness="0" Maximum="100"/>
                <Border Grid.Row="3" Background="#0d0d1a" CornerRadius="6">
                    <ListBox x:Name="LogBox" Background="Transparent" BorderThickness="0"
                             FontFamily="Consolas" FontSize="11" Padding="8"
                             ScrollViewer.HorizontalScrollBarVisibility="Disabled" ItemContainerStyle="{StaticResource LI}"/>
                </Border>
            </Grid>
        </Border>

        <DockPanel Grid.Row="6" LastChildFill="True">
            <Button x:Name="RefreshBtn" DockPanel.Dock="Right" Content="↻" Style="{StaticResource BGh}" Margin="10,0,0,0"/>
            <Button x:Name="LaunchBtn"  DockPanel.Dock="Right" Style="{StaticResource BLu}" Visibility="Collapsed" Margin="10,0,0,0"/>
            <Button x:Name="InstallBtn" Style="{StaticResource BG}"/>
        </DockPanel>
    </Grid>
</Window>
'@

$reader      = [System.Xml.XmlNodeReader]::new($xaml)
$window      = [Windows.Markup.XamlReader]::Load($reader)
$pathBox     = $window.FindName('PathBox');    $browseBtn  = $window.FindName('BrowseBtn')
$lblLauncherPath    = $window.FindName('LblLauncherPath')
$launcherPathBox    = $window.FindName('LauncherPathBox')
$launcherBrowseBtn  = $window.FindName('LauncherBrowseBtn')
$chkNoUpdate = $window.FindName('ChkNoUpdate')
$statusLbl   = $window.FindName('StatusLbl'); $logBox     = $window.FindName('LogBox')
$installBtn  = $window.FindName('InstallBtn');$launchBtn  = $window.FindName('LaunchBtn')
$refreshBtn  = $window.FindName('RefreshBtn')
$pBar        = $window.FindName('PBar');      $pBarFile   = $window.FindName('PBarFile')
$speedLbl    = $window.FindName('SpeedLbl'); $curLbl     = $window.FindName('CurLbl')
$chkFull     = $window.FindName('ChkFull');  $chkSkip    = $window.FindName('ChkSkip')
$lblLauncher = $window.FindName('LblLauncher'); $cmbLauncher = $window.FindName('CmbLauncher')
$dotGH       = $window.FindName('DotGH');    $dotSrv     = $window.FindName('DotSrv')
$dlcList     = $window.FindName('DlcList')
$btnEn=$window.FindName('BtnEn'); $btnRu=$window.FindName('BtnRu'); $btnZh=$window.FindName('BtnZh')
$titleLbl=$window.FindName('TitleLbl'); $lblPath=$window.FindName('LblPath')
$lblStatus=$window.FindName('LblStatus'); $lblOpts=$window.FindName('LblOpts'); $lblDlc=$window.FindName('LblDlc')
$legOk=$window.FindName('LegOk'); $legOld=$window.FindName('LegOld'); $legMiss=$window.FindName('LegMiss')

function Add-LogItem([string]$text, [string]$level) {
    $color = switch ($level) { 'ERROR' {'#e74c3c'} 'WARN' {'#f39c12'} 'OK' {'#27ae60'} default {'#6a7a9a'} }
    $tb = [System.Windows.Controls.TextBlock]::new()
    $tb.Text = $text; $tb.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $tb.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString($color)
    $li = [System.Windows.Controls.ListBoxItem]::new(); $li.Content = $tb
    $logBox.Items.Add($li) | Out-Null; $logBox.ScrollIntoView($li)
}

$drainTimer = [System.Windows.Threading.DispatcherTimer]::new()
$drainTimer.Interval = [TimeSpan]::FromMilliseconds(50)
$drainTimer.Add_Tick({
    $item = [object]$null
    while ($script:Q.TryDequeue([ref]$item)) {
        switch ($item.t) {
            'log'         { Add-LogItem $item.msg $item.lvl; Write-Log ($item.msg -replace '^\[.+?\] ','') $item.lvl }
            'dot_gh'      { $dotGH.Fill  = if ($item.ok) { [System.Windows.Media.Brushes]::LimeGreen } else { [System.Windows.Media.Brushes]::Crimson } }
            'dot_srv'     { $dotSrv.Fill = if ($item.ok) { [System.Windows.Media.Brushes]::LimeGreen } else { [System.Windows.Media.Brushes]::Crimson } }
            'dlc_data'    { $script:dlcData=$item.data; Refresh-DlcList }
            'outdated'    { $script:outdatedFolders=$item.folders; Refresh-DlcList }
            'init_done'   { Update-UI; Refresh-DlcList }
            'install_done'{
                $script:outdatedFolders = @()
                Update-UI; Refresh-DlcList
                $launchBtn.Visibility=[System.Windows.Visibility]::Visible
            }
            'speed_reset' { $speedLbl.Text=''; $curLbl.Text='' }
            'progress'    { $pBarFile.Value=$item.pfile; if ($item.speed) {$speedLbl.Text=$item.speed}; if ($item.cur) {$curLbl.Text=$item.cur} }
            'pbar'        { $pBar.Value=$item.val }
            'cur'         { $curLbl.Text=$item.text }
        }
    }
})
$drainTimer.Start()

function Set-LangActive([string]$lang) {
    $off = [System.Windows.Media.SolidColorBrush][System.Windows.Media.Color]::FromRgb(0x2a,0x2a,0x45)
    $on  = [System.Windows.Media.SolidColorBrush][System.Windows.Media.Color]::FromRgb(0x1a,0x5a,0x9a)
    $btnEn.Background=$off; $btnRu.Background=$off; $btnZh.Background=$off
    switch ($lang) { 'ru' {$btnRu.Background=$on} 'zh' {$btnZh.Background=$on} default {$btnEn.Background=$on} }
}
function Apply-UIText {
    $titleLbl.Text=T 'title'; $lblPath.Text=T 'path_label'; $browseBtn.Content=T 'browse'
    $lblStatus.Text=T 'status_label'; $lblOpts.Text=T 'options_label'
    $chkFull.Content=T 'chk_full'; $chkSkip.Content=T 'chk_skip'
    $chkNoUpdate.Content = T 'chk_no_update'
    $lblLauncher.Text=T 'lbl_launcher'
    $lblLauncherPath.Text = T 'lbl_launcher_path'
    $launcherBrowseBtn.Content = T 'browse'
    $sel = $cmbLauncher.SelectedIndex
    $cmbLauncher.Items.Clear()
    [void]$cmbLauncher.Items.Add((T 'launcher_default'))
    foreach ($alt in $ALT_LAUNCHERS) { [void]$cmbLauncher.Items.Add($alt) }
    if ($sel -ge 0) { $cmbLauncher.SelectedIndex = $sel } else { $cmbLauncher.SelectedIndex = 0 }
    $lblDlc.Text=T 'dlc_label'; $installBtn.Content=T 'install_btn'; $launchBtn.Content=T 'launch_btn'
    $refreshBtn.ToolTip=T 'refresh_tip'
    $legOk.Text=T 'dlc_ok'; $legOld.Text=T 'dlc_old'; $legMiss.Text=T 'dlc_missing'
}
function Apply-Lang([string]$lang) { Set-LangBuiltin $lang; Set-LangActive $lang; Apply-UIText; Update-UI }

function Refresh-DlcList {
    $dlcList.Items.Clear()
    if (-not $script:dlcData) { return }
    $gp = $pathBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($gp)) { return }
    try { if (-not (Test-Path (Join-Path $gp 'stellaris.exe'))) { return } } catch { return }
    $dlcBase = Join-Path $gp 'dlc'
    foreach ($dlc in $script:dlcData) {
        $name=$dlc.dlc_name; $f=$dlc.dlc_folder
        if (-not $name -or -not $f) { continue }
        $exists = try { Test-Path (Join-Path $dlcBase $f) } catch { $false }
        $color  = if (-not $exists) {'#e74c3c'} elseif ($f -in $script:outdatedFolders) {'#f39c12'} else {'#27ae60'}
        $tb=[System.Windows.Controls.TextBlock]::new(); $tb.Text=$name; $tb.FontSize=12
        $tb.Foreground=[System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString($color)
        $li=[System.Windows.Controls.ListBoxItem]::new(); $li.Content=$tb
        $dlcList.Items.Add($li) | Out-Null
    }
}
function Update-UI {
    $st    = Get-InstallStatus $pathBox.Text.Trim()
    $ready = ($null -ne $script:dlcData)
    switch ($st) {
        'installed'     { $statusLbl.Text=T 'status_installed';     $statusLbl.Foreground='#27ae60'; $installBtn.IsEnabled=$ready }
        'not_installed' { $statusLbl.Text=T 'status_not_installed'; $statusLbl.Foreground='#f0a030'; $installBtn.IsEnabled=$ready }
        'not_found'     { $statusLbl.Text=T 'status_not_found';     $statusLbl.Foreground='#e74c3c'; $installBtn.IsEnabled=$false }
    }
}

$window.Add_Loaded({
    Write-Log "=== Stellaris DLC Unlocker started ==="
    Set-LangBuiltin (Get-SystemLang); Set-LangActive $script:curLang; Apply-UIText
    $steam = Find-SteamPath
    $sp    = if ($steam) { Find-StellarisPath $steam } else { $null }
    if (-not [string]::IsNullOrWhiteSpace($sp)) { $pathBox.Text = $sp }
    $detectedLauncher = try {
        $reg = (Get-ItemProperty 'HKCU:\Software\Paradox Interactive\Paradox Launcher v2' -ErrorAction Stop).LauncherInstallation
        if ($reg -and (Test-Path $reg)) { $reg }
        else { "$env:LOCALAPPDATA\Programs\Paradox Interactive\launcher" }
    } catch { "$env:LOCALAPPDATA\Programs\Paradox Interactive\launcher" }
    if (Test-Path $detectedLauncher) { $launcherPathBox.Text = $detectedLauncher }
    $launcherBrowseBtn.Add_Click({
        $path = [Picker.FolderDialog]::Pick('Select Paradox Launcher folder', $launcherPathBox.Text)
        if ($path) { $launcherPathBox.Text = $path }
    })
    $statusLbl.Text=T 'status_loading'; $installBtn.IsEnabled=$false

    Start-PSRunspace $INIT_SCRIPT @{
        _Q           = $script:Q
        _GDLC        = $GITHUB_DLC_URL;      _GDLC_FALL   = $JSDELIVR_DLC_URL;
        _GHASH       = $GITHUB_HASHES_URL;   _GHASH_FALL = $JSDELIVR_HASHES_URL
        _STEAMCMD_API= $STEAMCMD_API;        _APPID      = $STELLARIS_APP_ID
        _ORIGIN_API  = $ORIGIN_API;          _CACHE_DIR  = $CACHE_DIR
        _SERVERURL = $SERVER_URL
        _ALTLAUNCHERS= $ALT_LAUNCHERS
        _GAMEPATH    = if (-not [string]::IsNullOrWhiteSpace($sp)) { $sp } else { '' }
    }
})

$btnEn.Add_Click({ Apply-Lang 'en'; Refresh-DlcList })
$btnRu.Add_Click({ Apply-Lang 'ru'; Refresh-DlcList })
$btnZh.Add_Click({ Apply-Lang 'zh'; Refresh-DlcList })

$browseBtn.Add_Click({
    $path = [Picker.FolderDialog]::Pick('Select Stellaris folder', $pathBox.Text)
    if ($path) { $pathBox.Text = $path; Update-UI; Refresh-DlcList }
})
$refreshBtn.Add_Click({ Update-UI; Refresh-DlcList })
$pathBox.Add_TextChanged({ Update-UI })

$chkFull.Add_Checked({
    $r=[System.Windows.MessageBox]::Show((T 'confirm_full'),(T 'warn_title'),[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
    if ($r -ne 'Yes') { $chkFull.IsChecked=$false; return }
    $chkSkip.IsChecked=$false; $chkSkip.IsEnabled=$false
})
$chkFull.Add_Unchecked({ $chkSkip.IsEnabled=$true })
$chkSkip.Add_Checked({
    $chkFull.IsChecked=$false; $chkFull.IsEnabled=$false
    $cmbLauncher.IsEnabled=$false
})
$chkSkip.Add_Unchecked({ $chkFull.IsEnabled=$true; $cmbLauncher.IsEnabled=$true })

$chkNoUpdate.Add_Unchecked({
    $r = [System.Windows.MessageBox]::Show(
        (T 'confirm_no_update'), (T 'warn_title'),
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning)
    if ($r -ne 'Yes') { $chkNoUpdate.IsChecked = $true }
})

$launchBtn.Add_Click({
    Start-Process "steam://rungameid/$STELLARIS_APP_ID"
    $window.Close()
})

$installBtn.Add_Click({
    $sp=$pathBox.Text.Trim()
    if (-not (Test-Path (Join-Path $sp 'stellaris.exe'))) {
        [System.Windows.MessageBox]::Show((T 'err_no_exe'),(T 'err_title'),[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
    }
    if (-not $script:dlcData) {
        [System.Windows.MessageBox]::Show((T 'err_loading'),(T 'wait_title'),[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null; return
    }
    $installBtn.IsEnabled=$false; $launchBtn.Visibility=[System.Windows.Visibility]::Collapsed
    $pBar.Value=0; $pBarFile.Value=0; $speedLbl.Text=''; $curLbl.Text=''

    $selectedAlt = if ($cmbLauncher.SelectedIndex -gt 0) { $ALT_LAUNCHERS[$cmbLauncher.SelectedIndex - 1] } else { $null }

    Start-PSRunspace $INSTALL_SCRIPT @{
        _Q                    = $script:Q
        _GAMEPATH             = $sp
        _LAUNCHERPATH         = $launcherPathBox.Text.Trim()
        _DLCDATA              = $script:dlcData
        _SERVERURL            = $SERVER_URL
        _ALTNAME              = $selectedAlt
        _OUTDATED             = $script:outdatedFolders
        _FULL                 = [bool]$chkFull.IsChecked
        _SKIP                 = [bool]$chkSkip.IsChecked
        _NO_UPDATE            = [bool]$chkNoUpdate.IsChecked
        _ALT                  = ($null -ne $selectedAlt)
        _CACHE_DIR            = $CACHE_DIR
        _ORIGIN_API           = $ORIGIN_API
        _STEAMCMD_API         = $STEAMCMD_API
        _APPID                = $STELLARIS_APP_ID
        _LOG_FILE             = $LOG_FILE
    }
})

[System.Windows.Media.RenderOptions]::ProcessRenderMode = [System.Windows.Interop.RenderMode]::SoftwareOnly
[void]$window.ShowDialog()
$drainTimer.Stop()
