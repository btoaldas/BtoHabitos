import logging
import secrets
import time

import jwt
import pytest

from app.security import hash_password, verify_password
from conftest import PASSWORD, create_account


def test_register_normalize_duplicate_login_and_me(client, settings, caplog):
    caplog.set_level(logging.INFO)
    response = client.post("/auth/register", json={"email": "  Persona.A@EXAMPLE.COM  ", "password": PASSWORD})
    assert response.status_code == 201
    user = response.json()
    assert set(user) == {"id", "email"} and user["email"] == "persona.a@example.com"
    duplicate = client.post("/auth/register", json={"email": user["email"], "password": PASSWORD})
    assert duplicate.status_code == 400 and isinstance(duplicate.json()["detail"], str)
    response = client.post("/auth/login", json={"email": "PERSONA.A@example.com", "password": PASSWORD})
    assert response.status_code == 200
    session = response.json()
    assert set(session) == {"access_token", "token_type", "expires_in", "user"}
    assert session["user"] == user and session["token_type"] == "bearer" and session["expires_in"] == 3600
    claims = jwt.decode(session["access_token"], settings.jwt_secret, algorithms=["HS256"])
    assert claims["sub"] == str(user["id"]) and claims["exp"] - claims["iat"] == 3600
    me = client.get("/auth/me", headers={"Authorization": "Bearer " + session["access_token"]})
    assert me.status_code == 200 and me.json() == user
    for email, password in [(user["email"], "ClaveIncorrecta123"), ("ausente@example.com", PASSWORD)]:
        invalid = client.post("/auth/login", json={"email": email, "password": password})
        assert invalid.status_code == 401 and invalid.json()["detail"] == "Correo o contraseña incorrectos"
    with client.app.state.db.connect() as conn:
        row = dict(conn.execute("SELECT * FROM users").fetchone())
    assert row["email"] == user["email"] and row["password_hash"].startswith("scrypt$32768$8$1$")
    assert PASSWORD not in str(row) and verify_password(PASSWORD, row["password_hash"])
    assert row["created_at"].endswith("Z")
    for private in [PASSWORD, session["access_token"], settings.jwt_secret, user["email"]]:
        assert private not in caplog.text


def test_hashes_random_salts_and_database_users(client):
    for email in ["salta@example.com", "saltb@example.com"]:
        assert client.post("/auth/register", json={"email": email, "password": PASSWORD}).status_code == 201
    with client.app.state.db.connect() as conn:
        hashes = [row[0] for row in conn.execute("SELECT password_hash FROM users ORDER BY id")]
    assert len(hashes) == 2 and hashes[0] != hashes[1]
    assert hashes[0].split("$")[4] != hashes[1].split("$")[4]
    assert all(verify_password(PASSWORD, value) and not verify_password("incorrecta", value) for value in hashes)


@pytest.mark.parametrize("encoded", ["", "not-scrypt", "scrypt$999999999$8$1$xxx$xxx", "scrypt$32768$8$1$!!!!$!!!!"])
def test_corrupt_derivation_rejected(encoded):
    assert verify_password(PASSWORD, encoded) is False


PROTECTED = [
    ("GET", "/auth/me", None), ("GET", "/plantillas", None),
    ("GET", "/habitos", None),
    ("POST", "/habitos", {"titulo": "Prueba", "categoria": "organizacion", "frecuencia": "diaria", "tipo": "habito"}),
    ("PATCH", "/habitos/1", {"titulo": "Cambio"}), ("DELETE", "/habitos/1", None),
    ("POST", "/asistente", {"consulta": "Una idea"}),
]


@pytest.mark.parametrize("method,path,body", PROTECTED)
@pytest.mark.parametrize("kind", ["ausente", "expirado", "manipulado"])
def test_every_protected_operation_rejects_invalid_auth(client, settings, method, path, body, kind):
    user, valid_headers = create_account(client)
    assert client.get("/auth/me", headers=valid_headers).json() == user
    now = int(time.time())
    claims = {"sub": str(user["id"]), "iat": now - 120, "exp": now - 1 if kind == "expirado" else now + 3600}
    token = jwt.encode(claims, settings.jwt_secret if kind == "expirado" else secrets.token_urlsafe(48), algorithm="HS256")
    headers = {} if kind == "ausente" else {"Authorization": "Bearer " + token}
    response = client.request(method, path, json=body, headers=headers)
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"
    assert set(response.json()) == {"detail"} and isinstance(response.json()["detail"], str)
    with client.app.state.db.connect() as conn:
        assert conn.execute("SELECT COUNT(*) FROM habitos").fetchone()[0] == 0


@pytest.mark.parametrize("token_kind", ["none", "hs384", "missing_exp", "future", "bad_subject", "missing_user", "string_exp"])
def test_token_algorithm_claims_and_user_checked(client, settings, token_kind):
    user, _ = create_account(client)
    now = int(time.time())
    claims = {"sub": str(user["id"]), "iat": now, "exp": now + 3600}
    algorithm = "HS256"
    key = settings.jwt_secret
    if token_kind == "none":
        algorithm, key = "none", None
    elif token_kind == "hs384":
        algorithm = "HS384"
    elif token_kind == "missing_exp":
        claims.pop("exp")
    elif token_kind == "future":
        claims.update(iat=now + 600, exp=now + 3600)
    elif token_kind == "bad_subject":
        claims["sub"] = "../otro"
    elif token_kind == "missing_user":
        claims["sub"] = "9999999"
    elif token_kind == "string_exp":
        claims["exp"] = str(now + 3600)
    token = jwt.encode(claims, key, algorithm=algorithm)
    assert client.get("/auth/me", headers={"Authorization": "Bearer " + token}).status_code == 401


@pytest.mark.parametrize("body", [
    {"email": "inválido", "password": PASSWORD},
    {"email": "a@example.com", "password": "corta"},
    {"email": "a@example.com", "password": "x" * 129},
    {"email": 4, "password": PASSWORD},
    {"email": "a@example.com", "password": PASSWORD, "user_id": 8},
])
@pytest.mark.parametrize("route", ["/auth/register", "/auth/login"])
def test_credentials_strict_and_error_sanitized(client, body, route):
    response = client.post(route, json=body)
    assert response.status_code == 422 and set(response.json()) == {"detail"}
    assert PASSWORD not in response.text and "password_hash" not in response.text and "input" not in response.text


def test_bearer_scheme(client):
    for header in ["Basic abc", "Bearer", "Bearer not.a.token"]:
        assert client.get("/auth/me", headers={"Authorization": header}).status_code == 401
