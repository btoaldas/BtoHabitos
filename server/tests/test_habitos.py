from datetime import datetime

import pytest

from conftest import HABIT


def test_full_crud_private_and_persistent_between_connections(client, accounts):
    a, ah, b, bh = accounts
    assert client.get("/habitos", headers=ah).json() == []
    created = client.post("/habitos", headers=ah, json={**HABIT, "plantilla_id": 15})
    assert created.status_code == 201
    habit = created.json()
    assert habit["titulo"] == HABIT["titulo"] and habit["plantilla_id"] == 15 and habit["completado"] is False
    assert "user_id" not in habit and habit["created_at"] == habit["updated_at"]
    assert datetime.fromisoformat(habit["created_at"]).utcoffset().total_seconds() == 0
    assert client.get("/habitos", headers=bh).json() == []
    other = client.post("/habitos", headers=bh, json={**HABIT, "titulo": "Solo B"}).json()
    assert other["id"] != habit["id"]
    path = f'/habitos/{habit["id"]}'
    foreign_patch = client.patch(path, headers=bh, json={"titulo": "Intrusión"})
    foreign_delete = client.delete(path, headers=bh)
    assert foreign_patch.status_code == foreign_delete.status_code == 404
    assert foreign_patch.json() == foreign_delete.json() == {"detail": "Hábito no encontrado"}
    for completed in [True, False]:
        response = client.patch(path, headers=ah, json={"titulo": "Lectura editada", "completado": completed, "plantilla_id": None})
        assert response.status_code == 200
        edited = response.json()
        assert edited["completado"] is completed and edited["titulo"] == "Lectura editada" and edited["plantilla_id"] is None
        assert edited["created_at"] == habit["created_at"] and edited["updated_at"] >= habit["updated_at"]
        with client.app.state.db.connect() as conn:
            row = conn.execute("SELECT * FROM habitos WHERE id = ?", (habit["id"],)).fetchone()
            assert row["user_id"] == a["id"] and row["titulo"] == edited["titulo"] and row["completado"] == int(completed)
    assert client.get("/habitos", headers=bh).json() == [other]
    response = client.delete(path, headers=ah)
    assert response.status_code == 204 and response.content == b""
    assert client.delete(path, headers=ah).status_code == 404
    assert client.patch(path, headers=ah, json={"titulo": "Ausente"}).status_code == 404
    assert client.get("/habitos", headers=ah).json() == []
    assert client.get("/habitos", headers=bh).json() == [other]
    with client.app.state.db.connect() as conn:
        assert [(r["id"], r["user_id"]) for r in conn.execute("SELECT id,user_id FROM habitos")] == [(other["id"], b["id"])]


def test_business_errors_no_mutations(client, accounts):
    _, ah, _, bh = accounts
    habit = client.post("/habitos", headers=ah, json=HABIT).json()
    path = f'/habitos/{habit["id"]}'
    assert client.patch(path, headers=ah, json={}).status_code == 400
    assert client.patch(path, headers=bh, json={}).status_code == 404
    assert client.post("/habitos", headers=ah, json={**HABIT, "plantilla_id": 999999}).status_code == 400
    assert client.patch(path, headers=ah, json={"plantilla_id": 999999}).status_code == 400
    assert client.patch("/habitos/999999", headers=ah, json={"titulo": "Nuevo"}).status_code == 404
    assert client.delete("/habitos/999999", headers=ah).status_code == 404
    assert client.get("/habitos", headers=ah).json() == [habit]


@pytest.mark.parametrize("field,value", [
    ("user_id", 12), ("id", 4), ("propietario", "otro"), ("extra", True),
    ("titulo", ""), ("titulo", " " * 3), ("titulo", "x" * 101),
    ("descripcion", "x" * 501), ("categoria", "medicina"),
    ("frecuencia", "mensual"), ("tipo", "accion"),
    ("completado", "true"), ("completado", 1), ("completado", None),
    ("plantilla_id", True), ("plantilla_id", "1"), ("plantilla_id", -1),
    ("titulo", None), ("descripcion", None),
])
def test_strict_create_and_patch_do_not_change_database(client, accounts, field, value):
    _, headers, _, _ = accounts
    habit = client.post("/habitos", headers=headers, json=HABIT).json()
    for method, path, body in [
        ("POST", "/habitos", {**HABIT, field: value}),
        ("PATCH", f'/habitos/{habit["id"]}', {field: value}),
    ]:
        response = client.request(method, path, headers=headers, json=body)
        assert response.status_code == 422, (field, response.text)
        assert set(response.json()) == {"detail"}
    assert client.get("/habitos", headers=headers).json() == [habit]


def test_create_defaults_and_patch_all_fields(client, accounts):
    _, headers, _, _ = accounts
    payload = {k: v for k, v in HABIT.items() if k != "descripcion"}
    response = client.post("/habitos", headers=headers, json=payload)
    assert response.status_code == 201
    assert response.json()["descripcion"] == "" and response.json()["plantilla_id"] is None
    patch = {"titulo": "Plan", "descripcion": "Otra descripción", "categoria": "organizacion", "frecuencia": "semanal", "tipo": "tarea", "plantilla_id": 8, "completado": True}
    edited = client.patch(f'/habitos/{response.json()["id"]}', headers=headers, json=patch)
    assert edited.status_code == 200
    assert all(edited.json()[k] == v for k, v in patch.items())
