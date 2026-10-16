"""Regenera un lock NUEVO desde este venv resuelto, verificando hashes en PyPI.

Uso desde server/: .venv/bin/python tests/tools/lock_dependencies.py
No sobrescribe locks existentes; para revisar otro, indicar una ruta nueva permitida.
"""

import importlib.metadata
import json
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


def published_hashes(package):
    name, version = package
    url = f"https://pypi.org/pypi/{name}/{version}/json"
    with urllib.request.urlopen(url, timeout=20) as response:
        document = json.load(response)
    hashes = sorted({row["digests"]["sha256"] for row in document["urls"] if not row["yanked"]})
    if not hashes or document["info"]["version"] != version:
        raise ValueError(f"No hay distribuciones verificables de {name}=={version}")
    return f"{name}=={version} \\\n" + " \\\n".join(f"    --hash=sha256:{value}" for value in hashes)


def main():
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("requirements.lock")
    packages = sorted({(dist.metadata["Name"].lower().replace("_", "-"), dist.version) for dist in importlib.metadata.distributions() if dist.metadata["Name"].lower() not in {"pip", "setuptools"}})
    with ThreadPoolExecutor(max_workers=8) as pool:
        entries = list(pool.map(published_hashes, packages))
    header = (
        "# BtoHabitos: Python 3.12, macOS/Linux; runtime + pytest.\n"
        "# Versiones instaladas y hashes de https://pypi.org/pypi/<nombre>/<version>/json.\n"
        "# Generado por tests/tools/lock_dependencies.py; no incluye bootstrap pip.\n"
        "# Instalar: python -m pip install --require-hashes -r requirements.lock\n\n"
    )
    with target.open("x", encoding="utf-8") as output:
        output.write(header + "\n\n".join(entries) + "\n")
    print(f"{target}: {len(packages)} paquetes fijados con hashes PyPI")


if __name__ == "__main__":
    main()
