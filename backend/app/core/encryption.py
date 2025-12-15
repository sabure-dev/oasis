import base64
import hashlib

from cryptography.fernet import Fernet

from config import settings


def _get_cipher():
    key = hashlib.sha256(settings.SECRET_KEY.encode()).digest()
    key_b64 = base64.urlsafe_b64encode(key)
    return Fernet(key_b64)


def encrypt_password(password: str) -> str:
    cipher = _get_cipher()
    return cipher.encrypt(password.encode()).decode()


def decrypt_password(token: str) -> str:
    cipher = _get_cipher()
    return cipher.decrypt(token.encode()).decode()
