import secrets
import sqlite3

import pytest

from app.config import Settings
from app.main import create_app
from conftest import create_account


@pytest.mark.parametrize("secret", ["", "corto", "a" * 31, " " * 32])
def test_secret_required_minimum_utf8_bytes(secret):
    with pytest.raises(ValueError, match="JWT_SECRET"):
        Settings(jwt_secret=secret)
    with pytest.raises(ValueError, match="JWT_SECRET"):
        create_app(Settings.from_env({"JWT_SECRET": secret}))


def test_factory_environment_config_and_legacy_ttl_precedence(tmp_path, monkeypatch):
    values = {"JWT_SECRET": secrets.token_urlsafe(48), "DB_PATH": str(tmp_path / "env.sqlite3"), "TOKEN_TTL_SECONDS": "200", "JWT_EXPIRES_SECONDS": "123", "ALLOWED_ORIGINS": "http://localhost:18311", "OPENAI_TIMEOUT_SECONDS": "2.5", "OPENAI_DISABLE_THINKING": "true"}
    config = Settings.from_env(values)
    assert config.db_path == tmp_path / "env.sqlite3" and config.jwt_expires_seconds == 123
    assert config.allowed_origins == ("http://localhost:18311",) and config.openai_disable_thinking is True
    assert config.openai_timeout_seconds == 2.5 and config.provider_configured is False
    assert values["JWT_SECRET"] not in repr(config)
    legacy = Settings.from_env({"JWT_SECRET": values["JWT_SECRET"], "TOKEN_TTL_SECONDS": "200"})
    assert legacy.jwt_expires_seconds == 200
    # Sustituye la referencia al entorno por datos sintéticos, sin leer valores privados del proceso.
    monkeypatch.setattr("app.config.os.environ", values)
    app = create_app()
    assert app.state.settings == config
    assert not config.db_path.exists(), "La factory no debe crear una base antes de lifespan"


@pytest.mark.parametrize("key,value", [
    ("JWT_EXPIRES_SECONDS", "0"), ("JWT_EXPIRES_SECONDS", "-1"), ("JWT_EXPIRES_SECONDS", "1.5"),
    ("OPENAI_TIMEOUT_SECONDS", "0"), ("OPENAI_TIMEOUT_SECONDS", "30.1"), ("OPENAI_TIMEOUT_SECONDS", "nan"), ("OPENAI_TIMEOUT_SECONDS", "inf"), ("OPENAI_TIMEOUT_SECONDS", "texto"),
    ("OPENAI_DISABLE_THINKING", "si"), ("DB_PATH", ""), ("DB_PATH", ":memory:"),
    ("OPENAI_BASE_URL", "http://proveedor.example.com/v1"),
    ("OPENAI_BASE_URL", "https://usuario:password@example.com/v1"),
    ("OPENAI_BASE_URL", "https://example.com/v1?clave=privada"),
    ("ALLOWED_ORIGINS", "*"), ("ALLOWED_ORIGINS", "https://externo.example.com"),
    ("ALLOWED_ORIGINS", "http://localhost:18311/path"),
    ("ALLOWED_ORIGINS", "http://localhost:18311/"),
])
def test_configuration_rejects_invalid_values_without_echo(key, value):
    with pytest.raises(ValueError) as error:
        Settings.from_env({"JWT_SECRET": secrets.token_urlsafe(48), key: value})
    assert key in str(error.value) or key in {"JWT_EXPIRES_SECONDS", "OPENAI_TIMEOUT_SECONDS"}
    assert "password@example" not in str(error.value) and "clave=privada" not in str(error.value)


def test_https_or_local_provider_and_explicit_cors(client):
    for url in ["http://127.0.0.1:18312/v1", "http://localhost:18312/v1", "https://api.example.com/v1"]:
        assert Settings(jwt_secret=secrets.token_urlsafe(48), openai_base_url=url).openai_base_url == url
    allowed = client.options("/habitos", headers={"Origin": "http://localhost:18311", "Access-Control-Request-Method": "POST", "Access-Control-Request-Headers": "authorization,content-type"})
    assert allowed.status_code == 200 and allowed.headers["access-control-allow-origin"] == "http://localhost:18311"
    denied = client.options("/habitos", headers={"Origin": "https://externo.example.com", "Access-Control-Request-Method": "POST"})
    assert denied.status_code == 400 and "access-control-allow-origin" not in denied.headers
    assert client.get("/health").json() == {"status": "ok"}
    assert client.get("/health").text == '{"status":"ok"}'


@pytest.mark.parametrize("error,expected", [(sqlite3.OperationalError("clave y ruta privadas"), 503), (RuntimeError("token y prompt privados"), 500)])
def test_database_and_unexpected_errors_are_sanitized(client, monkeypatch, caplog, error, expected):
    _, headers = create_account(client)

    def fail():
        raise error

    monkeypatch.setattr(client.app.state.db, "connect", fail)
    response = client.get("/habitos", headers=headers)
    assert response.status_code == expected and set(response.json()) == {"detail"}
    assert str(error) not in response.text and str(error) not in caplog.text


def test_malformed_json_error_does_not_echo_credentials(client):
    response = client.post("/auth/register", content=b'{"password":"NoMostrar123!","email":', headers={"Content-Type": "application/json"})
    assert response.status_code == 422 and "NoMostrar123!" not in response.text


def test_openapi_routes_and_strict_contract(client):
    schema = client.get("/openapi.json").json()
    assert set(schema["paths"]) == {"/health", "/auth/register", "/auth/login", "/auth/me", "/plantillas", "/habitos", "/habitos/{id}", "/asistente"}
    assert schema["components"]["schemas"]["HabitoCrear"]["additionalProperties"] is False
    assert set(schema["paths"]["/habitos"]) == {"get", "post"}
