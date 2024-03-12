from time import sleep
from sys import argv, exit
from PyQt5.QtWidgets import QFileDialog, QMessageBox, QMainWindow, QProgressDialog
from gui.cream_api_maker import CreamAPI
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QIcon, QDesktopServices

from libs.server_data import gameversion, version, get_remote_file_size, url, server_msg
from libs.game_path import stellaris_path, launcher_path
from gui.DownloadThread import DownloaderThread
from libs.launcher_reinstall import ReinstallThread
from libs.encrypt import decrypt
from subprocess import Popen, run, CREATE_NO_WINDOW
from zipfile import ZipFile
from shutil import rmtree, copytree
from requests import get
import ctypes
import os
from watchdog.observers import Observer
from threading import Thread
from libs.launcher_analyzer import FolderCreationHandler


class MainWindow(QMainWindow):
    def __init__(self, language):
        super(MainWindow, self).__init__()
        self.setup_ui(language)
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
        self.finish_button.clicked.connect(self.finish)
        self.locate_folder.clicked.connect(self.browse_folder)
        self.eula_true.toggled.connect(self.on_radio_button_toggled)
        self.eula_true1.toggled.connect(self.on_radio_button_toggled)
        self.eula_false.toggled.connect(self.on_radio_button_toggled)
        self.textBrowser_5.anchorClicked.connect(self.open_link_in_browser)
        self.textBrowser_15.anchorClicked.connect(self.open_link_in_browser)

        self.download_thread = None
        self.parent_directory = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.translations = self.load_translations(language)
        self.is_downloading = False
        self.game_path = None
        self.progress_label.setVisible(False)
        self.reinstall_progress.setVisible(False)
        self.now_reinstalling.setVisible(False)
        self.next_button_5.setEnabled(False)

        self.iversion = '0.96'

        # -------------------------------------------- #

        # ----------- запуск необходимых стартовых функций ----------- #
        self.version_check()
        self.version_change()
        self.server_msg()
        self.gameversion_change()
        self.space_req_change()
        self.kill_process('Paradox Launcher.exe')
        self.kill_process('stellaris.exe')
        self.path_change()
        self.stackedWidget.setCurrentIndex(5)
        self.setWindowTitle("Stellaris DLC Unlocker")
        self.setWindowIcon(QIcon(f'{self.parent_directory}/design/435345.png'))
        # ------------------------------------------------------------ #

    def setup_ui(self, language):
        if language == 'ru':
            from design.languages.installer_ru import Ui_MainWindow as gui_design
        else:
            from design.languages.installer_en import Ui_MainWindow as gui_design
        self.ui = gui_design()
        self.ui.setupUi(self)
        for name in dir(self.ui):
            if not name.startswith('_'):
                setattr(self, name, getattr(self.ui, name))

    def switch_to_next(self):
        self.stackedWidget.setCurrentIndex(self.stackedWidget.currentIndex() + 1)

    def switch_to_back(self):
        self.stackedWidget.setCurrentIndex(self.stackedWidget.currentIndex() - 1)

    def updateApplication(self, download_url):
        old_file = argv[0]
        old_dir = os.path.dirname(old_file)
        pid = ctypes.windll.kernel32.GetCurrentProcessId()
        error = False

        progress_dialog = QProgressDialog(self.translations.get("update_load", ""), None, 0, 100)
        progress_dialog.setWindowTitle(self.translations.get("update", ""))
        progress_dialog.setWindowModality(2)
        progress_dialog.show()

        try:
            response = get(download_url, stream=True)
            total_size_in_bytes = int(response.headers.get('content-length', 0))
            block_size = 1024
            downloaded_bytes = 0
            with open(f'{old_dir}/Stellaris-DLC-Unlocker.load', 'wb') as new_exe:
                for data in response.iter_content(block_size):
                    new_exe.write(data)
                    downloaded_bytes += len(data)
                    progress = int(downloaded_bytes / total_size_in_bytes * 100)
                    progress_dialog.setValue(progress)

            with open('unlocker_updater.bat', 'w') as updater_file:
                updater_file.write('@echo off\n')
                updater_file.write(f'taskkill /pid {pid} /f\n')
                updater_file.write(f'ping 127.0.0.1 -n 1 > nul\n')
                updater_file.write('echo Updating...\n')
                updater_file.write(f'del "{old_file}"\n')
                updater_file.write(f'rename "{old_dir}\\Stellaris-DLC-Unlocker.load" "Stellaris-DLC-Unlocker.exe"\n')
                updater_file.write(f'start "" "{old_dir}\\Stellaris-DLC-Unlocker.exe"\n')
                updater_file.write('ping 127.0.0.1 -n 1 > nul\n')
                updater_file.write('del %0')

        except Exception:
            if self.ok_dialog(self.translations.get("error", ""),
                              self.translations.get("update_error", ""),
                              QMessageBox.Critical):
                pass
            error = True
        progress_dialog.close()

        if not error:
            sleep(0.5)
            Popen(['cmd.exe', '/c', 'unlocker_updater.bat'], shell=True)
            exit()

    def version_check(self):
        if float(version) > float(self.iversion):
            if self.ok_dialog(self.translations.get("update_found_title", ""),
                              self.translations.get("update_found_text", "").format(iversion=self.iversion,
                                                                                    version=version),
                              QMessageBox.Critical):
                self.updateApplication(
                    f'https://github.com/seuyh/stellaris-dlc-unlocker/releases/download/{str(version)}/Stellaris-DLC-Unlocker.exe')

    def cancel(self):
        msg_box = QMessageBox()
        msg_box.setIcon(QMessageBox.Information)
        msg_box.setWindowTitle(self.translations.get("cancel_title", ""))
        msg_box.setText(self.translations.get("cancel_text", ""))
        msg_box.setStandardButtons(QMessageBox.Yes | QMessageBox.Cancel)
        msg_box.setDefaultButton(QMessageBox.Yes)
        yes_button = msg_box.button(QMessageBox.Yes)
        yes_button.setText('Да')
        cancel_button = msg_box.button(QMessageBox.Cancel)
        cancel_button.setText('Нет')
        reply = msg_box.exec_()
        if reply == QMessageBox.Yes:
            try:
                if os.path.exists(self.save_path):
                    os.remove(self.save_path)
            except:
                pass
            self.close()

    @staticmethod
    def kill_process(process_name):
        try:
            run(["taskkill", "/F", "/IM", process_name], check=True, creationflags=CREATE_NO_WINDOW)
        except:
            pass

    def version_change(self):
        new_text = self.version.text().replace("%nan%", self.iversion)
        self.version.setText(new_text)

    def gameversion_change(self):
        new_text = self.hello_msg.toHtml().replace("[unknown]", gameversion)
        self.hello_msg.setText(new_text)
        new_text = self.hello2_msg.toHtml().replace("[unknown]", gameversion)
        self.hello2_msg.setText(new_text)

    def space_req_change(self):
        new_text = self.space_req.text().replace("%nan%", get_remote_file_size(
            decrypt(url, 'LPrVJDjMXGx1ToihooozyFX4-toGjKcCr8pjZFmq62c=')))
        self.space_req.setText(new_text)

    def on_radio_button_toggled(self):
        if self.eula_true.isChecked() or self.eula_true1.isChecked():
            self.next_button_3.setEnabled(True)
            self.next_button_3.setCursor(Qt.PointingHandCursor)
        elif self.eula_false.isChecked():
            self.next_button_3.setEnabled(False)
            self.next_button_3.setCursor(Qt.ForbiddenCursor)

    def open_link_in_browser(self, url):
        content = self.sender().toHtml()
        QDesktopServices.openUrl(url)
        self.sender().setHtml(content)

    def load_translations(self, language):
        translations = {}
        filename = f"{self.parent_directory}/design/languages/{language}.txt"
        with open(filename, 'r', encoding='utf-8') as file:
            for line in file:
                key, value = line.strip().split(": ", 1)
                value = value.replace('\\n', '\n')
                translations[key] = value
        return translations

    def path_change(self):
        path = stellaris_path()
        if path:
            self.path_place.setPlainText(path)

    def path_check(self):
        try:
            if os.path.isfile(os.path.join(self.path_place.toPlainText(), "stellaris.exe")):
                return self.path_place.toPlainText()
        except Exception:
            return 0
        else:
            msg_box = QMessageBox()
            msg_box.setIcon(QMessageBox.Critical)
            msg_box.setWindowTitle(self.translations.get("error", ""))
            msg_box.setText(self.translations.get("path_error", ""))
            msg_box.addButton(QMessageBox.Ok)
            msg_box.exec_()
            return 0

    def browse_folder(self):
        directory = QFileDialog.getExistingDirectory(self, self.translations.get("dir_change", ""),
                                                     self.path_place.toPlainText())
        if directory:
            self.path_place.setPlainText(directory)

    def download_file(self):
        self.game_path = self.path_check().replace("/", "\\")
        if self.game_path:
            self.is_downloading = True
            if self.stackedWidget.currentIndex() != 4:
                self.stackedWidget.setCurrentIndex(self.stackedWidget.currentIndex() + 1)
            file_url = decrypt(url, 'LPrVJDjMXGx1ToihooozyFX4-toGjKcCr8pjZFmq62c=')
            self.save_path = os.path.join(self.game_path, 'stellaris_unlocker.zip')
            try:
                if os.path.exists(self.save_path):
                    os.remove(self.save_path)
            except:
                pass

            self.download_thread = DownloaderThread(file_url, self.save_path)
            self.download_thread.progress_signal.connect(self.update_progress)
            self.download_thread.error_signal.connect(self.show_error)
            self.download_thread.speed_signal.connect(self.show_download_speed)

            self.creamapi_maker = CreamAPI()
            self.creamapi_maker.progress_signal.connect(self.update_creamapi_progress)
            self.creamapi_maker.dlc_signal.connect(self.show_dlc_get_message)

            self.download_thread.start()
            self.creamapi_maker.start()
            self.download_text.setText(self.translations.get("loading", ""))
            self.creamapi_label.setText(
                self.translations.get("dlc_get", "") + " " + self.translations.get("dlc_get_format", ""))

    def update_creamapi_progress(self, value):
        self.creamapi_progressBar_2.setValue(value)
        if value == 100:
            self.creamapi_label.setText(self.translations.get('done', ''))
            self.download_complete()

    def show_dlc_get_message(self, dlc_name):
        self.creamapi_label.setText(f"{self.translations.get('dlc_get', '')} {dlc_name}")

    def update_progress(self, value):
        self.download_progressBar.setValue(value)
        if value == 100:
            self.download_text.setText(self.translations.get('done', ''))
            self.speed_label.setText(f"")
            self.download_complete()

    def update_reinstall_progress(self, value):
        self.reinstall_progress.setValue(value)
        if value == 33:
            self.now_reinstalling.setText(self.translations.get('launcher_install', ''))
        elif value == 66:
            self.now_reinstalling.setText(self.translations.get('launcher_update', ''))
        elif value == 100:
            self.now_reinstalling.setText(self.translations.get('done', ''))

    def show_download_speed(self, speed):
        self.speed_label.setText(self.translations.get("speed", "").format(speed=speed))

    def show_error(self, error_message):
        # QMessageBox.warning(self, self.translations.get('error', ''), self.translations.get('download_error', ''))
        if self.ok_dialog(self.translations.get("error", ""),
                          self.translations.get("download_error", ""),
                          QMessageBox.Critical):
            self.close()

    def show_reinstall_error(self):
        if self.ok_dialog(self.translations.get("error", ""),
                          self.translations.get("reinstall_error", ""),
                          QMessageBox.Critical):
            self.close()

    def download_complete(self):
        if self.download_progressBar.value() == 100 and self.creamapi_progressBar_2.value() == 100:
            self.next_button_5.setEnabled(True)
            self.cancel_button_5.setEnabled(True)

    def reinstall(self):
        self.reinstall_up.setVisible(False)
        self.reinstall_low.setVisible(False)
        self.reinstall_progress.setVisible(True)
        self.now_reinstalling.setVisible(True)
        self.progress_label.setVisible(True)
        self.reinstall_button.setVisible(False)
        self.cancel_button_6.setEnabled(False)
        self.now_reinstalling.setText(self.translations.get('launcher_uninstall', ''))
        paradox_folder1, paradox_folder2, paradox_folder3, paradox_folder4 = launcher_path()

        self.reinstall_thread = ReinstallThread(self.game_path, paradox_folder1, paradox_folder2, paradox_folder3,
                                                paradox_folder4)
        self.reinstall_thread.progress_signal.connect(self.update_reinstall_progress)
        self.reinstall_thread.error_signal.connect(self.show_reinstall_error)
        self.reinstall_thread.continue_reinstall.connect(self.reinstall_2)
        self.reinstall_thread.start()

    def reinstall_2(self, paradox_folder1):

        launcher_folders = [item for item in os.listdir(paradox_folder1) if item.startswith("launcher")]
        launcher_folders.sort(key=lambda x: os.path.getmtime(os.path.join(paradox_folder1, x)))
        launcher_folder = os.path.join(os.path.join(paradox_folder1, launcher_folders[0]))
        if self.ok_dialog(self.translations.get('attention', ''),
                          self.translations.get('launcher_updater', ''),
                          QMessageBox.Information):
            # process = Popen([os.path.join(paradox_folder1, launcher_folder, "Paradox Launcher.exe")])
            # process.wait()
            self.start_watch_update(paradox_folder1)
            self.thread.join()
            self.kill_process('Paradox Launcher.exe')

            # except:
            #     if self.ok_dialog(self.translations.get("error", ""),
            #                       self.translations.get("reinstall_error", ""),
            #                       QMessageBox.Critical):
            #         self.close()

        launcher_folders = [item for item in os.listdir(paradox_folder1) if item.startswith("launcher")]
        launcher_folders.sort(key=lambda x: os.path.getmtime(os.path.join(paradox_folder1, x)))
        self.update_reinstall_progress(100)
        sleep(0.5)
        self.switch_to_next()
        # self.replace_files(os.path.join(os.path.join(paradox_folder1, launcher_folders[0])))
        try:
            self.replace_files(os.path.join(os.path.join(paradox_folder1, launcher_folders[1])))
        except Exception:
            pass

    def replace_files(self, launcher_folder):
        try:
            rmtree(f'{self.game_path}/dlc')
        except Exception:
            pass
        self.unzip_and_replace()
        try:
            os.remove(f'{launcher_folder}/resources/app/dist/main/steam_api64_o.dll')
        except:
            pass
        os.rename(f'{launcher_folder}/resources/app/dist/main/steam_api64.dll',
                  f'{launcher_folder}/resources/app/dist/main/steam_api64_o.dll')
        copytree(f'{self.parent_directory}/creamapi_launcher_files',
                 f'{launcher_folder}/resources/app/dist/main',
                 dirs_exist_ok=True)
        copytree(f'{self.parent_directory}/creamapi_steam_files', self.game_path, dirs_exist_ok=True)
        self.finish_text.setPlainText(self.translations.get('all_done', ''))
        sleep(1)
        self.finish_button.setEnabled(True)

    def unzip_and_replace(self):
        zip_path = self.save_path
        extract_folder = self.game_path
        if not os.path.exists(extract_folder):
            os.makedirs(extract_folder)

        with ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_folder)
        return extract_folder

    def finish(self):
        if self.launch_game.isChecked():
            try:
                run('start steam://run/281990', shell=True, capture_output=True, text=True)
            except:
                pass

        try:
            if os.path.exists(self.save_path):
                os.remove(self.save_path)
        except:
            pass

        self.close()

    def start_watch_update(self, folder_to_watch):
        self.thread = Thread(target=self.watch_folder, args=(folder_to_watch,))
        self.thread.start()

    def watch_folder(self, folder_to_watch):
        process = Popen([os.path.join(folder_to_watch, "bootstrapper-v2.exe")])
        observer = Observer()
        event_handler = FolderCreationHandler(folder_to_watch, observer, process)
        observer.schedule(event_handler, path=folder_to_watch, recursive=True)
        observer.start()

        try:
            while observer.is_alive():
                observer.join(1)
        except KeyboardInterrupt:
            observer.stop()
            observer.join()

    def server_msg(self):
        if server_msg:
            if self.ok_dialog(self.translations.get('server_msg_title', ''),
                              self.translations.get('server_msg_text', '').format(server_msg=server_msg),
                              QMessageBox.Information):
                pass

    @staticmethod
    def ok_dialog(title, text, msg_type):
        msg_box = QMessageBox()
        msg_box.setIcon(msg_type)
        msg_box.setWindowTitle(title)
        msg_box.setText(text)
        ok_button = msg_box.addButton(QMessageBox.Ok)
        msg_box.exec_()
        return msg_box.clickedButton() == ok_button
