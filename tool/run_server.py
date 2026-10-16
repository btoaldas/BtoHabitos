#!/usr/bin/env python3
"""Carga literalmente el entorno documentado e inicia la factory loopback."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

ALLOWED_NAMES = frozenset({
    "DB_PATH", "JWT_SECRET", "TOKEN_TTL_SECONDS", "JWT_EXPIRES_SECONDS",
    "ALLOWED_ORIGINS", "OPENAI_BASE_URL", "OPENAI_API_KEY", "OPENAI_MODEL",
    "OPENAI_TIMEOUT_SECONDS", "OPENAI_DISABLE_THINKING",
})
NAME_PATTERN = re.compile(r"[A-Z][A-Z0-9_]*\Z")


def parse_env(text: str) -> dict[str, str]:
    """Lee líneas NOMBRE=valor literales, sin expansión de shell."""
    values: dict[str, str] = {}
    for number, raw_line in enumerate(text.splitlines(), 1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise ValueError(f"línea {number}: se esperaba NOMBRE=valor")
        name, value = line.split("=", 1)
        if not NAME_PATTERN.fullmatch(name) or name not in ALLOWED_NAMES:
            raise ValueError(f"línea {number}: nombre de variable no permitido")
        if name in values:
            raise ValueError(f"línea {number}: variable duplicada")
        values[name] = value
    return values


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    server = repo / "server"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--env-file", type=Path, default=server / ".env")
    args = parser.parse_args()
    env_file = args.env_file if args.env_file.is_absolute() else Path.cwd() / args.env_file
    try:
        values = parse_env(env_file.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, ValueError) as error:
        print(f"No se pudo cargar el entorno: {type(error).__name__}.", file=sys.stderr)
        return 2

    process_env = os.environ.copy()
    process_env.update(values)
    command = [
        str(server / ".venv" / "bin" / "python"), "-m", "uvicorn",
        "app.main:create_app", "--factory", "--host", "127.0.0.1",
        "--port", "18310", "--no-access-log",
    ]
    try:
        return subprocess.call(command, cwd=server, env=process_env)
    except OSError as error:
        print(f"No se pudo iniciar el servidor: {type(error).__name__}.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
