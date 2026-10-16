"""scrypt estándar y JWT HS256 con biblioteca; no se implementa JWT a mano."""

import base64
import hashlib
import hmac
import secrets
import time

import jwt

from .config import Settings

SCRYPT_N = 32768
SCRYPT_R = 8
SCRYPT_P = 1


def _derive(password: str, salt: bytes) -> bytes:
    return hashlib.scrypt(
        password.encode("utf-8"), salt=salt, n=SCRYPT_N, r=SCRYPT_R,
        p=SCRYPT_P, dklen=32, maxmem=64 * 1024 * 1024,
    )


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = _derive(password, salt)
    return "$".join(("scrypt", str(SCRYPT_N), str(SCRYPT_R), str(SCRYPT_P),
                     base64.b64encode(salt).decode("ascii"), base64.b64encode(digest).decode("ascii")))


def verify_password(password: str, encoded: str) -> bool:
    try:
        algorithm, n, r, p, salt_b64, digest_b64 = encoded.split("$")
        if (algorithm, n, r, p) != ("scrypt", str(SCRYPT_N), str(SCRYPT_R), str(SCRYPT_P)):
            return False
        salt = base64.b64decode(salt_b64, validate=True)
        digest = base64.b64decode(digest_b64, validate=True)
        return len(salt) == 16 and len(digest) == 32 and hmac.compare_digest(_derive(password, salt), digest)
    except (ValueError, TypeError):
        return False


# Permite derivar también en un login inexistente sin una contraseña utilizable.
DUMMY_HASH = hash_password(secrets.token_urlsafe(32))


def issue_token(user_id: int, settings: Settings) -> str:
    now = int(time.time())
    return jwt.encode(
        {"sub": str(user_id), "iat": now, "exp": now + settings.jwt_expires_seconds},
        settings.jwt_secret, algorithm="HS256",
    )


def token_user_id(token: str, settings: Settings) -> int:
    payload = jwt.decode(
        token, settings.jwt_secret, algorithms=["HS256"],
        options={"require": ["sub", "iat", "exp"]}, leeway=0,
    )
    subject = payload["sub"]
    if not isinstance(subject, str) or not subject.isascii() or not subject.isdecimal() or int(subject) < 1:
        raise jwt.InvalidTokenError("Sujeto no válido")
    if type(payload["iat"]) is not int or type(payload["exp"]) is not int or payload["exp"] <= payload["iat"]:
        raise jwt.InvalidTokenError("Fechas no válidas")
    return int(subject)
