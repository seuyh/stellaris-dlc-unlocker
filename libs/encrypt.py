from cryptography.fernet import Fernet


def encrypt(message, key):
    cipher_suite = Fernet(key)
    encrypted_text = cipher_suite.encrypt(message.encode())
    return encrypted_text


def decrypt(encrypted_text, key):
    cipher_suite = Fernet(key)
    decrypted_text = cipher_suite.decrypt(encrypted_text).decode()
    return decrypted_text
