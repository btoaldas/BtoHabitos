import asyncio
import json
import logging
import secrets
from dataclasses import replace

import httpx
import pytest

from app.main import create_app
from conftest import HABIT, PASSWORD, create_account, provider_response

PROVIDER = {"openai_base_url": "https://provider.invalid/v1", "openai_api_key": "solo-doble-sin-acceso-real", "openai_model": "modelo-sintetico"}
ADVICE = {"tipo": "consejo", "mensaje": "Reserve un momento para organizar su día."}
PROPOSAL = {"tipo": "propuesta", "mensaje": "Puede probar esta idea.", "habito": HABIT}


def snapshot(client):
    with client.app.state.db.connect() as conn:
        return {table: [tuple(row) for row in conn.execute(f"SELECT * FROM {table} ORDER BY id")] for table in ("users", "plantillas", "habitos")}


@pytest.mark.parametrize("thinking", [True, False])
def test_exact_request_minimized_authorized_aggregate_and_changed_output(make_client, thinking, caplog):
    captured = []
    responses = iter([ADVICE, {"tipo": "consejo", "mensaje": "Esta respuesta es diferente."}, PROPOSAL])

    def handler(request):
        captured.append(request)
        return provider_response(next(responses))

    caplog.set_level(logging.INFO)
    client = make_client(handler, **PROVIDER, openai_disable_thinking=thinking)
    a, ah = create_account(client)
    b, bh = create_account(client, "persona.b@example.com")
    for values in [HABIT, {**HABIT, "categoria": "bienestar", "completado": True}]:
        assert client.post("/habitos", json=values, headers=ah).status_code == 201
    assert client.post("/habitos", json={**HABIT, "titulo": "Otro usuario B", "completado": True}, headers=bh).status_code == 201
    before = snapshot(client)
    outputs = []
    for _ in range(3):
        response = client.post("/asistente", json={"consulta": "Una idea breve"}, headers=ah)
        assert response.status_code == 200, response.text
        outputs.append(response.json())
    assert outputs == [ADVICE, {"tipo": "consejo", "mensaje": "Esta respuesta es diferente."}, PROPOSAL]
    assert snapshot(client) == before
    assert len(captured) == 3
    for request in captured:
        payload = json.loads(request.content)
        expected_keys = {"model", "messages", "response_format", "stream", "max_tokens"} | ({"thinking"} if thinking else set())
        assert set(payload) == expected_keys
        assert request.method == "POST" and str(request.url) == "https://provider.invalid/v1/chat/completions"
        assert request.headers["authorization"] == "Bearer " + PROVIDER["openai_api_key"]
        assert payload["model"] == PROVIDER["openai_model"]
        assert payload["response_format"] == {"type": "json_object"} and payload["stream"] is False and payload["max_tokens"] == 512
        if thinking:
            assert payload["thinking"] == {"type": "disabled"}
        assert len(payload["messages"]) == 2 and payload["messages"][0]["role"] == "system" and payload["messages"][1]["role"] == "user"
        context = json.loads(payload["messages"][1]["content"])
        assert context == {"consulta": "Una idea breve", "contexto": {"total": 2, "completados": 1, "por_categoria": {"bienestar": 1, "organizacion": 0, "aprendizaje": 1}}}
        wire = request.content.decode()
        for private in [a["email"], b["email"], ah["Authorization"].split()[1], bh["Authorization"].split()[1], HABIT["titulo"], HABIT["descripcion"], "Otro usuario B", "user_id", "plantilla_id", PROVIDER["openai_api_key"]]:
            assert private not in wire
    for private in [PASSWORD, a["email"], b["email"], ah["Authorization"].split()[1], bh["Authorization"].split()[1], "Una idea breve", HABIT["descripcion"], PROVIDER["openai_api_key"]]:
        assert private not in caplog.text


