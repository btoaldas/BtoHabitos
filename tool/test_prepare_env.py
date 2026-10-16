"""Pruebas locales de preparación y arranque sin servicios externos."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from prepare_env import main, preparar
from run_server import parse_env


class PrepareEnvTests(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(tempfile.mkdtemp(prefix="btohabitos-tool-test-"))
        self.ejemplo = self.root / ".env.example"
        self.ejemplo.write_text(
            "JWT_SECRET=\nOPENAI_API_KEY=ejemplo-no-privado\nOPENAI_MODEL=\n",
            encoding="utf-8",
        )

    def test_secretos_distintos_privados_y_proveedor_vacio(self) -> None:
        primero, segundo = self.root / "uno.env", self.root / "dos.env"
        preparar(primero, self.ejemplo)
        preparar(segundo, self.ejemplo)
        texto_a, texto_b = primero.read_text(), segundo.read_text()
        secreto_a = texto_a.splitlines()[0].partition("=")[2]
        secreto_b = texto_b.splitlines()[0].partition("=")[2]
        self.assertGreaterEqual(len(secreto_a.encode()), 32)
        self.assertGreaterEqual(len(secreto_b.encode()), 32)
        self.assertNotEqual(secreto_a, secreto_b)
        self.assertIn("OPENAI_API_KEY=\n", texto_a)
        self.assertIn("OPENAI_MODEL=\n", texto_a)
        self.assertNotIn("ejemplo-no-privado", texto_a)
        self.assertEqual(os.stat(primero).st_mode & 0o777, 0o600)

    def test_destino_existente_se_conserva(self) -> None:
        destino = self.root / "existente.env"
        destino.write_text("KEEP=sin-cambios\n")
        with self.assertRaises(FileExistsError):
            preparar(destino, self.ejemplo)
        self.assertEqual(destino.read_text(), "KEEP=sin-cambios\n")

    def test_plantilla_rechaza_duplicado_desconocido_y_sintaxis_sin_valores(self) -> None:
        for plantilla, esperado in (
            ("JWT_SECRET=\nJWT_SECRET=secreto-no-mostrar", "duplicado"),
            ("JWT_SECRET=\nPRIVATE=secreto-no-mostrar", "no permitido"),
            ("JWT_SECRET=\nesto-no-es-valido", "sintaxis"),
        ):
            with self.subTest(esperado=esperado):
                self.ejemplo.write_text(plantilla, encoding="utf-8")
                with self.assertRaisesRegex(ValueError, esperado) as error:
                    preparar(self.root / "salida.env", self.ejemplo)
                self.assertNotIn("secreto-no-mostrar", str(error.exception))

    def test_cli_prepara_sin_imprimir_secreto(self) -> None:
        comando = [sys.executable, str(Path(__file__).with_name("prepare_env.py")),
                   "--output", str(self.root / "cli.env"), "--example", str(self.ejemplo)]
        resultado = subprocess.run(comando, capture_output=True, text=True, check=False)
        secreto = (self.root / "cli.env").read_text().splitlines()[0].partition("=")[2]
        self.assertEqual(resultado.returncode, 0, resultado.stderr)
        self.assertNotIn(secreto, resultado.stdout + resultado.stderr)

    def test_cli_run_server_resuelve_repo_y_cwd_desde_otro_directorio(self) -> None:
        raiz = self.root / "copia"
        (raiz / "tool").mkdir(parents=True)
        servidor = raiz / "server"
        python_falso = servidor / ".venv" / "bin" / "python"
        python_falso.parent.mkdir(parents=True)
        shutil.copy(Path(__file__).with_name("run_server.py"), raiz / "tool/run_server.py")
        shutil.copy(Path(__file__).with_name("prepare_env.py"), raiz / "tool/prepare_env.py")
        shutil.copy(Path(__file__).resolve().parents[1] / "server/.env.example", servidor / ".env.example")
        log = self.root / "invocacion.json"
        python_falso.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            f"open({str(log)!r}, 'w').write(json.dumps({{'cwd': os.getcwd(), 'argv': sys.argv[1:], 'jwt': os.environ.get('JWT_SECRET')}}))\n",
            encoding="utf-8",
        )
        python_falso.chmod(0o700)
        (servidor / ".env").write_text("JWT_SECRET=secreto-sintetico-no-imprimir\n", encoding="utf-8")
        otro_cwd = self.root / "otro-cwd"
        otro_cwd.mkdir()
        resultado = subprocess.run(
            [sys.executable, str(raiz / "tool/run_server.py")], cwd=otro_cwd,
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stderr)
        self.assertNotIn("secreto-sintetico-no-imprimir", resultado.stdout + resultado.stderr)
        registro = json.loads(log.read_text(encoding="utf-8"))
        self.assertEqual(registro["jwt"], "secreto-sintetico-no-imprimir")
        self.assertEqual(Path(registro["cwd"]).resolve(), servidor.resolve())
        self.assertEqual(registro["argv"], [
            "-m", "uvicorn", "app.main:create_app", "--factory", "--host",
            "127.0.0.1", "--port", "18310", "--no-access-log",
        ])

    def test_cli_run_server_falla_limpio_si_falta_entorno(self) -> None:
        copia = self.root / "sin-entorno"
        (copia / "tool").mkdir(parents=True)
        (copia / "server").mkdir()
        shutil.copy(Path(__file__).with_name("run_server.py"), copia / "tool/run_server.py")
        resultado = subprocess.run(
            [sys.executable, str(copia / "tool/run_server.py")], cwd=self.root,
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(resultado.returncode, 2)
        self.assertIn("FileNotFoundError", resultado.stderr)
        self.assertNotIn("JWT_SECRET", resultado.stderr)

    def test_parser_rechaza_duplicado_desconocido_y_sintaxis_malformada(self) -> None:
        for texto in ("JWT_SECRET=a\nJWT_SECRET=b", "HOME=privado", "malformado"):
            with self.subTest(texto=texto), self.assertRaises(ValueError):
                parse_env(texto)

    def test_expansiones_permanecen_como_datos_literales(self) -> None:
        self.assertEqual(parse_env("JWT_SECRET=$(touch marcador)")["JWT_SECRET"], "$(touch marcador)")


if __name__ == "__main__":
    unittest.main()
