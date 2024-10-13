import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import sys

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
headers = {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'}
try:
    response_dlc_data = requests.get(
        'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/dlc_data.json', headers=headers).json()
    dlc_data = response_dlc_data
except Exception:
    sys.exit(2)