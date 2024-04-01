import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import sys

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
url = 'https://github.com/seuyh/stellaris-dlc-unlocker/raw/main/data.json'
headers = {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'}
try:
    response = requests.get(url, headers=headers).json()
    response_dlc_data = requests.get(
        'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/dlc_data.json', headers=headers).json()
    gameversion = response["gameversion"]
    version = response["version"]
    url = response["url"]
    server_msg = response["server_msg"]
    dlc_data = response_dlc_data
except Exception:
    sys.exit(2)


def get_remote_file_size(url):
    size_str = 0
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
        }
        for dlc in dlc_data:
            dlc_folder = dlc['dlc_folder']
            if dlc_folder == '':
                continue
            response = requests.head(f"{url}/{dlc_folder}", headers=headers, verify=False)
            size_bytes = int(response.headers.get('content-length', 0)) * 2
            if size_bytes >= 1024 * 1024:
                size_str = "{:.2f} MB".format(size_bytes / (1024 * 1024))
            elif size_bytes >= 1024:
                size_str = "{:.2f} KB".format(size_bytes / 1024)
            else:
                size_str = "{} bytes".format(size_bytes)
        return size_str
    except Exception:
        return 'Unknown'
