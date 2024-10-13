import sys
from datetime import datetime
from functools import partial
import io
import traceback
import atexit
from PyQt5.QtCore import QTimer
from UI_logic.ErrorWindow import errorUi

class Logger:
    def __init__(self, log_file_path, log_widget):
        self.log_widget = log_widget
        self.stdout_buffer = []
        self.stderr_buffer = []
        self.log_file = open(log_file_path, 'w', encoding='utf-8')
        self.error = errorUi()

        if sys.stdout is None:
            sys.stdout = io.StringIO()
        if sys.stderr is None:
            sys.stderr = io.StringIO()

        self.orig_stdout_write = sys.stdout.write
        self.orig_stderr_write = sys.stderr.write

        sys.stdout.write = partial(self.log_print, orig_write=self.orig_stdout_write, is_stderr=False)
        sys.stderr.write = partial(self.log_print, orig_write=self.orig_stderr_write, is_stderr=True)

        sys.excepthook = self.handle_exception
        atexit.register(self.close)

    def log_print(self, text, orig_write, is_stderr=False):
        if is_stderr:
            self.stderr_buffer.append(text)
        else:
            self.stdout_buffer.append(text)

        if text.endswith('\n'):
            if is_stderr:
                full_message = ''.join(self.stderr_buffer)
                self.stderr_buffer.clear()
                self.handle_logging(full_message)
            else:
                full_message = ''.join(self.stdout_buffer)
                self.stdout_buffer.clear()
                self.handle_logging(full_message)

        orig_write(text)

    def handle_logging(self, full_message):
        if full_message.strip():
            log_text = f'[{datetime.now().strftime("%H:%M:%S")}] {full_message.strip()}'
            self.log_file.write(log_text + '\n')
            self.log_file.flush()
            self.log_widget.addItem(log_text)
            self.log_widget.scrollToBottom()

    def handle_exception(self, exc_type, exc_value, exc_traceback):
        if issubclass(exc_type, KeyboardInterrupt):
            sys.__excepthook__(exc_type, exc_value, exc_traceback)
            return

        error_message = ''.join(traceback.format_exception(exc_type, exc_value, exc_traceback))
        self.handle_logging(f"Unhandled exception: {error_message}")

        print(f"Error: {error_message}")
        QTimer.singleShot(0, lambda: self.errorexec('Crashed!\nSee unlocker.log', 'Exit', exitApp=True))

    def close(self):
        if self.log_file and not self.log_file.closed:
            self.log_file.close()

    def errorexec(self, heading, btnOk, icon=":/icons/icons/1x/closeAsset 43.png", exitApp=False):
        print(f'Call errorexec: {heading, btnOk, icon, exitApp}')
        errorUi.errorConstrict(self.error, heading, icon, btnOk, None, exitApp)
        self.error.exec_()