@pytest.mark.parametrize("overrides", [{}, {"openai_base_url": PROVIDER["openai_base_url"]}, {"openai_base_url": PROVIDER["openai_base_url"], "openai_model": PROVIDER["openai_model"]}])
def test_unconfigured_provider_503_no_fallback_no_writes(make_client, overrides):
    client = make_client(**overrides)
    _, headers = create_account(client)
    before = snapshot(client)
    response = client.post("/asistente", json={"consulta": "Una idea"}, headers=headers)
    assert response.status_code == 503 and "no está configurado" in response.json()["detail"]
    assert snapshot(client) == before


@pytest.mark.parametrize("content", [
    "Texto libre", '```json\n{"tipo":"consejo","mensaje":"Una idea"}\n```',
    '{"tipo":"consejo","mensaje":', '[]', 'null', 'true',
    {"tipo": "eliminar", "mensaje": "Algo"},
    {**ADVICE, "accion": "crear"}, {**ADVICE, "habito": HABIT},
    {"tipo": "consejo", "mensaje": ""}, {"tipo": "consejo", "mensaje": " "},
    {"tipo": "consejo", "mensaje": 12}, {"tipo": "consejo", "mensaje": "x" * 2001},
    {"tipo": "propuesta", "mensaje": "Sin hábito"},
    {**PROPOSAL, "habito": {**HABIT, "user_id": 99}},
    {**PROPOSAL, "habito": {**HABIT, "completado": True}},
    {**PROPOSAL, "habito": {**HABIT, "categoria": "desconocida"}},
    {**PROPOSAL, "habito": {**HABIT, "titulo": "x" * 101}},
    '{"tipo":"consejo","tipo":"propuesta","mensaje":"Ambiguo"}',
    '{"tipo":"consejo","mensaje":NaN}',
])
def test_invalid_model_output_502_and_database_unchanged(make_client, content):
    client = make_client(lambda request: provider_response(content), **PROVIDER)
    _, headers = create_account(client)
    client.post("/habitos", json=HABIT, headers=headers)
    before = snapshot(client)
    response = client.post("/asistente", json={"consulta": "Mi consulta privada"}, headers=headers)
    assert response.status_code == 502 and isinstance(response.json()["detail"], str)
    assert "Mi consulta privada" not in response.text and PROVIDER["openai_api_key"] not in response.text
    assert snapshot(client) == before


@pytest.mark.parametrize("finish", ["length", "tool_calls", "content_filter", None, "unknown"])
def test_truncation_or_unknown_finish_rejected_even_with_valid_json(make_client, finish):
    client = make_client(lambda request: provider_response(ADVICE, finish=finish), **PROVIDER)
    _, headers = create_account(client)
    before = snapshot(client)
    response = client.post("/asistente", json={"consulta": "Idea"}, headers=headers)
    assert response.status_code == 502 and snapshot(client) == before


@pytest.mark.parametrize("envelope", [
    {}, [], {"choices": []}, {"choices": [None]},
    {"choices": [{"finish_reason": "stop", "message": {"role": "assistant", "content": None}}]},
    {"choices": [{"finish_reason": "stop", "message": {"role": "user", "content": json.dumps(ADVICE)}}]},
    {"choices": [{"finish_reason": "stop", "message": {"role": "assistant", "content": json.dumps(ADVICE), "tool_calls": [{"id": "1"}]}}]},
])
def test_malformed_provider_envelope_rejected(make_client, envelope):
    client = make_client(lambda request: httpx.Response(200, json=envelope), **PROVIDER)
    _, headers = create_account(client)
    before = snapshot(client)
    response = client.post("/asistente", json={"consulta": "Idea"}, headers=headers)
    assert response.status_code == 502 and snapshot(client) == before


