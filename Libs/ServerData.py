import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import sys

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
headers = {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'}


def get_dlc_data():
    try:
        response_dlc_data = requests.get(
            'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/dlc_data.json', headers=headers).json()
        return response_dlc_data
    except Exception:
        sys.exit(2)


def get_server_data():
    try:
        response_server_data = requests.get(
            'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/refs/heads/main/data.json',
            headers=headers).json()
        return response_server_data
    except Exception:
        sys.exit(2)
