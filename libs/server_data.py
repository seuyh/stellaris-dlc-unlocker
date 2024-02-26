import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
url = 'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker-files/main/data.json'
headers = {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'}
response = requests.get(url, headers=headers).json()
gameversion = response["gameversion"]
version = response["version"]
url = response["url"]


def get_remote_file_size(url):
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
        }
        response = requests.head(url, headers=headers, verify=False)
        size_bytes = int(response.headers.get('content-length', 0))
        if size_bytes >= 1024 * 1024:
            size_str = "{:.2f} MB".format(size_bytes / (1024 * 1024))
        elif size_bytes >= 1024:
            size_str = "{:.2f} KB".format(size_bytes / 1024)
        else:
            size_str = "{} bytes".format(size_bytes)
        return size_str
    except Exception as e:
        return str(e)
