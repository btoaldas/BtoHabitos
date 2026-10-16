"""Comprueba que una prueba real detecta un bypass JWT introducido solo en memoria.

No cambia archivos de aplicación. Se espera una prueba roja con HTTP 200 vs 401.
El comando solo tiene éxito si falla exactamente esa aserción de comportamiento.
"""

import uuid

import pytest


class BypassSignature:
    def __init__(self):
        self.failed_calls = []

    def pytest_runtest_call(self, item):
        from app import auth
        self.original = auth.token_user_id
        auth.token_user_id = lambda token, settings: 1

    def pytest_runtest_teardown(self, item, nextitem):
        from app import auth
        auth.token_user_id = self.original

    def pytest_runtest_logreport(self, report):
        if report.failed:
            self.failed_calls.append((report.when, str(report.longrepr)))


def main():
    plugin = BypassSignature()
    result = pytest.main([
        "tests/test_auth.py", "-k", "manipulado and /auth/me",
        "--basetemp=tests/.runs/canary-" + uuid.uuid4().hex,
    ], plugins=[plugin])
    detected = int(result) == 1 and len(plugin.failed_calls) == 1
    detected = detected and plugin.failed_calls[0][0] == "call" and "assert 200 == 401" in plugin.failed_calls[0][1]
    if not detected:
        raise SystemExit("CANARIO INCORRECTO: no detectó exactamente el bypass JWT")
    print("CANARIO CORRECTO: la prueba detectó HTTP 200 indebido ante una firma inválida (esperaba 401)")


if __name__ == "__main__":
    main()
