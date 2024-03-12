from watchdog.events import FileSystemEventHandler


class FolderCreationHandler(FileSystemEventHandler):
    def __init__(self, folder_to_watch, observer, process):
        super().__init__()
        self.folder_to_watch = folder_to_watch
        self.observer = observer
        self.process = process

    def on_created(self, event):
        if event.is_directory and event.src_path.endswith('main'):
            print("updated")
            self.process.terminate()
            self.observer.stop()
