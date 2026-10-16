"""Entrada: uvicorn app.main:create_app --factory --host 127.0.0.1 --port 18310."""

import sqlite3
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException

from . import asistente, auth, catalogo, habitos
from .asistente import AssistantProvider
from .config import Settings
from .db import Database


def create_app(settings: Settings | None = None, *, transport: httpx.AsyncBaseTransport | None = None) -> FastAPI:
    config = settings if settings is not None else Settings.from_env()

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        db = Database(config.db_path)
        db.initialize()
        app.state.db = db
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(config.openai_timeout_seconds),
            transport=transport, follow_redirects=False, trust_env=False,
        ) as client:
            app.state.provider = AssistantProvider(config, client)
            yield

    app = FastAPI(title="BtoHabitos", version="0.1.0", lifespan=lifespan)
    app.state.settings = config
    app.add_middleware(
        CORSMiddleware, allow_origins=list(config.allowed_origins),
        allow_credentials=False, allow_methods=["GET", "POST", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
    )

    @app.middleware("http")
    async def sanitize_unexpected_errors(request: Request, call_next):
        try:
            return await call_next(request)
        except Exception:
            # No propagar mensajes/tracebacks con contenido de consultas o secretos.
            return JSONResponse(status_code=500, content={"detail": "Error interno del servidor"})

    @app.exception_handler(RequestValidationError)
    async def validation_error(request: Request, error: RequestValidationError):
        # El detalle estándar Pydantic incluye input; se omite para no devolver credenciales.
        return JSONResponse(status_code=422, content={"detail": "Solicitud inválida: revise los campos, tipos y límites"})

    @app.exception_handler(sqlite3.Error)
    async def database_error(request: Request, error: sqlite3.Error):
        return JSONResponse(status_code=503, content={"detail": "La base de datos no está disponible"})

    @app.exception_handler(HTTPException)
    async def http_error(request: Request, error: HTTPException):
        detail = error.detail if isinstance(error.detail, str) else "Solicitud no disponible"
        return JSONResponse(status_code=error.status_code, content={"detail": detail}, headers=error.headers)

    @app.get("/health")
    def health():
        return {"status": "ok"}

    app.include_router(auth.router)
    app.include_router(catalogo.router)
    app.include_router(habitos.router)
    app.include_router(asistente.router)
    return app
