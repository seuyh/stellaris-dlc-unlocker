import urllib.request
from os import remove, path
from PyQt5 import QtCore
from time import time


class DownloaderThread(QtCore.QThread):
    progress_signal = QtCore.pyqtSignal(int, bool)
    progress_signal_2 = QtCore.pyqtSignal(int)
    # text_signal = QtCore.pyqtSignal(str)
    error_signal = QtCore.pyqtSignal(Exception)
    speed_signal = QtCore.pyqtSignal(float)
    finished = QtCore.pyqtSignal()

    def __init__(self, file_url, save_path, dlc_downloaded, dlc_count):
        super().__init__()
        self.file_url = file_url
        self.save_path = save_path
        self.cancelled = False
        self.downloaded_bytes = 0
        self.dlc_downloaded = dlc_downloaded
        self.dlc_count = dlc_count

    def run(self):
        request = urllib.request.Request(self.file_url, headers={"User-Agent": "Mozilla/5.0"})
        request.add_header('Range', f'bytes={self.downloaded_bytes}-')
        try:
            with urllib.request.urlopen(request, timeout=25) as response:
                total_size = int(response.headers.get('content-length', 0)) + self.downloaded_bytes
                start_time = time()

                with open(self.save_path, 'ab') as file:
                    while True:
                        if self.cancelled:
                            remove(self.save_path)
                            return
                        data = response.read(1024)
                        if not data:
                            break
                        file.write(data)
                        self.downloaded_bytes += len(data)
                        elapsed_time = time() - start_time
                        if elapsed_time > 0:
                            speed = round(self.downloaded_bytes / (1024 * 1024 * elapsed_time), 1)
                        else:
                            speed = 0
                        progress_percentage_2 = int((self.downloaded_bytes / total_size) * 100)
                        self.speed_signal.emit(speed)
                        self.progress_signal_2.emit(progress_percentage_2)


            file.close()

        except Exception as e:
            self.cancelled = True
            self.error_signal.emit(e)
        finally:
            progress_percentage = int((self.dlc_downloaded / self.dlc_count) * 100)
            self.progress_signal.emit(progress_percentage, True)
            # self.text_signal.emit(path.basename(self.save_path))
            self.finished.emit()

    def cancel(self):
        self.cancelled = True