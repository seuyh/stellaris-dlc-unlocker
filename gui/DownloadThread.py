import urllib.request
import threading
import os


class DownloaderThread(threading.Thread):
    def __init__(self, file_url, save_path, progress_callback, error_callback):
        super().__init__()
        self.file_url = file_url
        self.save_path = save_path
        self.error_callback = error_callback
        self.progress_callback = progress_callback
        self.cancelled = False

    def run(self):
        request = urllib.request.Request(self.file_url, headers={"User-Agent": "Mozilla/5.0"})
        try:
            with urllib.request.urlopen(request) as response:
                total_size = int(response.headers.get('content-length', 0))
                downloaded = 0

                with open(self.save_path, 'wb') as file:
                    while True:
                        if self.cancelled:
                            os.remove(self.save_path)
                            return
                        data = response.read(1024)
                        if not data:
                            break
                        file.write(data)
                        downloaded += len(data)
                        progress_percentage = int((downloaded / total_size) * 100)
                        self.progress_callback(progress_percentage)
            file.close()
        except Exception as e:
            self.error_callback(e)


def cancel(self):
    self.cancelled = True
