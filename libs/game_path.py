import os.path
import winreg
from vdf import loads


def get_steam_path():
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Valve\Steam")
        steam_path, _ = winreg.QueryValueEx(key, "SteamPath")
        winreg.CloseKey(key)
        return steam_path
    except Exception:
        return 0


def stellaris_path():
    vdf_file_path = os.path.join(get_steam_path(), "steamapps", "libraryfolders.vdf")

    try:
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
