from PyQt5.QtCore import Qt
from PyQt5.QtWidgets import QDialog
from PyQt5 import QtGui

from UI.ui_dialog import Ui_Dialog
import UI.recources_rc


class dialogUi(QDialog):
    def __init__(self, parent=None):

        super(dialogUi, self).__init__(parent)
        self.d = Ui_Dialog()
        self.d.setupUi(self)
        self.setWindowFlags(Qt.FramelessWindowHint)



        self.d.bn_close.clicked.connect(lambda: self.close())

        self.d.bn_east.clicked.connect(lambda: self.close())
        self.d.bn_west.clicked.connect(lambda: self.close())

        self.dragPos = self.pos()
        def movedialogWindow(event):
            if event.buttons() == Qt.LeftButton:
                self.move(self.pos() + event.globalPos() - self.dragPos)
                self.dragPos = event.globalPos()
                event.accept()

        self.d.frame_top.mouseMoveEvent = movedialogWindow

    def mousePressEvent(self, event):
        self.dragPos = event.globalPos()

    def dialogConstrict(self, heading, message, btn1, btn2, icon, parent=None):
        self.d.lab_heading.setText(str(heading))
        self.d.lab_message.setText(str(message))
        self.d.bn_east.setText(str(btn2))
        self.d.bn_west.setText(str(btn1))
        pixmap = QtGui.QPixmap(icon)
        self.d.lab_icon.setPixmap(pixmap)
        if parent:
            parent_rect = parent.frameGeometry()
            self.move(
                parent_rect.left() + (parent_rect.width() - self.width()) // 2,
                parent_rect.top() + (parent_rect.height() - self.height()) // 2
            )

        try:
            self.d.bn_east.clicked.disconnect()
            self.d.bn_west.clicked.disconnect()
        except TypeError:
            pass

        self.d.bn_west.clicked.connect(self.reject)
        self.d.bn_east.clicked.connect(self.accept)