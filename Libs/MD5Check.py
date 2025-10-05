import os
import hashlib
import requests

class MD5:
    def __init__(self, game_path, url):
        self.game_path = game_path
        self.url = url
        self.prefix_to_remove = f"files/www/{url}/unlocker/files/"
        self.hashes_url = f"https://{url}/unlocker/hashes.txt"
        self.server_hashes = self._load_server_hashes()

    def _load_server_hashes(self):
        try:
            response = requests.get(self.hashes_url, timeout=10)
            response.raise_for_status()
            if not response.text.strip():
                return None

            lines = response.text.splitlines()
            hashes = {}
            for line in lines:
                server_hash, file_path = line.split()
                clean_path = file_path.replace(self.prefix_to_remove, "")
                hashes[clean_path] = server_hash
            return hashes
        except (requests.RequestException, ValueError):
            return None

    def calculate_md5(self, file_path):
        hash_md5 = hashlib.md5()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()

    def check_files(self):
        if self.server_hashes is None:
            return []

        mismatched_folders = []

        for relative_path, server_hash in self.server_hashes.items():
            local_path = os.path.join(self.game_path, relative_path)

            if os.path.isdir(local_path.split('/', 1)[0]):
                if os.path.isfile(local_path):
                    local_hash = self.calculate_md5(local_path)
                    if local_hash != server_hash:
                        folder = os.path.dirname(relative_path)
                        if folder not in mismatched_folders:
                            mismatched_folders.append(folder)
                else:
                    folder = os.path.dirname(relative_path)
                    if folder not in mismatched_folders:
                        mismatched_folders.append(folder)

        return mismatched_folders
