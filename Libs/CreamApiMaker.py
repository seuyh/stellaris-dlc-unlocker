from idlelib.iomenu import errors

from requests import get
from time import sleep
from PyQt5 import QtCore
import os


class CreamAPI(QtCore.QThread):
    progress_signal = QtCore.pyqtSignal(int)

    def __init__(self):
        super().__init__()
        # self.dlc_callback = dlc_callback
        # self.progress_callback = progress_callback
        self.parent_directory = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    def get_dlc_name(self, dlc_id, errors=0):
        print('CreamApi creating...')
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
            response = get(url, headers=headers, timeout=3)
            print(response)
            if response.status_code == 200:
                data = response.json()
                dlc_name = data['data'][str(dlc_id)]['common']['name']
                print(dlc_name)
                return dlc_name
            else:
                return None
        except Exception:
            if errors >= 3:
                return False
            errors += 1
            print('Cant connect steamcmd. Rertying...')
            return self.get_dlc_name(dlc_id)

    def get_dlc_list(self, app_id, errors=0):
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
            response = get(url, headers=headers, timeout=8)
            data = response.json()
            dlc_list_json = data['data'][str(app_id)]['extended']['listofdlc']
            dlc_list = dlc_list_json.split(',')
            return dlc_list
        except Exception:
            if errors >= 3:
                return False
            errors += 1
            print('Cant connect steamcmd. Rertying...')
            return self.get_dlc_list(app_id, errors)

    def run(self):
        print('Cream api creating...')
        dlc_list = self.get_dlc_list(281990)
        print(f"DLC list for Cream api {dlc_list}")
        if dlc_list:
            self.check_and_update_dlc_list(dlc_list,
                                           os.path.join(self.parent_directory, 'creamapi_steam_files', 'cream_api.ini'))
            self.check_and_update_dlc_list(dlc_list,
                                           os.path.join(self.parent_directory, 'creamapi_launcher_files', 'cream_api.ini'))
            # self.launcher_creamapi(dlcs)
            self.progress_signal.emit(100)
        else:
            print('SteamCmd unavailable. Skipped')
            self.progress_signal.emit(100)
            return


    def check_and_update_dlc_list(self, dlc_list, path):
        with open(path, 'r+') as file:
            content = file.read()
            for dlc_id in dlc_list:
                if str(dlc_id) not in content:
                    dlc_name = self.get_dlc_name(dlc_id)
                    file.write(f"\n{dlc_id} = {dlc_name}")
                    print('CreamApi writed')