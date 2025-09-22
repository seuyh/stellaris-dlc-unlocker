import os
from shutil import rmtree, copytree
from sys import argv
from zipfile import ZipFile, BadZipFile

import requests
import winreg
from PyQt5.QtGui import QDesktopServices, QColor, QBrush, QIcon
from PyQt5.QtWidgets import QMainWindow, QFileDialog, QListWidgetItem, QProgressDialog, QApplication
from PyQt5.QtCore import Qt, QUrl, QTimer, QTranslator
from subprocess import run, CREATE_NO_WINDOW
from pathlib import Path
from locale import getlocale

import UI.ui_main as ui_main
from Libs.ConnectionCheck import ConnectionCheckThread
from Libs.LauncherReinstall import ReinstallThread
from Libs.logger import Logger
from UI_logic.DialogWindow import dialogUi
from UI_logic.ErrorWindow import errorUi
from Libs.GamePath import stellaris_path, launcher_path, get_user_logon_name
from Libs.ServerData import get_dlc_data, get_server_data
from Libs.CreamApiMaker import CreamAPI
from Libs.DownloadThread import DownloaderThread
from Libs.MD5Check import MD5


class MainWindow(QMainWindow, ui_main.Ui_MainWindow):
    def __init__(self):
        super(MainWindow, self).__init__()
        self.translator = QTranslator()
        self.setWindowFlags(Qt.FramelessWindowHint)
        self.setupUi(self)
        self.setWindowState(Qt.WindowActive)

        self.error = errorUi()
        self.diag = dialogUi()
        self.game_path = None
        self.not_updated_dlc = []
        self.dlc_data = get_dlc_data()
        try:
            self.user_logon_name = get_user_logon_name()
        except:
            self.user_logon_name = os.getlogin()
        self.server_url, self.server_alturl = (lambda d: (d['url'], d['alturl']))(get_server_data())
        self.path_change()
        self.kill_process('Paradox Launcher.exe')
        self.kill_process('stellaris.exe')

        self.draggable_elements = [self.frame_user, self.server_status, self.gh_status, self.lappname_title,
                                   self.frame_top]
        for element in self.draggable_elements:
            element.mousePressEvent = self.mousePressEvent
            element.mouseMoveEvent = self.mouseMoveEvent
            element.mouseReleaseEvent = self.mouseReleaseEvent

        self.is_dragging = False
        self.last_mouse_position = None
        self.launcher_downloaded = None
        self.continued = False
        self.downloaded_launcher_dir = None
        self.parent_directory = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

        self.is_downloading = False
        self.download_thread = None
        self.creamapidone = False

        self.GITHUB_REPO = "https://api.github.com/repos/seuyh/stellaris-dlc-unlocker/releases/latest"
        self.current_version = '2.25'
        self.version_label.setText(f'Ver. {str(self.current_version)}')

        self.copy_files_radio.setVisible(False)
        self.download_files_radio.setVisible(False)
        self.launcher_reinstall_radio.setVisible(False)
        self.progress_label.setVisible(False)
        self.dlc_download_label.setVisible(False)
        self.dlc_download_progress_bar.setVisible(False)
        self.current_dlc_label.setVisible(False)
        self.current_dlc_progress_bar.setVisible(False)
        self.lauch_game_checkbox.setVisible(False)
        self.done_button.setVisible(False)

        self.speed_label.setVisible(False)
        self.update_dlc_button.setVisible(False)
        self.old_dlc_text.setVisible(False)
        self.en_lang.toggled.connect(self.switch_to_english)
        self.ru_lang.toggled.connect(self.switch_to_russian)
        self.cn_lang.toggled.connect(self.switch_to_chinese)

        self.connection_thread = ConnectionCheckThread(self.server_url)

        self.connection_thread.github_status_checked.connect(self.handle_github_status)
        self.connection_thread.server_status_checked.connect(self.handle_server_status)

        self.setWindowTitle("Stellaris DLC Unlocker")
        self.setWindowIcon(QIcon(f'{self.parent_directory}/UI/icons/stellaris.png'))

        self.bn_bug.clicked.connect(lambda: self.stackedWidget.setCurrentIndex(2))
        self.path_choose_button.clicked.connect(self.browse_folder)
        self.next_button.clicked.connect(
            lambda: (
                setattr(self, 'continued', True),
                self.stackedWidget.setCurrentIndex(1),
                self.old_dlc_show()
            )
        )
        self.bn_home.clicked.connect(lambda: self.stackedWidget.setCurrentIndex(1 if self.continued else 0))
        self.unlock_button.clicked.connect(self.unlock)
        self.done_button.clicked.connect(self.finish)

        self.bn_close.clicked.connect(
            lambda: self.close() if self.dialogexec(self.tr("Close"), self.tr("Exit Unlocker?"), self.tr("No"),
                                                    self.tr("Yes")) else None)

        self.bottom_label_github.linkActivated.connect(self.open_link_in_browser)
        self.logger = Logger('unlocker.log', self.log_widget)
        self.log_widget = self.log_widget
        self.log_widget.clear()

    def get_app_language(self):
        lang, _ = getlocale()
        if not lang:
            return "en"
        lang = lang.lower()
        if "russian" in lang:
            return "ru"
        elif "chinese" in lang:
            return "zh"
        else:
            return "en"


    def set_language_radio(self, lang):
        if lang == "ru":
            self.ru_lang.setChecked(True)
        elif lang == "zh":
            self.cn_lang.setChecked(True)
        else:
            self.en_lang.setChecked(True)

        self.apply_language(lang)

    def apply_language(self, lang):
        app = QApplication.instance()
        app.removeTranslator(self.translator)

        if lang == "ru":
            if self.translator.load(os.path.join("UI", "translations", "ru_RU.qm")):
                app.installTranslator(self.translator)
        elif lang == "zh":
            if self.translator.load(os.path.join("UI", "translations", "zh_CN.qm")):
                app.installTranslator(self.translator)

        self.retranslateUi(self)

    def showEvent(self, event):
        super(MainWindow, self).showEvent(event)
        self.set_language_radio(self.get_app_language())
        print('Start connection check')
        QTimer.singleShot(5, self.start_connection_check)
        print('Start updates check')
        QTimer.singleShot(4, lambda: self.check_for_updates(self.current_version))

    def switch_to_russian(self):
        if self.ru_lang.isChecked():
            if self.translator.load(os.path.join(self.parent_directory, "UI", "translations", "ru_RU.qm")):
                print("ru_RU translate Successfully loaded")
                QApplication.installTranslator(self.translator)
                self.retranslateUi(self)
            else:
                print("Unable to load ru_RU.qm")

    def switch_to_english(self):
        if self.en_lang.isChecked():
            QApplication.removeTranslator(self.translator)
            print("en-US translate Successfully loaded")
            self.retranslateUi(self)

    def switch_to_chinese(self):
        if self.cn_lang.isChecked():
            if self.translator.load(os.path.join(self.parent_directory, "UI", "translations", "zh_CN.qm")):
                print("zh_CN translate Successfully loaded")
                QApplication.installTranslator(self.translator)
                self.retranslateUi(self)
            else:
                print("Unable to load zh_CN.qm")

    @staticmethod
    def open_link_in_browser(url):
        print(f"Attempting to open URL: {url}")
        QDesktopServices.openUrl(QUrl(url))

    @staticmethod
    def kill_process(process_name):
        print(f'Killing {process_name}')
        try:
            run(["taskkill", "/F", "/IM", process_name], check=True, creationflags=CREATE_NO_WINDOW)
        except:
            print(f'No process named {process_name}')

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            self.is_dragging = True
            self.last_mouse_position = event.globalPos() - self.frameGeometry().topLeft()

    def mouseMoveEvent(self, event):
        if self.is_dragging:
            self.move(event.globalPos() - self.last_mouse_position)

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.LeftButton:
            self.is_dragging = False

    def dialogexec(self, heading, message, btn1, btn2, icon=":/icons/icons/1x/errorAsset 55.png"):
        print(f'Dialog exec {heading, message, btn1, btn2, icon}')
        dialogUi.dialogConstrict(self.diag, heading, message, btn1, btn2, icon, self)
        return self.diag.exec_()

    def errorexec(self, heading, btnOk, icon=":/icons/icons/1x/closeAsset 43.png", exitApp=False):
        print(f'Error exec {heading, btnOk, icon, exitApp}')
        errorUi.errorConstrict(self.error, heading, icon, btnOk, self, exitApp)
        self.error.exec_()

    def remove_compatibility(self, exe_path):
        exe_path = os.path.abspath(exe_path)
        keys = [
            (winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"),
            (winreg.HKEY_LOCAL_MACHINE, r"Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"),
        ]

        for root, subkey in keys:
            try:
                with winreg.OpenKey(root, subkey, 0, winreg.KEY_ALL_ACCESS) as key:
                    try:
                        value, regtype = winreg.QueryValueEx(key, exe_path)
                        print(f"Found compatibility parameter: {value} in {root}\\{subkey}")
                        winreg.DeleteValue(key, exe_path)
                        print(f"Compatibility parameter deleted: {exe_path}")
                    except FileNotFoundError:
                        print(f"Сompatibility for ({subkey}) parameters are not set")
                        pass
            except FileNotFoundError:
                continue

    def path_change(self):
        path = stellaris_path()
        if path:
            print(f'Auto detected game path: {path}')
            self.game_path_line.setText(path)
            self.game_path = path.replace("/", "\\")
            self.loadDLCNames()
        else:
            print(f'Cant detect game path')

    def browse_folder(self):
        directory = QFileDialog.getExistingDirectory(self, self.tr("Choose Stellaris path"),
                                                     self.game_path_line.text())
        if directory:
            if os.path.isfile(os.path.join(directory, "stellaris.exe")):
                self.game_path_line.setText(directory)
                self.game_path = directory.replace("/", "\\")
                print(f'Path browsed: {self.game_path}')
                self.loadDLCNames()
            else:
                print('Path browsed incorrectly')
                self.errorexec(self.tr("This is not Stellaris path"), self.tr("Ok"))

    def path_check(self):
        path = self.game_path_line.text().replace("/", "\\")
        try:
            if os.path.isfile(os.path.join(path, "stellaris.exe")):
                print(f'Game path: {path}')
                return path
        except:
            pass

        self.errorexec(self.tr("Please choose game path"), self.tr("Ok"))
        return False

    def old_dlc_show(self):
        if self.not_updated_dlc:
            print(f"Not updated DLCs: {self.not_updated_dlc}")
            self.update_dlc_button.setVisible(True)
            self.old_dlc_text.setVisible(True)
        else:
            self.update_dlc_button.setChecked(False)
            print("All DlCs is up to date or server return error")

    def check_for_updates(self, current_version):
        try:
            response = requests.get(self.GITHUB_REPO)
            if response.status_code == 200:
                response.raise_for_status()
                latest_release = response.json()
                latest_version = latest_release['tag_name']

                if latest_version != current_version:
                    print(f"Found new version: {latest_version}.")
                    if self.dialogexec(self.tr('New version'),
                                       self.tr('New version found\nPlease update the program to correctly work '),
                                       self.tr('Cancel'), self.tr('Update')):
                        exe_asset_url = None
                        for asset in latest_release['assets']:
                            if asset['name'].endswith('.exe'):
                                exe_asset_url = asset['browser_download_url']
                        self.open_link_in_browser(exe_asset_url)
                        self.close()
                else:
                    print(f"Unlocker is up to date")
        except:
            print("Cant check updates")
            pass

    def start_connection_check(self):
        self.connection_thread.start()

    def handle_github_status(self, status):
        if status:
            self.gh_status.setChecked(True)
            print('GitHub connection established')
        else:
            print('GitHub connection cant be established')
            self.errorexec(self.tr("Can't establish connection with GitHub. Check internet"), self.tr("Ok"),
                           exitApp=True)

    def handle_server_status(self, status):
        if status:
            self.server_status.setChecked(True)
            print('Server connection established')
        else:
            print('Server connection cant be established')
            if self.dialogexec(self.tr('Connection error'), self.tr(
                    'Cant establish connection with server\nCheck your connection or you can try download DLC directly\nUnzip downloaded "dlc" folder to game folder\nThen you can continue'),
                               self.tr("Exit"), self.tr("Open")):
                self.open_link_in_browser(self.server_alturl)
                self.alternative_unloc_checkbox.setEnabled(False)
            else:
                self.close()

    def loadDLCNames(self):
        self.dlc_status_widget.clear()
        self.not_updated_dlc = self.checkDLCUpdate()

        for dlc in self.dlc_data:
            dlc_name = dlc.get('dlc_name', '').strip()
            if not dlc_name:
                continue

            item = QListWidgetItem(dlc_name)

            status_color = self.checkDLCStatus(dlc.get('dlc_folder', ''))

            if status_color != 'black':
                item.setForeground(QBrush(QColor(status_color)))
                if status_color == "orange":
                    item.setText(item.text() + " (old)")
                self.dlc_status_widget.addItem(item)

    def checkDLCStatus(self, dlc_folder):
        if not dlc_folder:
            return "black"
        dlc_path_folder = os.path.join(self.game_path, "dlc", dlc_folder)
        dlc_path_zip = os.path.join(self.game_path, "dlc", f'{dlc_folder}.zip')
        if os.path.exists(dlc_path_folder) or os.path.exists(dlc_path_zip):
            if dlc_folder in self.not_updated_dlc:
                return "orange"
            return "teal"
        else:
            return "LightCoral"

    def checkDLCUpdate(self):
        md5_checker = MD5(f"{self.game_path}\\dlc", self.server_url)
        return md5_checker.check_files()

    def full_reinstall(self):
        try:
            print(f'Deleting documents folder...')
            user_home = os.path.join("C:\\Users", self.user_logon_name)
            rmtree(os.path.join(user_home, "Documents", "Paradox Interactive", "Stellaris"))
        except Exception as e:
            print(f'Cant delete {e}')
            pass

    def download_alt_method(self):
        print('Downloading alt launcher')
        file = argv[0]
        dir = os.path.dirname(file)
        print(f'Path to download: {dir}')
        self.downloaded_launcher_dir = f'{dir}\\launcher-installer-windows_2024.13.msi'
        print(f'Download path {self.downloaded_launcher_dir}')
        print(f'Path exist: {os.path.isfile(self.downloaded_launcher_dir)}')
        if os.path.isfile(self.downloaded_launcher_dir):
            return
        progress_dialog = QProgressDialog(self.tr('Alt launcher downloading'), None, 0, 100)
        progress_dialog.setWindowTitle(self.tr('Downloading'))
        progress_dialog.setWindowModality(2)
        progress_dialog.show()

        try:
            response = requests.get(
                f"https://{self.server_url}/unlocker/launcher-installer-windows_2024.13.msi",
                stream=True)
            total_size_in_bytes = int(response.headers.get('content-length', 0))
            block_size = 1024
            downloaded_bytes = 0

            with open(self.downloaded_launcher_dir, 'wb') as file:
                for data in response.iter_content(block_size):
                    download_breaked = 0
                    if progress_dialog.wasCanceled():
                        download_breaked = 1
                        break
                    file.write(data)
                    downloaded_bytes += len(data)
                    progress = int(downloaded_bytes / total_size_in_bytes * 100)
                    progress_dialog.setValue(progress)

        except Exception as e:
            print(f'Error while download alt launcher. Please try again or dont use this method Error: {e}')
            self.errorexec(self.tr("Cant download alt launcher"), self.tr("Ok"),
                           exitApp=True)

        finally:
            progress_dialog.close()
            if not download_breaked:
                self.launcher_downloaded = True
                print(f'Launcher downloaded {self.downloaded_launcher_dir}')

    def unlock(self):
        print('Unlocking...')
        if not self.path_check():
            print('Error: incorrect path, return')
            return
        self.game_path = self.game_path_line.text().replace("/", "\\")
        print('Unlock started')
        print(
            f'Settings:\nPath: {self.game_path}\nFull reinstall: {self.full_reinstall_checkbox.isChecked()}\nAlt unlock: {self.alternative_unloc_checkbox.isChecked()}\nSkip reinstall: {self.skip_launcher_reinstall_checbox.isChecked()}')
        self.unlock_button.setEnabled(False)
        self.game_path_line.setEnabled(False)
        self.path_choose_button.setEnabled(False)
        self.full_reinstall_checkbox.setEnabled(False)
        self.alternative_unloc_checkbox.setEnabled(False)
        self.skip_launcher_reinstall_checbox.setEnabled(False)
        self.update_dlc_button.setEnabled(False)
        self.copy_files_radio.setVisible(True)
        self.download_files_radio.setVisible(True)
        self.launcher_reinstall_radio.setVisible(True)
        self.progress_label.setVisible(True)
        self.dlc_download_label.setVisible(True)
        self.dlc_download_progress_bar.setVisible(True)
        self.current_dlc_label.setVisible(True)
        self.current_dlc_progress_bar.setVisible(True)
        self.speed_label.setVisible(True)
        if self.full_reinstall_checkbox.isChecked():
            self.full_reinstall()
        if self.alternative_unloc_checkbox.isChecked():
            self.download_alt_method()
        if not os.path.exists(os.path.join(self.game_path, "dlc")):
            os.makedirs(os.path.join(self.game_path, "dlc"))
        if self.game_path:
            try:
                self.remove_compatibility(f"{self.game_path}\stellaris.exe")
            except Exception as e:
                print(f"Cant remove compatibility: {e}")
                pass
            self.is_downloading = True
            if self.update_dlc_button.isChecked():
                print("Updating DLCs...")
                self.delete_folders(f"{self.game_path}\\dlc", self.not_updated_dlc)
                self.not_updated_dlc = []
            self.loadDLCNames()
            self.creamapi_maker = CreamAPI()
            self.creamapi_maker.progress_signal.connect(self.update_creamapi_progress)
            self.creamapi_maker.start()
            self.dlc_count = 0
            self.dlc_downloaded = 0
            self.download_queue = []

            def start_next_download():
                if self.download_queue:
                    file_url, save_path = self.download_queue.pop(0)
                    self.download_thread = DownloaderThread(file_url, save_path, self.dlc_downloaded, self.dlc_count)

                    # Подключаем сигналы к обработчикам
                    self.download_thread.progress_signal.connect(self.update_progress)
                    self.download_thread.progress_signal_2.connect(self.update_progress_2)
                    self.download_thread.error_signal.connect(self.show_error)
                    self.download_thread.speed_signal.connect(self.show_download_speed)
                    self.download_thread.finished.connect(
                        start_next_download)
                    self.download_thread.start()

            # Сначала заполняем очередь
            for item in self.dlc_data:
                if 'dlc_folder' in item and item['dlc_folder']:
                    self.dlc_count += 1
            for dlc in self.dlc_data:
                dlc_folder = dlc['dlc_folder']
                if dlc_folder == '':
                    continue
                file_url = f"https://{self.server_url}/unlocker/{dlc_folder}.zip"
                save_path = os.path.join(self.game_path, 'dlc', f'{dlc_folder}.zip')
                dlc_path = os.path.join(self.game_path, 'dlc', dlc_folder)

                if not os.path.exists(dlc_path) and self.is_invalid_zip(save_path):
                    if os.path.exists(save_path):
                        os.remove(save_path)
                    self.download_queue.append((file_url, save_path))
                else:
                    self.dlc_downloaded += 1
                    self.update_progress(int((self.dlc_downloaded / self.dlc_count) * 100))

            if self.download_queue:
                print('Starting downloads...')
                if self.server_status.isChecked():
                    start_next_download()
                else:
                    self.download_files_radio.setVisible(False)
                    self.progress_label.setVisible(False)
                    self.dlc_download_label.setVisible(False)
                    self.dlc_download_progress_bar.setVisible(False)
                    self.current_dlc_label.setVisible(False)
                    self.current_dlc_progress_bar.setVisible(False)
                    self.speed_label.setVisible(False)
                    self.reinstall()

    def update_creamapi_progress(self, value):
        if value == 100:
            self.creamapidone = True
            self.download_complete()

    @staticmethod
    def is_invalid_zip(path):
        if not os.path.exists(path):
            return True
        if os.path.getsize(path) == 0:
            return True
        try:
            with ZipFile(path, 'r') as zf:
                if zf.testzip() is not None:
                    return True
        except BadZipFile:
            return True
        return False

    @staticmethod
    def delete_folders(base_path, folders):
        base_path = Path(base_path)

        for name in folders:
            dir_path = base_path / name
            try:
                if dir_path.is_dir():
                    rmtree(dir_path)
                    print(f"Deleted: {dir_path}")
                else:
                    pass
            except Exception as e:
                print(f"Can't delete {dir_path}: {e}")

    def update_progress(self, value, by_download=False):
        self.dlc_download_progress_bar.setValue(value)
        if by_download:
            self.dlc_downloaded += 1
            self.update_progress(int((self.dlc_downloaded / self.dlc_count) * 100))
            self.loadDLCNames()
        if value == 100:
            self.speed_label.setText(f"")
            self.update_progress_2(100)
            # self.download_text_dlc(' ')
            self.download_complete()

    def update_progress_2(self, value):
        self.current_dlc_progress_bar.setValue(value)

    def show_download_speed(self, speed):
        self.speed_label.setText(f'{speed}MB/s')

    def show_error(self, error_message):
        print(f'DownloadThread error signal: {error_message}')
        self.errorexec(self.tr("File download error"), self.tr("Exit"), exitApp=True)

    def show_reinstall_error(self, error_message):
        print(f'ReinstallThread error signal: {error_message}')
        self.errorexec(self.tr("Launcher reinstall error"), self.tr("Exit"), exitApp=True)

    def download_complete(self):
        if self.dlc_download_progress_bar.value() == 100 and self.creamapidone == True:
            print('Dlc downloaded')
            self.reinstall()

    def reinstall(self):
        self.download_files_radio.setChecked(True)
        print('Reinstalling')
        paradox_folder1, paradox_folder2, paradox_folder3, paradox_folder4 = launcher_path()
        if not self.skip_launcher_reinstall_checbox.isChecked():
            self.reinstall_thread = ReinstallThread(self.game_path, paradox_folder1, paradox_folder2, paradox_folder3,
                                                    paradox_folder4, self.launcher_downloaded,
                                                    self.downloaded_launcher_dir, self.user_logon_name)
            # self.reinstall_thread.progress_signal.connect(self.update_reinstall_progress)
            self.reinstall_thread.error_signal.connect(self.show_reinstall_error)
            self.reinstall_thread.continue_reinstall.connect(self.reinstall_2)
            self.reinstall_thread.start()
        else:
            print('Reinstalling skipped')
            self.reinstall_2(paradox_folder1)

    def reinstall_2(self, paradox_folder1):

        launcher_folders = [item for item in os.listdir(paradox_folder1) if item.startswith("launcher")]
        launcher_folders.sort(key=lambda x: os.path.getmtime(os.path.join(paradox_folder1, x)))
        # launcher_folder = os.path.join(os.path.join(paradox_folder1, launcher_folders[0]))
        launcher_folders = [item for item in os.listdir(paradox_folder1) if item.startswith("launcher")]
        launcher_folders.sort(key=lambda x: os.path.getmtime(os.path.join(paradox_folder1, x)))
        # self.replace_files(os.path.join(os.path.join(paradox_folder1, launcher_folders[0])))
        try:
            self.replace_files(os.path.join(os.path.join(paradox_folder1, launcher_folders[0])))
        except Exception as e:
            print(f'Start replace files error: {e}')
            self.errorexec(self.tr("Launcher reinstall error"), self.tr("Exit"), exitApp=True)

    def replace_files(self, launcher_folder):
        self.launcher_reinstall_radio.setChecked(True)
        print('Replacing files')
        # try:
        #     rmtree(f'{self.game_path}/dlc')
        # except Exception:
        #     pass
        try:
            print('Unzipping...')
            zip_files = [file for file in os.listdir(os.path.join(self.game_path, 'dlc')) if file.endswith('.zip')]
            if zip_files:
                for zip_file in zip_files:
                    self.unzip_and_replace(zip_file)
        except Exception as e:
            print(f"Error while unzipping {e}")
            self.errorexec(self.tr("Error while unzipping"), self.tr("Exit"), exitApp=True)

        if os.path.exists(
                os.path.join(launcher_folder, 'resources', 'app.asar.unpacked', 'node_modules', 'greenworks', 'lib')):
            copy_to_path = os.path.join(launcher_folder, 'resources', 'app.asar.unpacked', 'node_modules', 'greenworks',
                                        'lib')
        elif os.path.exists(os.path.join(launcher_folder, 'resources', 'app', 'dist', 'main')):
            copy_to_path = os.path.join(launcher_folder, 'resources', 'app', 'dist', 'main')
        else:
            print('Error unknown launcher')
            self.errorexec(self.tr("Error unknown launcher"), self.tr("Exit"), exitApp=True)
        print(f'Copy to path: {copy_to_path}')
        # try: # C:\Users\sp21\AppData\Local\Programs\Paradox Interactive\launcher\launcher-v2.2024.14\resources\app.asar.unpacked\node_modules\greenworks\lib
        # o s.remove(f'{launcher_folder}/resources/{old_path}/dist/main/steam_api64_o.dll')
        # except:
        # pass
        try:
            os.remove(f'{launcher_folder}/xdelta3.exe')
        except:
            pass
        # os.rename(f'{launcher_folder}/resources/{old_path}/dist/main/steam_api64.dll',
        # f'{launcher_folder}/resources/{old_path}/dist/main/steam_api64_o.dll')
        copytree(f'{self.parent_directory}/creamapi_launcher_files',
                 f'{copy_to_path}',
                 dirs_exist_ok=True)
        copytree(f'{self.parent_directory}/creamapi_steam_files', self.game_path, dirs_exist_ok=True)
        print('Copy complete')
        self.copy_files_radio.setChecked(True)
        self.lauch_game_checkbox.setVisible(True)
        self.update_dlc_button.setVisible(False)
        self.old_dlc_text.setVisible(False)
        self.done_button.setVisible(True)
        print('All done!')

    def unzip_and_replace(self, dlc_path):
        zip_path = os.path.join(self.game_path, 'dlc', dlc_path)
        extract_folder = os.path.join(self.game_path, 'dlc')
        if not os.path.exists(extract_folder):
            os.makedirs(extract_folder)

        try:
            with ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(extract_folder)
            os.remove(zip_path)
            return extract_folder
        except Exception as e:
            print(f'Error while unzipping {e}')
            self.errorexec(self.tr("Error while unzipping"), self.tr("Exit"), exitApp=True)

    def finish(self):
        if self.lauch_game_checkbox.isChecked():
            try:
                run('start steam://run/281990', shell=True, capture_output=True, text=True)
            except:
                pass
        self.close()
