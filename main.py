from PyQt5.QtWidgets import QApplication, QMessageBox
from gui.main_window import MainWindow
from gui.LanguageSelectionWindow import LanguageSelectionWindow
from PyQt5.QtCore import QTimer
from sys import argv, exit
import sys
import traceback


def show_crash_message():
    msg_box = QMessageBox()
    msg_box.setIcon(QMessageBox.Critical)
    msg_box.setWindowTitle("Error!")
    msg_box.setText(
        "An unexpected error has been detected.\n'unlocker_crashlog.txt' was created. Please attach it with the error report")
    msg_box.exec_()

    QTimer.singleShot(0, lambda: sys.exit(2))

def excepthookk(exctype, value, tb):
    """Обработчик исключений для перехвата ошибок."""
    crashlog_path = "unlocker_crashlog.txt"
    try:
        with open(crashlog_path, 'a') as f:
            f.write("Exception Type: {}\n".format(exctype.__name__))
            f.write("Exception Value: {}\n".format(value))
            f.write("Traceback:\n")
            traceback.print_tb(tb, file=f)
            f.write("\n\n")
        show_crash_message()
    except Exception as e:
        print("Failed to create crash log:", e)


sys.excepthook = excepthookk

if __name__ == "__main__":
    app = QApplication(argv)
    language_selection_window = LanguageSelectionWindow()
    language_selection_window.show()

    app.exec_()

    try:
        main_window = MainWindow(language_selection_window.selected_language)
        main_window.show()
    except AttributeError:
        exit(0)

    exit(app.exec_())
