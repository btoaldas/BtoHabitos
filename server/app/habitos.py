import sqlite3

from fastapi import APIRouter, HTTPException, Request, Response

from .auth import CurrentUser
from .db import utc_now
from .schemas import Habito, HabitoCrear, HabitoPatch

router = APIRouter(prefix="/habitos", tags=["hábitos"])


def _output(row: sqlite3.Row) -> dict:
    result = dict(row)
    result.pop("user_id")
    result["completado"] = bool(result["completado"])
    return result


def _owned(conn: sqlite3.Connection, habit_id: int, user_id: int) -> sqlite3.Row:
    row = conn.execute("SELECT * FROM habitos WHERE id = ? AND user_id = ?", (habit_id, user_id)).fetchone()
    if row is None:
        raise HTTPException(404, "Hábito no encontrado")
    return row


def _validate_template(conn: sqlite3.Connection, template_id: int | None) -> None:
    if template_id is not None and conn.execute("SELECT id FROM plantillas WHERE id = ?", (template_id,)).fetchone() is None:
        raise HTTPException(400, "La plantilla no existe")


@router.get("", response_model=list[Habito])
def list_habits(request: Request, user: CurrentUser):
    with request.app.state.db.connect() as conn:
        return [_output(row) for row in conn.execute("SELECT * FROM habitos WHERE user_id = ? ORDER BY id", (user.id,))]


@router.post("", response_model=Habito, status_code=201)
def create_habit(body: HabitoCrear, request: Request, user: CurrentUser):
    values = body.model_dump()
    values.update(user_id=user.id, created_at=utc_now())
    values["updated_at"] = values["created_at"]
    with request.app.state.db.connect() as conn:
        _validate_template(conn, body.plantilla_id)
        cursor = conn.execute(
            """INSERT INTO habitos (user_id,plantilla_id,titulo,descripcion,categoria,frecuencia,tipo,completado,created_at,updated_at)
            VALUES (:user_id,:plantilla_id,:titulo,:descripcion,:categoria,:frecuencia,:tipo,:completado,:created_at,:updated_at)""", values,
        )
        return _output(_owned(conn, cursor.lastrowid, user.id))


@router.patch("/{id}", response_model=Habito)
def patch_habit(id: int, body: HabitoPatch, request: Request, user: CurrentUser):
    values = body.model_dump(exclude_unset=True)
    with request.app.state.db.connect() as conn:
        # Un ID ajeno siempre se oculta, incluso ante un PATCH vacío.
        _owned(conn, id, user.id)
        if not values:
            raise HTTPException(400, "Indique al menos un campo para actualizar")
        if "plantilla_id" in values:
            _validate_template(conn, values["plantilla_id"])
        values["updated_at"] = utc_now()
        # Las claves proceden exclusivamente de HabitoPatch(extra=forbid), nunca de SQL del cliente.
        assignment = ", ".join(f"{name} = ?" for name in values)
        conn.execute(f"UPDATE habitos SET {assignment} WHERE id = ? AND user_id = ?", (*values.values(), id, user.id))
        return _output(_owned(conn, id, user.id))


@router.delete("/{id}", status_code=204)
def delete_habit(id: int, request: Request, user: CurrentUser):
    with request.app.state.db.connect() as conn:
        _owned(conn, id, user.id)
        conn.execute("DELETE FROM habitos WHERE id = ? AND user_id = ?", (id, user.id))
    return Response(status_code=204)
