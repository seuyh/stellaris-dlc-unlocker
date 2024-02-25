import requests
url = 'https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker-files/main/data.json'
headers = {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'}
response = requests.get(url, headers=headers).json()
gameversion = response["gameversion"]
version = response["version"]
size = response["size"]
url = response["url"]
