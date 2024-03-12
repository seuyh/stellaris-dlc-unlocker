import os
from shutil import rmtree
from subprocess import Popen
from PyQt5 import QtCore
from time import sleep


class ReinstallThread(QtCore.QThread):
    progress_signal = QtCore.pyqtSignal(int)
    error_signal = QtCore.pyqtSignal(Exception)
    continue_reinstall = QtCore.pyqtSignal(str)

    def __init__(self, msi_path, paradox_folder1, paradox_folder2, paradox_folder3, paradox_folder4):
        super().__init__()
        self.msi_path = msi_path
        self.paradox_folder1 = paradox_folder1
        self.paradox_folder2 = paradox_folder2
        self.paradox_folder3 = paradox_folder3
        self.paradox_folder4 = paradox_folder4
        self.msi_path = 'D:\\steam\\steamapps\\common\\Stellaris'

    def run(self):
        try:
            self.paradox_remove(self.paradox_folder1, self.paradox_folder2, self.paradox_folder3, self.paradox_folder4)

            uninstall = Popen(['cmd.exe', '/c', 'msiexec', '/uninstall',
                               os.path.join(self.msi_path, "launcher-installer-windows.msi"), '/quiet'], shell=True)

            while uninstall.poll() is None:  # Проверяем, завершился ли процесс
                sleep(0.1)
            self.progress_signal.emit(33)
            sleep(1)
            install = Popen(
                ['cmd.exe', '/c', 'msiexec', '/package', os.path.join(self.msi_path, "launcher-installer-windows.msi"),
                 '/quiet', 'CREATE_DESKTOP_SHORTCUT=0'], shell=True)
            while install.poll() is None:  # Проверяем, завершился ли процесс
                sleep(0.1)
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