@pytest.mark.parametrize("status,expected", [(400, 502), (401, 502), (404, 502), (302, 502), (429, 503), (500, 503), (503, 503)])
def test_provider_status_sanitized_without_retry_or_writes(make_client, status, expected):
    calls = []

    def handler(request):
        calls.append(request)
        return httpx.Response(status, text="Excepción con secreto y prompt privado", headers={"Location": "https://otro.invalid"})

    client = make_client(handler, **PROVIDER)
    _, headers = create_account(client)
    before = snapshot(client)
    response = client.post("/asistente", json={"consulta": "Idea"}, headers=headers)
    assert response.status_code == expected and "privado" not in response.text and "Excepción" not in response.text
    assert len(calls) == 1 and snapshot(client) == before


@pytest.mark.parametrize("error_type,expected", [(httpx.ConnectError, 503), (httpx.ReadTimeout, 504), (httpx.ConnectTimeout, 504), (httpx.DecodingError, 502)])
def test_provider_network_errors_do_not_leak_or_write(make_client, error_type, expected):
    def handler(request):
        raise error_type("No divulgar clave o consulta", request=request)

    client = make_client(handler, **PROVIDER)
    _, headers = create_account(client)
    before = snapshot(client)
    response = client.post("/asistente", json={"consulta": "Idea"}, headers=headers)
    assert response.status_code == expected and "No divulgar" not in response.text and snapshot(client) == before


def test_oversized_response_rejected(make_client):
    client = make_client(lambda request: httpx.Response(200, content=b"x" * 65537), **PROVIDER)
    _, headers = create_account(client)
    before = snapshot(client)
    response = client.post("/asistente", json={"consulta": "Idea"}, headers=headers)
    assert response.status_code == 502 and snapshot(client) == before


@pytest.mark.parametrize("body", [{"consulta": ""}, {"consulta": " "}, {"consulta": "x" * 1001}, {"consulta": 1}, {"consulta": "Idea", "user_id": 3}, {"consulta": "Idea", "total": 100}, {"consulta": "Idea", "OPENAI_API_KEY": "invasor"}])
def test_assistant_request_strict_no_provider_call(make_client, body):
    client = make_client(**PROVIDER)
    _, headers = create_account(client)
    before = snapshot(client)
    response = client.post("/asistente", json=body, headers=headers)
    assert response.status_code == 422 and snapshot(client) == before


def test_cancellation_propagates_and_total_timeout_no_writes(settings):
    async def scenario():
        entered = asyncio.Event()
        cancelled = asyncio.Event()

        async def blocked(request):
            entered.set()
            try:
                await asyncio.Event().wait()
            finally:
                cancelled.set()

        config = replace(settings, **PROVIDER, openai_timeout_seconds=0.1)
        app = create_app(config, transport=httpx.MockTransport(blocked))
        async with app.router.lifespan_context(app):
            async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as api:
                credentials = {"email": "cancelacion@example.com", "password": PASSWORD}
                assert (await api.post("/auth/register", json=credentials)).status_code == 201
                login = await api.post("/auth/login", json=credentials)
                headers = {"Authorization": "Bearer " + login.json()["access_token"]}
                saved = await api.post("/habitos", json=HABIT, headers=headers)
                assert saved.status_code == 201
                with app.state.db.connect() as conn:
                    before = [tuple(r) for r in conn.execute("SELECT * FROM habitos")]
                task = asyncio.create_task(api.post("/asistente", json={"consulta": "Idea"}, headers=headers))
                await asyncio.wait_for(entered.wait(), timeout=2)
                task.cancel()
                with pytest.raises(asyncio.CancelledError):
                    await task
                await asyncio.wait_for(cancelled.wait(), timeout=2)
                entered.clear()
                cancelled.clear()
                timed_out = await api.post("/asistente", json={"consulta": "Idea"}, headers=headers)
                assert timed_out.status_code == 504 and cancelled.is_set()
                with app.state.db.connect() as conn:
                    after = [tuple(r) for r in conn.execute("SELECT * FROM habitos")]
                assert before == after
                assert (await api.get("/habitos", headers=headers)).json() == [saved.json()]

    asyncio.run(scenario())
