from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, StringConstraints, field_validator, model_validator

Categoria = Literal["bienestar", "organizacion", "aprendizaje"]
Frecuencia = Literal["diaria", "semanal"]
TipoHabito = Literal["habito", "tarea"]
Titulo = Annotated[str, StringConstraints(min_length=1, max_length=100, pattern=r"\S")]
Descripcion = Annotated[str, StringConstraints(max_length=500)]
Mensaje = Annotated[str, StringConstraints(min_length=1, max_length=2000, pattern=r"\S")]
PositiveId = Annotated[int, Field(gt=0, strict=True)]


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class Credenciales(StrictModel):
    email: EmailStr
    password: Annotated[str, StringConstraints(min_length=8, max_length=128)]

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value: object) -> object:
        return value.strip().casefold() if isinstance(value, str) else value

    @field_validator("email")
    @classmethod
    def reject_display_name(cls, value: str) -> str:
        # EmailStr valida el buzón; aquí se conserva una única representación.
        return value.casefold()


class Usuario(StrictModel):
    id: PositiveId
    email: str


class Sesion(StrictModel):
    access_token: str
    token_type: Literal["bearer"] = "bearer"
    expires_in: int
    user: Usuario


class HabitoPropuesto(StrictModel):
    titulo: Titulo
    descripcion: Descripcion
    categoria: Categoria
    frecuencia: Frecuencia
    tipo: TipoHabito


class HabitoCrear(HabitoPropuesto):
    descripcion: Descripcion = ""
    plantilla_id: PositiveId | None = None
    completado: bool = False


class HabitoPatch(StrictModel):
    plantilla_id: PositiveId | None = None
    titulo: Titulo | None = None
    descripcion: Descripcion | None = None
    categoria: Categoria | None = None
    frecuencia: Frecuencia | None = None
    tipo: TipoHabito | None = None
    completado: bool | None = None

    @model_validator(mode="after")
    def reject_null_fields(self) -> "HabitoPatch":
        if any(getattr(self, name) is None for name in self.model_fields_set - {"plantilla_id"}):
            raise ValueError("Solo plantilla_id permite null")
        return self


class Habito(HabitoCrear):
    id: PositiveId
    created_at: str
    updated_at: str


class Plantilla(HabitoPropuesto):
    id: PositiveId
    descripcion: Annotated[str, StringConstraints(min_length=1, max_length=500, pattern=r"\S")]


class Consulta(StrictModel):
    consulta: Annotated[str, StringConstraints(min_length=1, max_length=1000, pattern=r"\S")]


class Consejo(StrictModel):
    tipo: Literal["consejo"]
    mensaje: Mensaje


class Propuesta(StrictModel):
    tipo: Literal["propuesta"]
    mensaje: Mensaje
    habito: HabitoPropuesto


RespuestaAsistente = Annotated[Consejo | Propuesta, Field(discriminator="tipo")]
