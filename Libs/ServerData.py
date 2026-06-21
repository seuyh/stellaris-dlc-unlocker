import json
import os
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import sys

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
headers = {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'}

GITHUB_DLC_URL = 'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/dlc_data.json'
GITHUB_DATA_URL = 'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/data.json'

SITE_DLC_URL = "https://femboysex.pro/unlocker/dlc_data.json"
SITE_DATA_URL = "https://femboysex.pro/unlocker/data.json"


def _local_dlc_data_path():
    return os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'dlc_data.json')


def _load_local_dlc_data():
    try:
        with open(_local_dlc_data_path(), 'r', encoding='utf-8') as file:
            return json.load(file)
    except Exception as e:
        print(f"Local dlc_data.json unavailable: {e}")
        return None


def _merge_dlc_folders(primary, fallback):
    if not fallback:
        return primary
    fallback_by_name = {entry.get('dlc_name'): entry.get('dlc_folder', '') for entry in fallback}
    for entry in primary:
        if entry.get('dlc_folder') or entry.get('dlc_name') not in fallback_by_name:
            continue
        folder = fallback_by_name[entry['dlc_name']]
        if folder:
            entry['dlc_folder'] = folder
            print(f"Merged dlc_folder for {entry['dlc_name']}: {folder}")
    return primary


def get_dlc_data():
    local_data = _load_local_dlc_data()

    try:
        print(f"Trying to fetch DLC data from GitHub...")
        response = requests.get(GITHUB_DLC_URL, headers=headers, timeout=5)
        if response.status_code == 200:
            print("DLC data fetched from GitHub.")
            return _merge_dlc_folders(response.json(), local_data)
    except Exception as e:
        print(f"GitHub DLC fetch failed: {e}")

    try:
        print(f"Fetching DLC data from Fallback Server...")
        response = requests.get(SITE_DLC_URL, headers=headers, timeout=10)
        if response.status_code == 200:
            print("DLC data fetched from Server.")
            return _merge_dlc_folders(response.json(), local_data)
        else:
            raise Exception("Server returned non-200 code")
    except Exception as e:
        print(f"Server DLC fetch failed: {e}")

    if local_data:
        print("Using bundled dlc_data.json.")
        return local_data

    print("Could not fetch DLC data from anywhere.")
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