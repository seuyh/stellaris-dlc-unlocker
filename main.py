from PyQt5.QtWidgets import QApplication
from gui.main_window import MainWindow
from gui.LanguageSelectionWindow import LanguageSelectionWindow
from sys import argv, exit
# import sys
# import traceback



# def excepthookk(exctype, value, tb):
#     """Обработчик исключений для перехвата ошибок."""
#     crashlog_path = "crashlog.txt"
#     try:
#         with open(crashlog_path, 'a') as f:
#             f.write("Exception Type: {}\n".format(exctype.__name__))
#             f.write("Exception Value: {}\n".format(value))
#             f.write("Traceback:\n")
#             traceback.print_tb(tb, file=f)
#             f.write("\n\n")
#     except Exception as e:
#         print("Failed to create crash log:", e)
#
#
# sys.excepthook = excepthookk

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
