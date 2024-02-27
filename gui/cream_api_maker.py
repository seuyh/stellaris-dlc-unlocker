from requests import get
from time import sleep
from datetime import datetime
from PyQt5 import QtCore
import os


class CreamAPI(QtCore.QThread):
    progress_signal = QtCore.pyqtSignal(int)
    dlc_signal = QtCore.pyqtSignal(str)

    def __init__(self):
        super().__init__()
        # self.dlc_callback = dlc_callback
        # self.progress_callback = progress_callback
        self.parent_directory = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    def get_dlc_name(self, dlc_id):
        url = f"https://api.steamcmd.net/v1/info/{dlc_id}"
        headers = {
            "User-Agent": "Mozilla/5.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            "Accept-Encoding": "gzip, deflate, br",
            "Accept-Language": "en-US,en;q=0.9",
            "Cache-Control": "max-age=0",
            "Connection": "keep-alive",
            "Host": "api.steamcmd.net",
            "Upgrade-Insecure-Requests": "1"
        }
        try:
            response = get(url, headers=headers)
            data = response.json()
            dlc_name = data['data'][str(dlc_id)]['common']['name']
            return dlc_name
        except Exception:
            sleep(3)
            return self.get_dlc_name(dlc_id)

    def get_dlc_list(self, app_id):
        url = f"https://api.steamcmd.net/v1/info/{app_id}"
        headers = {
            "User-Agent": "Mozilla/5.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            "Accept-Encoding": "gzip, deflate, br",
            "Accept-Language": "en-US,en;q=0.9",
            "Cache-Control": "max-age=0",
            "Connection": "keep-alive",
            "Host": "api.steamcmd.net",
            "Upgrade-Insecure-Requests": "1"
        }
        try:
            response = get(url, headers=headers)
            data = response.json()
            dlc_list_json = data['data'][str(app_id)]['extended']['listofdlc']
            dlc_list = dlc_list_json.split(',')
            return dlc_list
        except Exception:
            sleep(3)
            return self.get_dlc_list(app_id)

    def run(self):
        stellaris_dlc_list = self.get_dlc_list('281990')
        # hoi_dlc_list = self.get_dlc_list('394360')
        total_dlcs = len(stellaris_dlc_list)
        with open(os.path.join(self.parent_directory, 'creamapi_steam_files', 'cream_api.ini'), 'w', encoding='utf-8') as f:
            f.write("; auto created by Stellaris DLC Unlocker\n")
            f.write("; Author seuyh\n")
            current_datetime = datetime.now().strftime("%d.%m.%Y")
            f.write(f"; created {current_datetime}\n")
            f.write("; Get DLC Info from api.steamcmd.net\n")
            f.write("; Format: CreamAPI v4.5.0.0\n")
            f.write(f"; AppID: 281990\n")
            f.write(f"; AppID Name: Stellaris\n")
            f.write(f"; AppID Total DLCs: {total_dlcs}\n\n")
            f.write("[steam]\n")
            f.write(f"appid = 281990\n")
            f.write("orgapi64 = steam_api64_org_game.dll\n\n")
            f.write("[steam_misc]\n")
            f.write("; Disables the internal SteamUser interface handler.\n")
            f.write("; Does have an effect on the games that are using the license check for the DLC/application.\n")
            f.write('; Default is "false".')
            f.write("disableuserinterface = false\n\n")
            f.write("[dlc]\n")
            f.write("; DLC handling.\n")
            f.write("; Format: <dlc_id> = <dlc_description>\n")
            f.write("; If the DLC is not specified in this section\n")
            f.write("; then it won't be unlocked\n")
            current_dlc = 0
            dlcs = []
            for dlc_id in stellaris_dlc_list:
                dlc_name = self.get_dlc_name(dlc_id)
                dlcs.append(f"{dlc_id} = {dlc_name}\n")
                f.write(f"{dlc_id} = {dlc_name}\n")
                current_dlc += 1
                progress = int(round(current_dlc / total_dlcs, 2) * 100)
                if progress >= 100:
                    progress = 99
                # self.progress_callback(progress)
                self.progress_signal.emit(progress)
                # self.dlc_callback(dlc_name)
                dlc_str = f'{current_dlc}/{total_dlcs}: {dlc_name}'
                self.dlc_signal.emit(dlc_str)
            # f.write("; HOI IV DlS\n")
            # for dlc_id in hoi_dlc_list:
            #     dlc_name = self.get_dlc_name(dlc_id)
            #     f.write(f"{dlc_id} = {dlc_name}\n")
            #     current_dlc += 1
            #     progress = int(round(current_dlc / total_dlcs, 2) * 100)
            #     if progress > 100:
            #         progress = 100
            #     # self.progress_callback(progress)
            #     self.progress_signal.emit(progress)
            #     # self.dlc_callback(dlc_name)
            #     self.dlc_signal.emit(dlc_name)

            self.launcher_creamapi(dlcs)

    def launcher_creamapi(self, dlcs):
        with open(os.path.join(self.parent_directory, 'creamapi_launcher_files', 'cream_api.ini'), 'w', encoding='utf-8') as f:
            current_datetime = datetime.now().strftime("%d.%m.%Y")
            f.write(f"; created {current_datetime}\n")
            f.write("[steam]\n")
            f.write("; Application ID (http://store.steampowered.com/app/%appid%/)\n")
            f.write("appid = 281990\n")
            f.write("; Current game language.\n")
            f.write("; Uncomment this option to turn it on.\n")
            f.write("; Default is \"english\".\n")
            f.write(";language = german\n")
            f.write("; Enable/disable automatic DLC unlock. Default option is set to \"false\".\n")
            f.write("; Keep in mind that this option  WON'T work properly if the \"[dlc]\" section is NOT empty\n")
            f.write("unlockall = false\n")
            f.write("; Original Valve's steam_api.dll.\n")
            f.write("; Default is \"steam_api_o.dll\".\n")
            f.write("orgapi = steam_api_o.dll\n")
            f.write("; Original Valve's steam_api64.dll.\n")
            f.write("; Default is \"steam_api64_o.dll\".\n")
            f.write("orgapi64 = steam_api64_o.dll\n")
            f.write("; Enable/disable extra protection bypasser.\n")
            f.write("; Default is \"false\".\n")
            f.write("extraprotection = false\n")
            f.write("; The game will think that you're offline (supported by some games).\n")
            f.write("; Default is \"false\".\n")
            f.write("forceoffline = false\n")
            f.write("; Some games are checking for the low violence presence.\n")
            f.write("; Default is \"false\".\n")
            f.write(";lowviolence = true\n")
            f.write("; Purchase timestamp for the DLC (http://www.onlineconversion.com/unix_time.htm).\n")
            f.write("; Default is \"0\" (1970/01/01).\n")
            f.write(";purchasetimestamp = 0\n\n")
            f.write("[steam_misc]\n")
            f.write("; Disables the internal SteamUser interface handler.\n")
            f.write("; Does have an effect on the games that are using the license check for the DLC/application.\n")
            f.write("; Default is \"false\".\n")
            f.write("disableuserinterface = false\n\n")
            f.write("[dlc]\n")
            f.write("; DLC handling.\n")
            f.write("; Format: <dlc_id> = <dlc_description>\n")
            f.write("; e.g. : 247295 = Saints Row IV - GAT V Pack\n")
            f.write("; If the DLC is not specified in this section\n")
            f.write("; then it won't be unlocked\n\n")
            for dlc in dlcs:
                f.write(dlc)
        self.progress_signal.emit(100)
