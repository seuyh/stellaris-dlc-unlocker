from PyQt5.QtCore import Qt
from PyQt5.QtWidgets import QApplication
from UI_logic.MainWindow import MainWindow
import sys
if hasattr(Qt, 'AA_EnableHighDpiScaling'):
    QApplication.setAttribute(Qt.AA_EnableHighDpiScaling, True)
if hasattr(Qt, 'AA_UseHighDpiPixmaps'):
    QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps, True)
if __name__ == '__main__':
    app = QApplication(sys.argv)
    print(f"Using AA_EnableHighDpiScaling > {QApplication.testAttribute(Qt.AA_EnableHighDpiScaling)}")
    print(f"Using AA_UseHighDpiPixmaps    > {QApplication.testAttribute(Qt.AA_UseHighDpiPixmaps)}")
    main_window = MainWindow()
    main_window.show()
    app.exec_()
