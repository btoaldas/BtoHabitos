# Servidor local BtoHabitos

Backend original FastAPI/Pydantic/SQLite del laboratorio personal. Implementa
cuentas, catálogo de 21 plantillas, CRUD privado y asistente compatible con
OpenAI. No requiere Flutter para ejecutar sus pruebas. El asistente no guarda
historial ni crea, edita o elimina hábitos.

## Instalación reproducible

Comandos desde `server/`, con **CPython 3.12**. Verificado con Python 3.12.14 en
macOS arm64. El lock incluye dependencias de ejecución y pytest, versiones
exactas y hashes de distribuciones oficiales; contempla macOS/Linux con 3.12.
Linux queda pendiente de ejecutar por el coordinador.

```sh
python3.12 -m venv .venv
.venv/bin/python -m pip install --require-hashes -r requirements.lock
.venv/bin/python -m pip check
```

El procedimiento instala el lock sin instalar el proyecto como paquete:
se ejecuta desde `server/`. No requiere instalar un servicio de arranque.

Versiones directas comprobadas en el índice oficial PyPI el 15 de octubre de
2026: [FastAPI 0.143.2](https://pypi.org/project/fastapi/0.143.2/),
[Pydantic 2.14.1](https://pypi.org/project/pydantic/2.14.1/),
[HTTPX 0.28.1](https://pypi.org/project/httpx/0.28.1/),
[PyJWT 2.15.1](https://pypi.org/project/PyJWT/2.15.1/),
[Uvicorn 0.54.0](https://pypi.org/project/uvicorn/0.54.0/),
[email-validator 2.3.0](https://pypi.org/project/email-validator/2.3.0/)
y [pytest 9.1.1](https://pypi.org/project/pytest/9.1.1/).
`requirements.lock` fija también todas las dependencias transitivas.

## Arranque en loopback

El coordinador proporciona las variables privadas al proceso. `.env.example`
documenta los nombres; **la aplicación no abre `.env` automáticamente**. No hay
secreto JWT utilizable por defecto. Ejemplo local que genera uno en memoria,
sin mostrarlo, y deja el proveedor sin configurar:

```sh
export DB_PATH=./data/btohabitos.sqlite3
export JWT_SECRET="$(.venv/bin/python -c 'import secrets; print(secrets.token_urlsafe(48))')"
export JWT_EXPIRES_SECONDS=3600
export ALLOWED_ORIGINS=http://127.0.0.1:18311,http://localhost:18311
.venv/bin/python -m uvicorn app.main:create_app --factory --host 127.0.0.1 --port 18310 --no-access-log
```

Para conservar sesiones entre arranques, conservar el mismo secreto en el
entorno privado. Cambiarlo invalida tokens anteriores. El comando usa la
factory explícita en lugar de crear una aplicación global durante el import.
No abrir el bind a otras interfaces. Android emulado utiliza
`API_BASE_URL=http://10.0.2.2:18310` en su compilación; no configura el proveedor.

```sh
curl --fail http://127.0.0.1:18310/health
```

Respuesta exacta: `{"status":"ok"}`. No revela configuración. Para detener la
instancia iniciada en esta terminal, usar Ctrl+C. No hay comandos de purga,
rollback destructivo o reinicialización de bases en este procedimiento.

## Variables de entorno

| Variable | Interpretación |
|---|---|
| `DB_PATH` | Archivo SQLite; por defecto `./data/btohabitos.sqlite3`, relativo al directorio de ejecución. No acepta `:memory:`. |
| `JWT_SECRET` | Obligatorio, al menos 32 bytes UTF-8, sin valor por defecto; se recomienda aleatorio. |
| `JWT_EXPIRES_SECONDS` | Entero positivo, por defecto 3600; segundos de validez. |
| `TOKEN_TTL_SECONDS` | Alias legado conservado; solo se usa si falta `JWT_EXPIRES_SECONDS`. El canónico siempre prevalece. |
| `ALLOWED_ORIGINS` | Orígenes completos separados por comas. Por defecto los dos orígenes locales del ejemplo. Una cadena vacía deshabilita la lista. Rechaza comodines, rutas y hosts no loopback. |
| `OPENAI_BASE_URL` | Base del proveedor, sin `/chat/completions`. Requiere HTTPS; permite HTTP únicamente para host loopback explícito. Sin usuario, contraseña, query ni fragmento en la URL. |
| `OPENAI_API_KEY` | Clave privada del proveedor, únicamente servidor. |
| `OPENAI_MODEL` | Identificador del modelo, únicamente servidor. |
| `OPENAI_TIMEOUT_SECONDS` | Número finito mayor que 0 y menor o igual que 30; por defecto 30. Límite HTTPX por fase y límite total de la llamada al proveedor. |
| `OPENAI_DISABLE_THINKING` | `true` o `false` (por defecto): true añade `thinking={"type":"disabled"}`; false omite esa extensión. |

Si falta cualquiera de base/clave/modelo, `/asistente` responde 503, sin
fallback. El coordinador configurará estos valores para la prueba real; aquí
no se leyó ni configuró proveedor alguno. No se siguen redirecciones ni proxies
heredados del entorno en las llamadas de IA. No se reintenta automáticamente.

## Contrato y almacenamiento

Se conserva `docs/specs/001-habitos/contracts/README.md` de la raíz. JSON UTF-8,
fechas UTC terminadas en `Z`, cabecera `Authorization: Bearer <token>`:

| Operación | Resultado |
|---|---|
| `POST /auth/register` con `{email,password}` | 201 `{id,email}`; correo válido normalizado con strip/casefold, contraseña 8–128 caracteres; duplicado 400. |
| `POST /auth/login` con `{email,password}` | 200 `{access_token,token_type:"bearer",expires_in,user:{id,email}}`; credenciales incorrectas 401. |
| `GET /auth/me` | 200 `{id,email}`; token obligatorio. |
| `GET /plantillas` | 200 lista de 21 objetos `{id,titulo,descripcion,categoria,frecuencia,tipo}`; token obligatorio. |
| `GET /habitos` | 200 lista propia, inicialmente `[]`. |
| `POST /habitos` | 201 hábito persistido. |
| `PATCH /habitos/{id}` | 200 hábito actualizado; cuerpo vacío 400. |
| `DELETE /habitos/{id}` | 204 sin cuerpo; la confirmación pertenece a Flutter. |
| `POST /asistente` con `{consulta}` | 200 consejo/propuesta validada; consulta de 1–1000 caracteres. |

En hábitos, título de 1–100 caracteres, descripción de 0–500, categorías
`bienestar/organizacion/aprendizaje`, frecuencia `diaria/semanal`, tipo
`habito/tarea`. POST requiere título/categoría/frecuencia/tipo; descripción
vacía, `completado=false` y `plantilla_id=null` son los valores por defecto.
PATCH admite solo los campos editables presentes; únicamente `plantilla_id`
admite null para desvincular la plantilla. Una plantilla inexistente produce
400. Los cuerpos rechazan campos extra, valores coercionados como `"true"`
y campos `id`, `user_id` o `propietario`: 422. Un ID ajeno o inexistente
produce el mismo 404; no existe lectura individual fuera del contrato.

La salida de hábito incluye sus campos editables, `id`, `created_at` y
`updated_at`; el propietario se obtiene del token y no se expone como campo de
salida. Todas las operaciones SQL de hábitos filtran por ese propietario.
SQLite exige claves foráneas, índices de propietario y restricciones de
enum/longitud/bool. Cada operación abre y cierra su propia conexión.

`seeds/plantillas.json` es original y versionado. El inicio crea el esquema
v1 e inserta solo los IDs ausentes en una transacción, sin sobrescribir filas
existentes ni hábitos. Inicializar dos veces mantiene exactamente los mismos
21 IDs; una edición existente del catálogo se conserva y se ve en la API sin
recompilar. Un catálogo con IDs ajenos a la semilla detiene la inicialización;
no se purga ni corrige silenciosamente. Esquemas futuros requieren migración
revisada. No hay limpieza automática de bases existentes.

Las contraseñas usan `hashlib.scrypt`, N=32768/r=8/p=1, salt aleatorio de 16
bytes y derivado de 32, guardando algoritmo/parámetros/salt/derivado. La
verificación usa comparación constante. PyJWT firma y verifica exclusivamente
HS256, firma/expiración/iat/sub obligatorios; comprueba además la existencia
del usuario. JWT no tiene revocación por sesión en este laboratorio: salir
elimina el token en el cliente; un token emitido sigue siendo válido hasta
expirar o cambiar el secreto. El control de respuestas tardías de UI pertenece
a Flutter y no se afirma verificado aquí.

Los errores usan `{detail:"mensaje"}`: 400 negocio, 401 autenticación, 404
inexistente/ajeno, 422 validación, 502 salida/rechazo del proveedor, 503 falta
de configuración/caída/DB no disponible, 504 timeout. Un error inesperado
devuelve 500 genérico. La validación omite `input` y excepciones para no
reflejar contraseñas u otros datos. La aplicación no registra cuerpos, tokens,
consultas ni contraseñas; sus registros de IA contienen duración, estado y
nombre del modelo. El arranque documentado omite access logs.

## Adaptador de IA

El servidor consulta SQLite para obtener exclusivamente `total`,
`completados` y `por_categoria` de la cuenta autenticada. Envía esos conteos
y la consulta escrita por la persona. No adjunta correo, identidad/token ni
títulos/descripciones de hábitos. Como la consulta se transmite literalmente,
la persona debe evitar incluir datos sensibles en su texto libre.

Petición exacta a `<OPENAI_BASE_URL>/chat/completions`: `model`, dos `messages`,
`response_format={"type":"json_object"}`, `stream=false`, `max_tokens=512` y
solo cuando se activa la extensión, `thinking={"type":"disabled"}`. No usa
SDK de proveedor. Una respuesta requiere un solo choice con
`finish_reason="stop"` y mensaje assistant; rechaza truncamiento, llamadas a
herramientas, refusals, JSON malformado, claves duplicadas, constantes noJSON,
objetos ambiguos y campos adicionales. Se limita la respuesta HTTP a 64 KiB.
Consejo: `{tipo:"consejo",mensaje}`. Propuesta:
`{tipo:"propuesta",mensaje,habito:{titulo,descripcion,categoria,frecuencia,tipo}}`.
`mensaje` tiene 1–2000 caracteres. El hábito propuesto exige todos sus campos
y los mismos límites de hábito; no acepta IDs ni estado completado.

La salida sigue siendo texto no confiable: no se ejecuta código ni se
rescata texto libre para aparentar éxito. La propuesta solo vuelve al cliente;
guardar exige el POST ordinario de hábitos después de la confirmación de UI.
Timeout produce 504; red/429/5xx produce 503; rechazo de parámetros 4xx u otra
respuesta no admitida produce 502 con texto saneado.

## Pruebas y límites de validación

```sh
.venv/bin/python -m pytest
```

El arnés crea un directorio nuevo dentro de `tests/.runs` por ejecución. Si se
especifica `--basetemp`, exige que sea nuevo y esté dentro de esa carpeta: no
reutiliza ni purga fixtures anteriores. `.runs`, `.venv`, bytecode y bases quedan ignorados.
Las pruebas usan cuentas sintéticas, SQLite real, TestClient, procesos Python
independientes y un proceso Uvicorn con socket loopback/puerto efímero propio.
No requieren servicios externos ni leen `.env`. El proceso de prueba Uvicorn
se cierra al terminar; no se tocan procesos ajenos. El adaptador IA usa
`httpx.MockTransport`: inspecciona la petición real, varía las respuestas y
comprueba que éxito/error/cancelación/timeout no cambian ninguna tabla.

Starlette 1.8.0 todavía incluye el adaptador TestClient para HTTPX 0.28.1 y
avisa de su futura migración a httpx2. Pytest trata las advertencias como
errores salvo **esa advertencia concreta**, filtrada en `pyproject.toml`;
el runtime usa HTTPX 0.28.1 directamente. Revisar esta transición al actualizar.

La evidencia ejecutada y saneada se guarda en
`tests/evidencia-constructor.json`. Las pruebas no acreditan integración
Flutter, IA real, CI, APK ni aceptación de tareas SDD. El coordinador debe
repetir la instalación en su entorno y realizar el recorrido completo con
dos cuentas, SQLite y el proveedor privado autorizado.

Control del propio arnés:

```sh
.venv/bin/python tests/tools/check_auth_canary.py
```

Este comando introduce un bypass de firma solo en la memoria de su proceso y
ejecuta la prueba real de token manipulado. Debe mostrar una prueba roja con
`200 == 401` y después `CANARIO CORRECTO`; su salida global es 0 solo si
detectó exactamente esa regresión. No modifica las fuentes de la aplicación.

Para revisar una resolución futura en otro venv aislado, el generador consulta
los hashes publicados en PyPI y exige una ruta de salida nueva, evitando
sobrescribir el lock vigente:

```sh
.venv/bin/python tests/tools/lock_dependencies.py tests/.runs/requirements-candidato.lock
```

Bibliotecas reutilizadas: FastAPI/Starlette para HTTP/ASGI, Pydantic y
email-validator para validación, SQLite y hashlib de Python para datos y
scrypt, PyJWT para JWT, HTTPX para transporte, Uvicorn para el servidor y
pytest para pruebas. Se crearon el dominio, semilla y adaptador propios; no
se copiaron fuentes ni identidad de otra aplicación. No aplican SDK global,
hooks, Docker, remoto, despliegue o publicación en este lote.
