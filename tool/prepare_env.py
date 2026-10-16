#!/usr/bin/env python3
"""Prepara el entorno local del servidor sin revelar secretos."""

from __future__ import annotations

import argparse
import os
import secrets
import sys
from pathlib import Path

NOMBRES = frozenset({
    "DB_PATH", "JWT_SECRET", "TOKEN_TTL_SECONDS", "JWT_EXPIRES_SECONDS",
    "ALLOWED_ORIGINS", "OPENAI_BASE_URL", "OPENAI_API_KEY", "OPENAI_MODEL",
    "OPENAI_TIMEOUT_SECONDS", "OPENAI_DISABLE_THINKING",
})
PROVEEDOR = frozenset({"OPENAI_BASE_URL", "OPENAI_API_KEY", "OPENAI_MODEL"})


def preparar(destino: Path, ejemplo: Path) -> None:
    """Crea una configuración nueva desde plantilla y genera JWT_SECRET."""
    lineas = ejemplo.read_text(encoding="utf-8").splitlines()
    vistos: set[str] = set()
    resultado: list[str] = []
    secreto_encontrado = False
    for numero, linea in enumerate(lineas, 1):
        texto = linea.strip()
        if not texto or texto.startswith("#"):
            resultado.append(linea)
            continue
        if "=" not in linea:
            raise ValueError(f"línea {numero}: sintaxis inválida")
        nombre, valor = linea.split("=", 1)
        if nombre not in NOMBRES:
            raise ValueError(f"línea {numero}: nombre no permitido")
        if nombre in vistos:
            raise ValueError(f"línea {numero}: nombre duplicado")
        vistos.add(nombre)
        if nombre == "JWT_SECRET":
            valor = secrets.token_urlsafe(48)
            secreto_encontrado = True
        elif nombre in PROVEEDOR:
            valor = ""
        resultado.append(f"{nombre}={valor}")
    if not secreto_encontrado:
        raise ValueError("falta JWT_SECRET en la plantilla")
    if not destino.parent.is_dir():
        raise FileNotFoundError("el directorio de destino debe existir")
    descriptor = os.open(destino, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as salida:
        salida.write("\n".join(resultado) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("server/.env"))
    parser.add_argument("--example", type=Path, default=Path("server/.env.example"))
    args = parser.parse_args()
    try:
        preparar(args.output, args.example)
    except FileExistsError:
        print("No se modificó el destino existente.", file=sys.stderr)
        return 2
    except (OSError, UnicodeError, ValueError) as error:
        print(f"No se pudo preparar el entorno: {type(error).__name__}.", file=sys.stderr)
        return 1
    print(f"Entorno local creado sin mostrar valores: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
