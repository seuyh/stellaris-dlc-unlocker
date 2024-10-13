from PyQt5.QtCore import Qt
from PyQt5.QtWidgets import QDialog, QApplication, QDesktopWidget
from PyQt5 import QtGui

from UI.ui_error import Ui_Error
import UI.recources_rc


class errorUi(QDialog):
    def __init__(self, parent=None):
        super(errorUi, self).__init__(parent)
        self.e = Ui_Error()
        self.e.setupUi(self)
        self.setWindowFlags(Qt.FramelessWindowHint)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.screen = QDesktopWidget().screenGeometry()

        self.e.bn_ok.clicked.connect(self.close_app)

        self.dragPos = self.pos()

        def moveWindow(event):
            # MOVE WINDOW
            if event.buttons() == Qt.LeftButton:
                self.move(self.pos() + event.globalPos() - self.dragPos)
                self.dragPos = event.globalPos()
                event.accept()

        self.e.frame_top.mouseMoveEvent = moveWindow
        self.exitApp = False

    def mousePressEvent(self, event):
        self.dragPos = event.globalPos()

    def errorConstrict(self, heading, icon, btnOk, parent=None, exitApp=False):
        self.exitApp = exitApp
        self.e.lab_heading.setText(heading)
        self.e.bn_ok.setText(btnOk)
        pixmap2 = QtGui.QPixmap(icon)
        self.e.lab_icon.setPixmap(pixmap2)

        if parent:
            parent_rect = parent.frameGeometry()
            self.move(
                parent_rect.left() + (parent_rect.width() - self.width()) // 2,
                parent_rect.top() + (parent_rect.height() - self.height()) // 2
            )
        else:
            x = (self.screen.width() - self.width()) // 2
            y = (self.screen.height() - self.height()) // 2
            self.move(x, y)

    def close_app(self):
        if self.exitApp:
            QApplication.quit()
        else:
            self.close()