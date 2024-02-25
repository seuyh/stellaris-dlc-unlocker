import os
import time
import sys
from PyQt5.QtWidgets import QMainWindow, QFileDialog, QMessageBox
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QIcon
import design.main_window as main_design
from libs.server_data import gameversion, version, size, url
from libs.game_path import stellaris_path
from gui.DownloadThread import DownloaderThread
from libs.encrypt import decrypt
import subprocess
import zipfile
import shutil


class MainWindow(QMainWindow, main_design.Ui_MainWindow):

    def __init__(self):
        super(MainWindow, self).__init__()
        self.setupUi(self)
        self.setWindowState(Qt.WindowActive)

        # ----------- инициализация кнопок ----------- #

        self.next_button.clicked.connect(self.switch_to_next)
        self.next_button_2.clicked.connect(self.download_file)
        self.next_button_3.clicked.connect(self.switch_to_next)
        self.next_button_4.clicked.connect(self.switch_to_next)
        self.next_button_5.clicked.connect(self.switch_to_next)
        self.cancel_button.clicked.connect(self.cancel)
        self.cancel_button_2.clicked.connect(self.cancel)
        self.cancel_button_3.clicked.connect(self.cancel)
        self.cancel_button_4.clicked.connect(self.cancel)
        self.cancel_button_5.clicked.connect(self.cancel)
        self.cancel_button_6.clicked.connect(self.cancel)
        self.back_button.clicked.connect(self.switch_to_back)
        self.back_button_2.clicked.connect(self.switch_to_back)
        self.back_button_3.clicked.connect(self.switch_to_back)
        self.reinstall_button.clicked.connect(self.reinstall)
        self.skip_button.clicked.connect(lambda: self.reinstall(skip=True))
        self.finish_button.clicked.connect(self.finish)
        self.locate_folder.clicked.connect(self.browse_folder)
        self.eula_true.toggled.connect(self.on_radio_button_toggled)
        self.eula_true1.toggled.connect(self.on_radio_button_toggled)
        self.eula_false.toggled.connect(self.on_radio_button_toggled)

        self.download_thread = None
        self.is_downloading = False
        self.next_button_5.setEnabled(False)
        # self.thread = DownloadThread(
        #     "https://github.com/user/repository/raw/master/file.zip",
        #     os.path.join(os.getenv("TEMP"), "file.zip")
        # )
        # self.thread.progress.connect(self.update_progress)
        # -------------------------------------------- #

        # ----------- запуск необходимых стартовых функций ----------- #
        self.version_check()
        self.version_change()
        self.gameversion_change()
        self.space_req_change()
        self.path_change()
        self.setWindowTitle("Stellaris DLC Unlocker")
        self.setWindowIcon(QIcon('design/435345.png'))
        # ------------------------------------------------------------ #

    def switch_to_next(self):
        self.stackedWidget.setCurrentIndex(self.stackedWidget.currentIndex() + 1)

    def switch_to_back(self):
        self.stackedWidget.currentIndex()
        self.stackedWidget.setCurrentIndex(self.stackedWidget.currentIndex() - 1)

    def version_check(self):
        if float(version) > float(0.1):
            if self.ok_dialog('Новая версия',
                              "На сервере обнаружена новая версия!\n\nПерекачайте анлокер с сайта",
                              QMessageBox.Critical):
                sys.exit()

    def cancel(self):
        msg_box = QMessageBox()
        msg_box.setIcon(QMessageBox.Information)
        msg_box.setWindowTitle('Выход')
        msg_box.setText(
            'Если вы выйдите разблокировщик не будет установлен.\n\n\nВыйти из программы установки?')
        msg_box.setStandardButtons(QMessageBox.Yes | QMessageBox.Cancel)
        msg_box.setDefaultButton(QMessageBox.Yes)
        yes_button = msg_box.button(QMessageBox.Yes)
        yes_button.setText('Да')
        cancel_button = msg_box.button(QMessageBox.Cancel)
        cancel_button.setText('Нет')
        reply = msg_box.exec_()
        if reply == QMessageBox.Yes:
            self.close()

    def version_change(self):
        new_text = self.version.text().replace("%nan%", version)
        self.version.setText(new_text)

    def gameversion_change(self):
        new_text = self.hello_msg.toHtml().replace("[unknown]", gameversion)
        self.hello_msg.setText(new_text)
        new_text = self.hello2_msg.toHtml().replace("[unknown]", gameversion)
        self.hello2_msg.setText(new_text)

    def space_req_change(self):
        new_text = self.space_req.text().replace("%nan%", size)
        self.space_req.setText(new_text)

    def on_radio_button_toggled(self):
        if self.eula_true.isChecked() or self.eula_true1.isChecked():
            self.next_button_3.setEnabled(True)
            self.next_button_3.setCursor(Qt.PointingHandCursor)
        elif self.eula_false.isChecked():
            self.next_button_3.setEnabled(False)
            self.next_button_3.setCursor(Qt.ForbiddenCursor)

    def path_change(self):
        path = stellaris_path()
        if path:
            self.path_place.setPlainText(path)

    def path_check(self):
        if os.path.isfile(
                os.path.join(self.path_place.toPlainText(), "stellaris.exe")):
            return 1
        else:
            msg_box = QMessageBox()
            msg_box.setIcon(QMessageBox.Critical)
            msg_box.setWindowTitle('Ошибка!')
            msg_box.setText(
                'Исполняемый файл "stellaris.exe" не найден.\n\n\nВозможно, вы указали неверную директорию.')
            ok_button = msg_box.addButton(QMessageBox.Ok)
            msg_box.exec_()
            return 0

    def browse_folder(self):
        directory = QFileDialog.getExistingDirectory(self, "Выберите папку Stellaris", self.path_place.toPlainText())
        if directory:
            self.path_place.setPlainText(directory)

    def download_file(self):
        if self.path_check():
            self.is_downloading = True
            if self.stackedWidget.currentIndex() != 4:
                self.stackedWidget.setCurrentIndex(self.stackedWidget.currentIndex() + 1)
            file_url = decrypt(url, 'LPrVJDjMXGx1ToihooozyFX4-toGjKcCr8pjZFmq62c=')
            # self.save_path = os.path.join(os.getenv("TEMP"), "stellaris_unlocker")
            self.save_path = os.path.join(os.path.expanduser("~"), "Downloads", 'stellaris_unlocker.zip')
            try:
                if os.path.exists(self.save_path):
                    os.remove(self.save_path)
                if os.path.exists(os.path.join(os.path.expanduser("~"), "Downloads", 'stellaris_unlocker')):
                    shutil.rmtree(os.path.join(os.path.expanduser("~"), "Downloads", 'stellaris_unlocker'))
            except:
                pass

            self.download_thread = DownloaderThread(file_url, self.save_path, self.update_progress, self.show_error)
            self.download_thread.start()
            self.download_text.setText("Загрузка...")

    def update_progress(self, value):
        self.download_progressBar.setValue(value)
        # self.speed_line.setText("Скорость: {:.2f} KB/s".format(speed))
        if value == 100:
            self.download_text.setText("Готово! Теперь вы можете продолжить установку!")
            self.next_button_5.setEnabled(True)

    def show_error(self, error_message):
        QMessageBox.warning(self, "Error", "Failed to download file: " + error_message)

    def paradox_remove(self):
        user_home = os.path.expanduser("~")
        paradox_folder1 = os.path.join(user_home, "AppData", "Local", "Programs", "Paradox Interactive")
        paradox_folder2 = os.path.join(user_home, "AppData", "Local", "Paradox Interactive")
        paradox_folder3 = os.path.join(user_home, "AppData", "Roaming", "Paradox Interactive")
        paradox_folder4 = os.path.join(user_home, "AppData", "Roaming", "paradox-launcher-v2")
        try:
            if os.path.exists(paradox_folder1):
                shutil.rmtree(paradox_folder1)

            if os.path.exists(paradox_folder2):
                shutil.rmtree(paradox_folder2)

            if os.path.exists(paradox_folder3):
                shutil.rmtree(paradox_folder3)

            if os.path.exists(paradox_folder4):
                shutil.rmtree(paradox_folder4)
        except Exception:
            pass

    def reinstall(self, skip=False):
        self.stackedWidget.setCurrentIndex(6)
        if skip:
            user_home = os.path.expanduser("~")
            folder_path = os.path.join(user_home, "AppData", "Local", "Programs", "Paradox Interactive", "launcher")
            launcher_folders = []
            for item in os.listdir(folder_path):
                if item.startswith("launcher"):
                    launcher_folders.append(item)
            time.sleep(0.2)
            self.replace_files(os.path.join(os.path.join(folder_path, launcher_folders[1])))
        else:
            self.paradox_remove()
            if self.ok_dialog('Внимание',
                              "Сейчас будет открыт инсталятор лаунчера, пожалуйста выберете 'Remove' если будет предложено, либо просто продолжите установку",
                              QMessageBox.Information):
                process = subprocess.Popen([f"{self.path_place.toPlainText()}/launcher-installer-windows.msi"],
                                           shell=True)
                process.wait()

            user_home = os.path.expanduser("~")
            folder_path = os.path.join(user_home, "AppData", "Local", "Programs", "Paradox Interactive", "launcher")
            if not os.path.exists(folder_path):
                if self.ok_dialog('Внимание',
                                  "Сейчас будет открыт инсталятор лаунчера, пожалуйста выполните установку",
                                  QMessageBox.Information):
                    process = subprocess.Popen([f"{self.path_place.toPlainText()}/launcher-installer-windows.msi"],
                                               shell=True)
                    process.wait()
                time.sleep(1)
            launcher_folders = []
            for item in os.listdir(folder_path):
                if item.startswith("launcher"):
                    launcher_folders.append(item)
            launcher_folder = os.path.join(os.path.join(folder_path, launcher_folders[0]))
            if self.ok_dialog('Внимание',
                              "Сейчас мы запустим лаунчер, но так как мы не можем отследить когда он выполнит уведомление, после его открытия нажмите 'SKIP' в правом верхем углу и дождитесь пока лаучнер скажет, что обновление готово и просто закройте его",
                              QMessageBox.Information):
                process = subprocess.Popen([os.path.join(folder_path, launcher_folder, "Paradox Launcher.exe")])
                process.wait()
            time.sleep(1)
            launcher_folders = []
            for item in os.listdir(folder_path):
                if item.startswith("launcher"):
                    launcher_folders.append(item)
                    time.sleep(0.2)
                    self.switch_to_next()
            self.replace_files(os.path.join(os.path.join(folder_path, launcher_folders[1])))

    def replace_files(self, launcher_folder):
        unzipped = self.unzip_and_replace()
        shutil.rmtree(f'{launcher_folder}/resources')
        shutil.move(f'{unzipped}/1launcher/resources', launcher_folder)
        files = os.listdir(f'{unzipped}/2game')
        for file in files:
            source_path = os.path.join(f'{unzipped}/2game', file)
            target_path = os.path.join(self.path_place.toPlainText(), file)
            shutil.move(source_path, target_path)
        shutil.rmtree(f'{self.path_place.toPlainText()}/dlc')
        shutil.move(f'{unzipped}/dlc', self.path_place.toPlainText())
        self.finish_text.setPlainText('Все готово!')
        time.sleep(1)
        self.finish_button.setEnabled(True)

    def unzip_and_replace(self):
        zip_path = self.save_path
        extract_folder = os.path.splitext(zip_path)[0]
        if not os.path.exists(extract_folder):
            os.makedirs(extract_folder)

        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_folder)
        return extract_folder

    def finish(self):
        if self.launch_game.isChecked():
            try:
                subprocess.Popen([f"{self.path_place.toPlainText()}/stellaris.exe"])
            except:
                pass

        try:
            if os.path.exists(self.save_path):
                os.remove(self.save_path)
            if os.path.exists(os.path.join(os.path.expanduser("~"), "Downloads", 'stellaris_unlocker')):
                shutil.rmtree(os.path.join(os.path.expanduser("~"), "Downloads", 'stellaris_unlocker'))
        except:
            pass

        self.close()

    def ok_dialog(self, title, text, msg_type):
        msg_box = QMessageBox()
        msg_box.setIcon(msg_type)
        msg_box.setWindowTitle(title)
        msg_box.setText(text)
        ok_button = msg_box.addButton(QMessageBox.Ok)
        msg_box.exec_()
        return msg_box.clickedButton() == ok_button
