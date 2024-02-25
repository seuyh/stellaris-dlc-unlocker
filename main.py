# pyrcc5 C:/Users/sp21/PycharmProjects/stellaris-dlc-unlock/design/resources.qrc -o design/resources_rc.py
# pyuic5 C:/Users/sp21/PycharmProjects/stellaris-dlc-unlock/design/installer.ui -o design/main_window.py

from PyQt5.QtWidgets import QApplication
from gui.main_window import MainWindow
import sys

if __name__ == "__main__":
    app = QApplication(sys.argv)
    main_window = MainWindow()
    main_window.show()
    app.exec_()
