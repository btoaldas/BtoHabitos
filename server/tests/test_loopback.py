"""Segundo ángulo: Uvicorn real en socket loopback propio y puerto efímero."""

import secrets
import socket
import subprocess
import sys
import time
from pathlib import Path

import httpx


def test_real_uvicorn_process_with_two_accounts_and_sqlite(tmp_path):
    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
    code = '''
import socket, sys, uvicorn
from app.main import create_app
sock = socket.socket(fileno=int(sys.argv[1]))
server = uvicorn.Server(uvicorn.Config(create_app(), log_level="warning", access_log=False))
server.run(sockets=[sock])
'''
    process = subprocess.Popen(
        [sys.executable, "-c", code, str(sock.fileno())],
        pass_fds=(sock.fileno(),), cwd=Path(__file__).resolve().parents[1],
        env={"JWT_SECRET": secrets.token_urlsafe(48), "DB_PATH": str(tmp_path / "loopback.sqlite3"), "PYTHONDONTWRITEBYTECODE": "1"},
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    sock.close()
    try:
        with httpx.Client(base_url=f"http://127.0.0.1:{port}", trust_env=False, timeout=2) as api:
            deadline = time.monotonic() + 8
            while True:
                assert process.poll() is None, "Uvicorn terminó antes de atender"
                try:
                    response = api.get("/health")
                    if response.status_code == 200:
                        break
                except httpx.TransportError:
                    pass
                assert time.monotonic() < deadline, "Uvicorn no inició en el tiempo esperado"
                time.sleep(0.02)
            assert response.json() == {"status": "ok"}
            assert api.get("/plantillas").status_code == 401
            headers = []
            for email in ["loopback.a@example.com", "loopback.b@example.com"]:
                body = {"email": email, "password": "PruebaLocal123!"}
                assert api.post("/auth/register", json=body).status_code == 201
                login = api.post("/auth/login", json=body)
                assert login.status_code == 200
                headers.append({"Authorization": "Bearer " + login.json()["access_token"]})
            ah, bh = headers
            assert len(api.get("/plantillas", headers=ah).json()) == 21
            created = api.post("/habitos", headers=ah, json={"titulo": "Prueba por socket real", "categoria": "organizacion", "frecuencia": "semanal", "tipo": "tarea"})
            assert created.status_code == 201
            habit = created.json()
            assert api.get("/habitos", headers=ah).json() == [habit]
            assert api.get("/habitos", headers=bh).json() == []
            assert api.patch(f'/habitos/{habit["id"]}', headers=bh, json={"titulo": "Cambio ajeno"}).status_code == 404
            assert api.post("/asistente", headers=ah, json={"consulta": "Idea"}).status_code == 503
            import sqlite3
            with sqlite3.connect(tmp_path / "loopback.sqlite3") as conn:
                assert conn.execute("SELECT titulo FROM habitos").fetchall() == [("Prueba por socket real",)]
    finally:
        process.terminate()
        stdout, stderr = process.communicate(timeout=8)
    assert stdout == "" and stderr == "", (stdout, stderr)
