import requests
from PyQt5.QtCore import QThread, pyqtSignal

class ConnectionCheckThread(QThread):
    github_status_checked = pyqtSignal(bool)
    server_status_checked = pyqtSignal(bool)

    def __init__(self, server_url, github_api_url):
        super().__init__()
        self.server_url = server_url
        self.github_api_url = github_api_url

    def run(self):
        try:
            response = requests.get(self.github_api_url, timeout=5)
            if response.status_code == 200:
                self.github_status_checked.emit(True)
            else:
                self.github_status_checked.emit(False)
        except:
            self.github_status_checked.emit(False)

        try:
            if self.server_url:
                response = requests.get(f'https://{self.server_url}', timeout=10)
                if response.status_code == 200:
                    self.server_status_checked.emit(True)
                else:
                    self.server_status_checked.emit(False)
            else:
                self.server_status_checked.emit(False)
        except:
            self.server_status_checked.emit(False)