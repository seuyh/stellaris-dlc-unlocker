from PyQt5.QtWidgets import QApplication
from gui.main_window import MainWindow
from sys import argv

if __name__ == "__main__":
    app = QApplication(argv)
    main_window = MainWindow()
    main_window.show()
    app.exec_()
