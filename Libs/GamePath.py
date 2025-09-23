import os.path
import winreg
from vdf import loads
import subprocess


def get_user_logon_name():
    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startupinfo.wShowWindow = subprocess.SW_HIDE

    ps = "(Get-CimInstance -ClassName Win32_ComputerSystem).Username;"

    res = subprocess.check_output(
        ["powershell", "-NoProfile", "-Command", ps],
        universal_newlines=True,
        startupinfo=startupinfo
    ).strip()

    if "\\" in res:
        res = res = res.rsplit("\\", 1)[1]

    return res


def get_steam_path():
    return reg_search(r"Software\Valve\Steam", "SteamPath")


def stellaris_path():
    try:
        vdf_file_path = os.path.join(get_steam_path(), "steamapps", "libraryfolders.vdf")
        with open(vdf_file_path, 'r', encoding='utf-8') as vdf_file:
            vdf_data = loads(vdf_file.read())

        if "libraryfolders" in vdf_data:
            libraryfolders = vdf_data["libraryfolders"]
            for key, value in libraryfolders.items():
                if "apps" in value and "281990" in value["apps"]:
                    return os.path.join(value["path"], "steamapps", "common", "Stellaris")
            else:
                return 0
        else:
            return 0
    except Exception:
        return 0


def is_drive_root(path: str) -> bool:
    if not path:
        return False
    norm = os.path.normpath(path)
    drive, tail = os.path.splitdrive(norm)
    return bool(drive) and (tail in ("", os.sep))


def launcher_path():
    try:
        user_logon_name = get_user_logon_name()
    except:
        user_logon_name = os.getlogin()

    user_home = os.path.join("C:\\Users", user_logon_name)

    launcher_path_1 = reg_search(r"Software\Paradox Interactive\Paradox Launcher v2", "LauncherInstallation")
    launcher_path_2 = reg_search(r"Software\Paradox Interactive\Paradox Launcher v2", "LauncherPathFolder")

    if (launcher_path_1 and is_drive_root(launcher_path_1)) or not launcher_path_1:
        launcher_path_1 = os.path.join(user_home, "AppData", "Local", "Programs", "Paradox Interactive", "launcher")
    if (launcher_path_2 and is_drive_root(launcher_path_2)) or not launcher_path_2:
        launcher_path_2 = os.path.join(user_home, "AppData", "Local", "Paradox Interactive")


    launcher_path_3 = os.path.join(user_home, "AppData", "Roaming", "Paradox Interactive")
    launcher_path_4 = os.path.join(user_home, "AppData", "Roaming", "paradox-launcher-v2")

    return launcher_path_1, launcher_path_2, launcher_path_3, launcher_path_4


def reg_search(vaule_data, vaule_name):
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, vaule_data)
        launcher_path, _ = winreg.QueryValueEx(key, vaule_name)
        winreg.CloseKey(key)
        return launcher_path
    except:
        return 0
