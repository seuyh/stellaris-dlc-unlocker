from PyQt5.QtWidgets import QApplication
from gui.main_window import MainWindow
from gui.LanguageSelectionWindow import LanguageSelectionWindow
from sys import argv, exit

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
