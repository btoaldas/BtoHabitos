import json
import sqlite3
import subprocess
import sys
from pathlib import Path

import pytest

from app.db import Database, SEED_PATH
from app.schemas import Plantilla
from conftest import HABIT, PASSWORD, create_account


def test_seed_twice_same_ids_preserves_habits_and_catalog_edits(client):
    _, headers = create_account(client)
    catalog = client.get("/plantillas", headers=headers)
    assert catalog.status_code == 200
    rows = catalog.json()
    ids = [r["id"] for r in rows]
    assert len(rows) == len(set(ids)) == 21
    assert rows == json.loads(SEED_PATH.read_text())
    for row in rows:
        assert set(row) == {"id", "titulo", "descripcion", "categoria", "frecuencia", "tipo"}
        Plantilla.model_validate(row)
    saved = client.post("/habitos", headers=headers, json={**HABIT, "plantilla_id": ids[0]}).json()
    db = client.app.state.db
    with db.connect() as conn:
        conn.execute("UPDATE plantillas SET titulo = ? WHERE id = ?", ("Título cambiado en SQLite", ids[0]))
    db.initialize()
    db.initialize()
    after = client.get("/plantillas", headers=headers).json()
    assert [r["id"] for r in after] == ids and len(after) == 21
    assert after[0]["titulo"] == "Título cambiado en SQLite"
    assert client.get("/habitos", headers=headers).json() == [saved]
    with db.connect() as conn:
        assert conn.execute("SELECT COUNT(*) FROM users").fetchone()[0] == 1
        assert conn.execute("PRAGMA foreign_key_check").fetchall() == []


def test_sqlite_foreign_keys_owner_index_constraints_and_rollback(client):
    db = client.app.state.db
    with db.connect() as conn:
        assert conn.execute("PRAGMA foreign_keys").fetchone()[0] == 1
        assert conn.execute("PRAGMA user_version").fetchone()[0] == 1
        fk = conn.execute("PRAGMA foreign_key_list(habitos)").fetchall()
        assert {(r["from"], r["table"], r["to"]) for r in fk} == {("user_id", "users", "id"), ("plantilla_id", "plantillas", "id")}
        assert [r["name"] for r in conn.execute("PRAGMA index_info(idx_habitos_user_id)")] == ["user_id"]
    _, headers = create_account(client)
    saved = client.post("/habitos", headers=headers, json=HABIT).json()
    for column, value in [("user_id", 99999), ("plantilla_id", 99999), ("categoria", "otra"), ("completado", 2)]:
        with pytest.raises(sqlite3.IntegrityError):
            with db.connect() as conn:
                conn.execute(f"UPDATE habitos SET {column} = ? WHERE id = ?", (value, saved["id"]))
    assert client.get("/habitos", headers=headers).json() == [saved]


def test_seed_conflict_fails_without_purge_or_partial_seed(client):
    db = client.app.state.db
    with db.connect() as conn:
        conn.execute("INSERT INTO plantillas(id,titulo,descripcion,categoria,frecuencia,tipo) VALUES (99,'Extra','Preexistente','organizacion','diaria','tarea')")
    with pytest.raises(ValueError, match="no se modifica ni purga"):
        db.initialize()
    with db.connect() as conn:
        assert conn.execute("SELECT COUNT(*) FROM plantillas").fetchone()[0] == 22
        assert conn.execute("SELECT titulo FROM plantillas WHERE id=99").fetchone()[0] == "Extra"


@pytest.mark.parametrize("failure", ["duplicate", "missing", "invalid"])
def test_invalid_seed_creates_no_database(settings, tmp_path, failure):
    rows = json.loads(SEED_PATH.read_text())
    if failure == "duplicate":
        rows[-1]["id"] = rows[0]["id"]
    elif failure == "missing":
        rows.pop()
    else:
        rows[0]["categoria"] = "desconocida"
    seed = tmp_path / "seed.json"
    seed.write_text(json.dumps(rows))
    with pytest.raises(ValueError):
        Database(settings.db_path).initialize(seed)
    assert not settings.db_path.exists()


def test_crud_survives_independent_processes_without_losing_other_user(tmp_path):
    db_path = tmp_path / "processes.sqlite3"
    common = '''
import json, secrets, sys
from pathlib import Path
from fastapi.testclient import TestClient
from app.config import Settings
from app.main import create_app
app = create_app(Settings(jwt_secret=secrets.token_urlsafe(48), db_path=Path(sys.argv[1])))
password = "SoloPruebas-123!"
def login(client, email):
    response = client.post('/auth/login', json={'email':email,'password':password})
    assert response.status_code == 200
    return {'Authorization': 'Bearer ' + response.json()['access_token']}
'''
    scripts = [common + '''
with TestClient(app) as client:
    for email in ['a@example.com','b@example.com']:
        assert client.post('/auth/register',json={'email':email,'password':password}).status_code == 201
        headers = login(client,email)
        response = client.post('/habitos',headers=headers,json={'titulo':email[0]+' persistente','categoria':'organizacion','frecuencia':'diaria','tipo':'habito','plantilla_id':8})
        assert response.status_code == 201
    print(json.dumps({'a':client.get('/habitos',headers=login(client,'a@example.com')).json(),'b':client.get('/habitos',headers=login(client,'b@example.com')).json()}))
''', common + '''
with TestClient(app) as client:
    ah, bh = login(client,'a@example.com'),login(client,'b@example.com')
    before = client.get('/habitos',headers=ah).json()
    assert len(before) == 1 and before[0]['titulo'] == 'a persistente'
    response = client.patch('/habitos/'+str(before[0]['id']),headers=ah,json={'titulo':'A editado en segundo proceso','completado':True})
    assert response.status_code == 200
    print(json.dumps({'a':client.get('/habitos',headers=ah).json(),'b':client.get('/habitos',headers=bh).json()}))
''', common + '''
with TestClient(app) as client:
    ah, bh = login(client,'a@example.com'),login(client,'b@example.com')
    a = client.get('/habitos',headers=ah).json()
    assert a[0]['titulo'] == 'A editado en segundo proceso' and a[0]['completado'] is True
    deleted = client.delete('/habitos/'+str(a[0]['id']),headers=ah)
    assert deleted.status_code == 204 and deleted.content == b''
    print(json.dumps({'a':client.get('/habitos',headers=ah).json(),'b':client.get('/habitos',headers=bh).json(),'catalog_count':len(client.get('/plantillas',headers=ah).json())}))
''']
    results = []
    for script in scripts:
        result = subprocess.run(
            [sys.executable, "-c", script, str(db_path)], cwd=Path(__file__).resolve().parents[1],
            env={"PYTHONDONTWRITEBYTECODE": "1"}, text=True, capture_output=True, timeout=20,
        )
        assert result.returncode == 0, result.stderr
        results.append(json.loads(result.stdout))
    assert results[0]["a"][0]["titulo"] == "a persistente" and results[0]["a"][0]["completado"] is False
    assert results[1]["a"][0]["id"] == results[0]["a"][0]["id"]
    assert results[1]["a"][0]["titulo"] == "A editado en segundo proceso" and results[1]["a"][0]["completado"] is True
    assert results[2]["a"] == [] and results[2]["catalog_count"] == 21
    assert results[0]["b"] == results[1]["b"] == results[2]["b"]
    with sqlite3.connect(db_path) as conn:
        assert conn.execute("SELECT titulo FROM habitos").fetchall() == [("b persistente",)]
        assert conn.execute("SELECT COUNT(*) FROM users").fetchone()[0] == 2
        assert conn.execute("SELECT COUNT(*) FROM plantillas").fetchone()[0] == 21
