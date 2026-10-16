"""Fixtures sintéticas: ninguna consulta externa ni lectura de .env."""

import secrets
import uuid
from dataclasses import replace
from pathlib import Path

import httpx
import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app

PASSWORD = "SoloPruebas-123!"
HABIT = {
    "titulo": "Lectura sintética",
    "descripcion": "Detalle privado sintético A",
    "categoria": "aprendizaje", "frecuencia": "diaria", "tipo": "habito",
}


def pytest_configure(config):
    """Retener fixtures dentro del alcance y evitar la purga implícita de --basetemp."""
    root = Path(__file__).resolve().parent / ".runs"
    requested = config.option.basetemp
    target = Path(requested).absolute() if requested else root / ("pytest-" + uuid.uuid4().hex)
    if not target.resolve().is_relative_to(root.resolve()):
        raise pytest.UsageError("Use un --basetemp nuevo dentro de server/tests/.runs")
    if target.exists():
        raise pytest.UsageError("No se reutiliza ni purga --basetemp existente; indique una ruta nueva")
    target.parent.mkdir(parents=True, exist_ok=True)
    config.option.basetemp = str(target)


@pytest.fixture
def settings(tmp_path):
    return Settings(jwt_secret=secrets.token_urlsafe(48), db_path=tmp_path / "api.sqlite3")


@pytest.fixture
def make_client(settings):
    clients = []

    def factory(handler=None, **overrides):
        def no_network(request):
            raise AssertionError("Una prueba intentó consultar un proveedor no declarado")

        config = replace(settings, **overrides)
        app = create_app(config, transport=httpx.MockTransport(handler or no_network))
        client = TestClient(app)
        client.__enter__()
        clients.append(client)
        return client

    yield factory
    for client in reversed(clients):
        client.__exit__(None, None, None)


@pytest.fixture
def client(make_client):
    return make_client()


def create_account(client, email="persona.a@example.com"):
    response = client.post("/auth/register", json={"email": email, "password": PASSWORD})
    assert response.status_code == 201, response.text
    login = client.post("/auth/login", json={"email": email, "password": PASSWORD})
    assert login.status_code == 200, login.text
    data = login.json()
    return data["user"], {"Authorization": "Bearer " + data["access_token"]}


@pytest.fixture
def accounts(client):
    a, a_headers = create_account(client)
    b, b_headers = create_account(client, "persona.b@example.com")
    return a, a_headers, b, b_headers


def provider_response(content, *, finish="stop"):
    import json
    text = json.dumps(content, ensure_ascii=False) if not isinstance(content, str) else content
    return httpx.Response(200, json={
        "choices": [{"finish_reason": finish, "message": {"role": "assistant", "content": text}}],
    })
