"""Configuración explícita. No lee .env, llavero ni fuentes privadas."""

import ipaddress
import math
import os
from collections.abc import Mapping
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import urlsplit


def _local_host(host: str | None) -> bool:
    if host == "localhost":
        return True
    try:
        return ipaddress.ip_address(host or "").is_loopback
    except ValueError:
        return False


def _validate_url(value: str, *, origin: bool) -> None:
    try:
        url = urlsplit(value)
        port = url.port
        valid = (
            url.scheme in {"http", "https"}
            and bool(url.hostname)
            and not url.username
            and not url.password
            and not url.query
            and not url.fragment
            and (port is None or 1 <= port <= 65535)
            and "*" not in value
            and not any(c.isspace() for c in value)
        )
        if origin:
            valid = valid and _local_host(url.hostname) and url.path == ""
        else:
            valid = valid and (url.scheme == "https" or _local_host(url.hostname))
        if not valid:
            raise ValueError
    except ValueError:
        label = "ALLOWED_ORIGINS" if origin else "OPENAI_BASE_URL"
        raise ValueError(f"{label}: URL no permitida") from None


@dataclass(frozen=True)
class Settings:
    jwt_secret: str = field(repr=False)
    db_path: Path = Path("./data/btohabitos.sqlite3")
    jwt_expires_seconds: int = 3600
    allowed_origins: tuple[str, ...] = (
        "http://127.0.0.1:18311", "http://localhost:18311",
    )
    openai_base_url: str = ""
    openai_api_key: str = field(default="", repr=False)
    openai_model: str = ""
    openai_timeout_seconds: float = 30.0
    openai_disable_thinking: bool = False

    def __post_init__(self) -> None:
        if not isinstance(self.jwt_secret, str) or len(self.jwt_secret.encode("utf-8")) < 32 or not self.jwt_secret.strip():
            raise ValueError("JWT_SECRET es obligatorio y debe tener al menos 32 bytes")
        if type(self.jwt_expires_seconds) is not int or self.jwt_expires_seconds <= 0:
            raise ValueError("JWT_EXPIRES_SECONDS debe ser un entero positivo")
        if not math.isfinite(self.openai_timeout_seconds) or not 0 < self.openai_timeout_seconds <= 30:
            raise ValueError("OPENAI_TIMEOUT_SECONDS debe ser mayor que 0 y como máximo 30")
        if type(self.openai_disable_thinking) is not bool:
            raise ValueError("OPENAI_DISABLE_THINKING debe ser true o false")
        if str(self.db_path) == ":memory:":
            raise ValueError("DB_PATH debe indicar un archivo SQLite persistente")
        object.__setattr__(self, "db_path", Path(self.db_path).expanduser().absolute())
        for origin in self.allowed_origins:
            _validate_url(origin, origin=True)
        if self.openai_base_url:
            _validate_url(self.openai_base_url, origin=False)
            object.__setattr__(self, "openai_base_url", self.openai_base_url.rstrip("/"))
        if self.openai_model and (len(self.openai_model) > 200 or any(c.isspace() for c in self.openai_model)):
            raise ValueError("OPENAI_MODEL debe ser un identificador sin espacios de hasta 200 caracteres")

    @property
    def provider_configured(self) -> bool:
        return all((self.openai_base_url, self.openai_api_key, self.openai_model))

    @classmethod
    def from_env(cls, env: Mapping[str, str] | None = None) -> "Settings":
        values = os.environ if env is None else env
        try:
            ttl = int(values.get("JWT_EXPIRES_SECONDS", values.get("TOKEN_TTL_SECONDS", "3600")))
            timeout = float(values.get("OPENAI_TIMEOUT_SECONDS", "30"))
        except (ValueError, TypeError):
            raise ValueError("JWT_EXPIRES_SECONDS y OPENAI_TIMEOUT_SECONDS deben ser numéricos") from None
        thinking = values.get("OPENAI_DISABLE_THINKING", "false").strip().lower()
        if thinking not in {"true", "false"}:
            raise ValueError("OPENAI_DISABLE_THINKING debe ser true o false")
        db_path = values.get("DB_PATH", "./data/btohabitos.sqlite3")
        if not db_path.strip():
            raise ValueError("DB_PATH no puede estar vacío")
        return cls(
            jwt_secret=values.get("JWT_SECRET", ""),
            db_path=Path(db_path),
            jwt_expires_seconds=ttl,
            allowed_origins=tuple(x.strip() for x in values.get(
                "ALLOWED_ORIGINS", "http://127.0.0.1:18311,http://localhost:18311",
            ).split(",") if x.strip()),
            openai_base_url=values.get("OPENAI_BASE_URL", "").strip(),
            openai_api_key=values.get("OPENAI_API_KEY", "").strip(),
            openai_model=values.get("OPENAI_MODEL", "").strip(),
            openai_timeout_seconds=timeout,
            openai_disable_thinking=thinking == "true",
        )
