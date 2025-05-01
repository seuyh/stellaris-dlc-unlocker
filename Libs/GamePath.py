import os.path
import platform
from vdf import loads


def get_steam_path():
    system = platform.system()
    if system == "Windows":
        return reg_search(r"Software\Valve\Steam", "SteamPath")
    else:
        return os.path.expanduser("~/.steam/steam")


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


def launcher_path():
    user_home = os.path.expanduser("~")
    launcher_path_1 = reg_search(r"Software\Paradox Interactive\Paradox Launcher v2", "LauncherInstallation")
    launcher_path_2 = reg_search(r"Software\Paradox Interactive\Paradox Launcher v2", "LauncherPathFolder")

    if not launcher_path_1:
        launcher_path_1 = os.path.join(user_home, "AppData", "Local", "Programs", "Paradox Interactive", "launcher")
    if not launcher_path_2:
        launcher_path_2 = os.path.join(user_home, "AppData", "Local", "Paradox Interactive")

    launcher_path_3 = os.path.join(user_home, "AppData", "Roaming", "Paradox Interactive")
    launcher_path_4 = os.path.join(user_home, "AppData", "Roaming", "paradox-launcher-v2")

    return launcher_path_1, launcher_path_2, launcher_path_3, launcher_path_4


def reg_search(vaule_data, vaule_name):
    try:
        import winreg
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, vaule_data)
        launcher_path, _ = winreg.QueryValueEx(key, vaule_name)
        winreg.CloseKey(key)
        return launcher_path
    except:
        return 0