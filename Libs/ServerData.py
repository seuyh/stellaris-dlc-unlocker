import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import sys

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
headers = {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'}

GITHUB_DLC_URL = 'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/dlc_data.json'
GITHUB_DATA_URL = 'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/data.json'

SITE_DLC_URL = "https://stlunlocker.ru/unlocker/dlc_data.json"
SITE_DATA_URL = "https://stlunlocker.ru/unlocker/data.json"

def get_dlc_data():
    try:
        print(f"Trying to fetch DLC data from GitHub...")
        response = requests.get(GITHUB_DLC_URL, headers=headers, timeout=5)
        if response.status_code == 200:
            print("DLC data fetched from GitHub.")
            return response.json()
    except Exception as e:
        print(f"GitHub DLC fetch failed: {e}")

    try:
        print(f"Fetching DLC data from Fallback Server...")
        response = requests.get(SITE_DLC_URL, headers=headers, timeout=10)
        if response.status_code == 200:
            print("DLC data fetched from Server.")
            return response.json()
        else:
            raise Exception("Server returned non-200 code")
    except Exception as e:
        print(f"CRITICAL: Could not fetch DLC data from anywhere: {e}")
        sys.exit(2)


def get_server_data():
    try:
        print(f"Trying to fetch Server config from GitHub...")
        response = requests.get(GITHUB_DATA_URL, headers=headers, timeout=5)
        if response.status_code == 200:
            print("Server config fetched from GitHub.")
            return response.json()
    except Exception as e:
        print(f"GitHub Server config fetch failed: {e}")

    try:
        print(f"Fetching Server config from Fallback Server...")
        response = requests.get(SITE_DATA_URL, headers=headers, timeout=10)
        if response.status_code == 200:
            print("Server config fetched from Server.")
            return response.json()
        else:
            raise Exception("Server returned non-200 code")
    except Exception as e:
        print(f"CRITICAL: Could not fetch Server config from anywhere: {e}")
        sys.exit(2)