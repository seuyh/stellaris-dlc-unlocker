import urllib.request
from os import remove
from PyQt5 import QtCore
from time import time


class DownloaderThread(QtCore.QThread):
    progress_signal = QtCore.pyqtSignal(int)
    error_signal = QtCore.pyqtSignal(Exception)
    speed_signal = QtCore.pyqtSignal(float)

    def __init__(self, file_url, save_path):
        super().__init__()
        self.file_url = file_url
        self.save_path = save_path
        self.cancelled = False

    def run(self):
        request = urllib.request.Request(self.file_url, headers={"User-Agent": "Mozilla/5.0"})
        try:
            with urllib.request.urlopen(request) as response:
                total_size = int(response.headers.get('content-length', 0))
                downloaded = 0
                start_time = time()

                with open(self.save_path, 'wb') as file:
                    while True:
                        if self.cancelled:
                            remove(self.save_path)
                            return
                        data = response.read(1024)
                        if not data:
                            break
                        file.write(data)
                        downloaded += len(data)
                        elapsed_time = time() - start_time
                        if elapsed_time > 0:
                            speed = round(downloaded / (1024 * 1024 * elapsed_time), 1)
                        else:
                            speed = 0
                        progress_percentage = int((downloaded / total_size) * 100)
                        self.speed_signal.emit(speed)
                        self.progress_signal.emit(progress_percentage)
            file.close()
        except Exception as e:
            self.error_signal.emit(e)

    def cancel(self):
        self.cancelled = True
