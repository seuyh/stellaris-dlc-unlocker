import os
from PyQt5.QtWidgets import QApplication, QHBoxLayout, QWidget, QVBoxLayout, QComboBox, QPushButton
from PyQt5.QtGui import QIcon
from PyQt5.QtCore import Qt



class LanguageSelectionWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Language selection")

        layout = QVBoxLayout()

        self.parent_directory = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.setWindowIcon(QIcon(f'{self.parent_directory}/design/435345.png'))

        self.language_combo = QComboBox()
        self.language_combo.addItem("English", "en")
        self.language_combo.addItem("Русский", "ru")
        self.language_combo.currentIndexChanged.connect(self.language_changed)
        font = self.language_combo.font()
        font.setPointSize(10)
        self.language_combo.setFont(font)

        self.select_button = QPushButton("Next")
        self.select_button.clicked.connect(self.select_language)
        self.select_button.setFixedSize(115, 23)
        self.select_button.setCursor(Qt.PointingHandCursor)
        self.select_button.setStyleSheet(
            "QPushButton {border: 1px solid #B22222;} QPushButton:hover {background-color: #FFD0D1;}")

        self.cancel_button = QPushButton("Cancel")
        self.cancel_button.clicked.connect(self.close)
        self.cancel_button.setFixedSize(90, 23)
        self.cancel_button.setCursor(Qt.PointingHandCursor)
        self.cancel_button.setStyleSheet(
            "QPushButton {border: 1px solid #B22222;} QPushButton:hover {background-color: #FFD0D1;}")

        button_layout = QHBoxLayout()
        button_layout.addWidget(self.cancel_button)
        button_layout.addSpacing(5)
        button_layout.addWidget(self.select_button)

        layout.addWidget(self.language_combo)
        layout.addSpacing(5)
        layout.addLayout(button_layout)
        layout.addStretch(1)

        self.setLayout(layout)
        self.resize(271, 80)

        self.center()

    def center(self):
        # Получаем геометрию главного экрана
        qr = self.frameGeometry()
        # Получаем центральную точку относительно главного экрана
        cp = QApplication.desktop().availableGeometry().center()
        # Перемещаем окно в центр главного экрана
        qr.moveCenter(cp)
        self.setGeometry(qr)

    def language_changed(self):
        # Обновляем надписи на кнопках при изменении выбранного языка
        if self.language_combo.currentData() == 'en':
            self.setWindowTitle("Language selection")
            self.select_button.setText("Next")
            self.cancel_button.setText("Cancel")
        elif self.language_combo.currentData() == 'ru':
            self.setWindowTitle("Выбор языка")
            self.select_button.setText("Далее")
            self.cancel_button.setText("Отмена")

    def select_language(self):
        self.selected_language = self.language_combo.currentData()
        self.close()
