"""SQLite por operación: transacciones cortas y cierre incluso al fallar."""

import json
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path

from pydantic import TypeAdapter

from .schemas import Plantilla

SEED_PATH = Path(__file__).resolve().parents[1] / "seeds" / "plantillas.json"
SCHEMA = (
    """CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
    )""",
    """CREATE TABLE IF NOT EXISTS plantillas (
        id INTEGER PRIMARY KEY,
        titulo TEXT NOT NULL CHECK(length(titulo) BETWEEN 1 AND 100),
        descripcion TEXT NOT NULL CHECK(length(descripcion) BETWEEN 1 AND 500),
        categoria TEXT NOT NULL CHECK(categoria IN ('bienestar','organizacion','aprendizaje')),
        frecuencia TEXT NOT NULL CHECK(frecuencia IN ('diaria','semanal')),
        tipo TEXT NOT NULL CHECK(tipo IN ('habito','tarea'))
    )""",
    """CREATE TABLE IF NOT EXISTS habitos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id),
        plantilla_id INTEGER REFERENCES plantillas(id),
        titulo TEXT NOT NULL CHECK(length(titulo) BETWEEN 1 AND 100),
        descripcion TEXT NOT NULL DEFAULT '' CHECK(length(descripcion) <= 500),
        categoria TEXT NOT NULL CHECK(categoria IN ('bienestar','organizacion','aprendizaje')),
        frecuencia TEXT NOT NULL CHECK(frecuencia IN ('diaria','semanal')),
        tipo TEXT NOT NULL CHECK(tipo IN ('habito','tarea')),
        completado INTEGER NOT NULL DEFAULT 0 CHECK(completado IN (0,1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
    )""",
    "CREATE INDEX IF NOT EXISTS idx_habitos_user_id ON habitos(user_id)",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")


class Database:
    def __init__(self, path: Path):
        self.path = path

    @contextmanager
    def connect(self):
        conn = sqlite3.connect(self.path, timeout=5)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        try:
            with conn:
                yield conn
        finally:
            conn.close()

    def initialize(self, seed_path: Path = SEED_PATH) -> None:
        rows = TypeAdapter(list[Plantilla]).validate_python(json.loads(seed_path.read_text(encoding="utf-8")))
        ids = {row.id for row in rows}
        if len(rows) != 21 or len(ids) != 21:
            raise ValueError("La semilla debe contener exactamente 21 identificadores únicos")
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as conn:
            conn.execute("BEGIN IMMEDIATE")
            version = conn.execute("PRAGMA user_version").fetchone()[0]
            if version not in (0, 1):
                raise ValueError("Versión de esquema no compatible; se requiere migración revisada")
            for statement in SCHEMA:
                conn.execute(statement)
            conn.executemany(
                """INSERT INTO plantillas (id,titulo,descripcion,categoria,frecuencia,tipo)
                VALUES (:id,:titulo,:descripcion,:categoria,:frecuencia,:tipo)
                ON CONFLICT(id) DO NOTHING""",
                [row.model_dump() for row in rows],
            )
            stored = {row[0] for row in conn.execute("SELECT id FROM plantillas")}
            if stored != ids:
                raise ValueError("El catálogo existente difiere de los 21 IDs; no se modifica ni purga")
            conn.execute("PRAGMA user_version = 1")

    def aggregate(self, user_id: int) -> dict:
        with self.connect() as conn:
            rows = conn.execute(
                """SELECT categoria, COUNT(*) AS total, SUM(completado) AS completados
                FROM habitos WHERE user_id = ? GROUP BY categoria""", (user_id,),
            ).fetchall()
        counts = {name: 0 for name in ("bienestar", "organizacion", "aprendizaje")}
        total = completed = 0
        for row in rows:
            counts[row["categoria"]] = row["total"]
            total += row["total"]
            completed += row["completados"]
        return {"total": total, "completados": completed, "por_categoria": counts}
