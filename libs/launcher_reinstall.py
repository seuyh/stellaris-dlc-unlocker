import os
from shutil import rmtree, move
from subprocess import Popen
from PyQt5 import QtCore
from time import sleep
from glob import glob


class ReinstallThread(QtCore.QThread):
    progress_signal = QtCore.pyqtSignal(int)
    error_signal = QtCore.pyqtSignal(Exception)
    continue_reinstall = QtCore.pyqtSignal(str)

    def __init__(self, msi_path, paradox_folder1, paradox_folder2, paradox_folder3, paradox_folder4,
                 launcher_downloaded, downloaded_launcher_dir):
        super().__init__()
        self.msi_path = msi_path
        self.paradox_folder1 = paradox_folder1
        self.paradox_folder2 = paradox_folder2
        self.paradox_folder3 = paradox_folder3
        self.paradox_folder4 = paradox_folder4
        self.launcher_downloaded = launcher_downloaded
        self.downloaded_launcher_dir = downloaded_launcher_dir

    def run(self):
        msi_files = glob(os.path.join(self.msi_path, "launcher-installer-windows_*.msi"))
        if msi_files:
            msi_path = msi_files[0]
        else:
            msi_path = os.path.join(self.msi_path, "launcher-installer-windows.msi")
            if os.path.exists(msi_path):
                pass
            else:
                self.error_signal.emit('launcher_installer not found!')
        print(f'Требуется ли подмена лаунчера: {self.launcher_downloaded}')
        if self.launcher_downloaded:
            os.remove(msi_path)
            move(self.downloaded_launcher_dir, msi_path)
        print(f'Путь к игре: {self.msi_path}')
        print(f'Путь к лаунчеру: {msi_path}\nСуществует ли путь: {os.path.exists(msi_path)}')
        print(f'Выполнение удаления')
        try:
            self.paradox_remove(self.paradox_folder1, self.paradox_folder2, self.paradox_folder3, self.paradox_folder4)

            uninstall = Popen(['cmd.exe', '/c', 'msiexec', '/uninstall',
                               msi_path, '/quiet'], shell=True)
            # output, error = uninstall.communicate()
            # if uninstall.returncode != 0:
            #     print("Произошла ошибка при удалении:", error.decode())

            uninstall.wait()
            self.progress_signal.emit(33)
            sleep(1)
            print(f'Выполнение установки')
            install = Popen(
                ['cmd.exe', '/c', 'msiexec', '/package', msi_path,
                 '/quiet', 'CREATE_DESKTOP_SHORTCUT=0'], shell=True)
            # output, error = install.communicate()
            # if uninstall.returncode != 0:
            #     print("Произошла ошибка при установке:", error.decode())
            install.wait()
            self.progress_signal.emit(66)
            self.continue_reinstall.emit(self.paradox_folder1)
        except Exception as e:
            self.error_signal.emit(e)

    @staticmethod
    def paradox_remove(paradox_folder1, paradox_folder2, paradox_folder3, paradox_folder4):
        # user_home = os.path.expanduser("~")
        # paradox_folder1 = os.path.join(user_home, "AppData", "Local", "Programs", "Paradox Interactive")
        # paradox_folder2 = os.path.join(user_home, "AppData", "Local", "Paradox Interactive")
        # paradox_folder3 = os.path.join(user_home, "AppData", "Roaming", "Paradox Interactive")
        # paradox_folder4 = os.path.join(user_home, "AppData", "Roaming", "paradox-launcher-v2")
        try:
            if os.path.exists(paradox_folder1):
                rmtree(paradox_folder1)

            if os.path.exists(paradox_folder2):
                rmtree(paradox_folder2)

            if os.path.exists(paradox_folder3):
                rmtree(paradox_folder3)

            if os.path.exists(paradox_folder4):
                rmtree(paradox_folder4)
        except Exception:
            pass
