import sqlite3
from typing import Annotated

import jwt
from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from .db import utc_now
from .schemas import Credenciales, Sesion, Usuario
from .security import DUMMY_HASH, hash_password, issue_token, token_user_id, verify_password

router = APIRouter(prefix="/auth", tags=["cuenta"])
bearer = HTTPBearer(auto_error=False)


def unauthorized() -> HTTPException:
    return HTTPException(401, "Sesión ausente, inválida o expirada", headers={"WWW-Authenticate": "Bearer"})


def current_user(
    request: Request,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
) -> Usuario:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise unauthorized()
    try:
        user_id = token_user_id(credentials.credentials, request.app.state.settings)
    except (jwt.InvalidTokenError, ValueError, OverflowError):
        raise unauthorized() from None
    with request.app.state.db.connect() as conn:
        row = conn.execute("SELECT id,email FROM users WHERE id = ?", (user_id,)).fetchone()
    if row is None:
        raise unauthorized()
    return Usuario(**dict(row))


CurrentUser = Annotated[Usuario, Depends(current_user)]


@router.post("/register", response_model=Usuario, status_code=201)
def register(body: Credenciales, request: Request):
    encoded = hash_password(body.password)
    try:
        with request.app.state.db.connect() as conn:
            cursor = conn.execute(
                "INSERT INTO users(email,password_hash,created_at) VALUES (?,?,?)",
                (str(body.email), encoded, utc_now()),
            )
            user_id = cursor.lastrowid
    except sqlite3.IntegrityError:
        raise HTTPException(400, "El correo ya está registrado") from None
    return Usuario(id=user_id, email=str(body.email))


@router.post("/login", response_model=Sesion)
def login(body: Credenciales, request: Request):
    with request.app.state.db.connect() as conn:
        row = conn.execute("SELECT id,email,password_hash FROM users WHERE email = ?", (str(body.email),)).fetchone()
    valid = verify_password(body.password, row["password_hash"] if row else DUMMY_HASH)
    if row is None or not valid:
        raise HTTPException(401, "Correo o contraseña incorrectos", headers={"WWW-Authenticate": "Bearer"})
    settings = request.app.state.settings
    return Sesion(
        access_token=issue_token(row["id"], settings), expires_in=settings.jwt_expires_seconds,
        user=Usuario(id=row["id"], email=row["email"]),
    )


@router.get("/me", response_model=Usuario)
def me(user: CurrentUser):
    return user
