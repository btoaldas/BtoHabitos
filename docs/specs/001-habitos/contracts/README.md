# Contrato HTTP propuesto — S001

API JSON UTF-8; fechas ISO8601 UTC; base local `http://127.0.0.1:18310`. Android emulado usa `http://10.0.2.2:18310`, configurable al compilar. Autorización `Bearer <token>` en cabecera; nunca en URL/cuerpo. CORS solo orígenes locales de desarrollo explícitos. Contrato que ambos constructores deben conservar; una desviación se revisa antes de integrar.

| Método/ruta | Entrada | Salida correcta |
|---|---|---|
| GET /health | sin sesión | 200 `{status:"ok"}` sin configuración privada |
| POST /auth/register | `{email,password}`; correo válido, clave8–128 | 201 `{id,email}`; duplicado400 |
| POST /auth/login | `{email,password}` | 200 `{access_token,token_type:"bearer",expires_in,user:{id,email}}`; inválido401 |
| GET /auth/me | token | 200 `{id,email}` |
| GET /plantillas | token | 200 lista de21 objetos `{id,titulo,descripcion,categoria,frecuencia,tipo}` |
| GET /habitos | token | 200 lista de hábitos propios; vacío`[]` |
| POST /habitos | token+campos de hábito editables | 201 hábito propio persistido |
| PATCH /habitos/{id} | token+campos parciales editables; al menos1 | 200 hábito propio actualizado |
| DELETE /habitos/{id} | token; confirmación en UI | 204 sin cuerpo |
| POST /asistente | token+`{consulta}` de1–1000caracteres | 200 respuesta estructurada descrita abajo |

Campos editables: `plantilla_id` opcional, `titulo`, `descripcion`, `categoria`, `frecuencia`, `tipo`, `completado`. En POST titulo/categoria/frecuencia/tipo obligatorios, descripcion por defecto vacía y completadofalse. Categorías: bienestar/organizacion/aprendizaje; frecuencias diaria/semanal; tipos habito/tarea. Rechazar campos extra: no aceptar user_id, id o propietario del cliente. Las plantillas son solo lectura.

Errores: 400 regla de negocio/duplicado/patch vacío;401 falta/token inválido/expirado;404 hábito propio inexistente o ajeno;422 validación tipada;502 proveedor/salida inválida;503 proveedor no configurado/no disponible;504timeout. Errores legibles sin exponer excepción, prompt o secreto. Forma estándar `{detail:"mensaje"}`; Flutter también tolera la lista `detail` de validación Pydantic sin imprimir datos sensibles. Nunca usar caché para ocultar401/4xx.

## Asistente y proveedor

El servidor obtiene el agregado autorizado desde SQLite; el cliente no suministra conteos o identidad. El adaptador compatible con OpenAI usa `OPENAI_BASE_URL`, `OPENAI_API_KEY` y `OPENAI_MODEL` del entorno privado. Llamada con timeout máximo30s y tope de respuesta; registrar solo duración, estado y nombre de modelo no sensible. No registrar consulta, Authorization o clave.

Respuesta de consejo: `{tipo:"consejo",mensaje:"texto breve"}`. Propuesta: `{tipo:"propuesta",mensaje:"texto breve",habito:{titulo,descripcion,categoria,frecuencia,tipo}}`. Mensaje1–2000; mismos límites/enum de hábito. Validar salida antes de responder; no aceptar código, acciones desconocidas, campos extra, JSON incompleto ni objetos ambiguos. La salida del modelo es dato no confiable. El adaptador nunca crea/edita/elimina hábitos.

La UI muestra la propuesta y confirma/cancela. Solo confirmar con la generación/usuario/token originales vigentes invoca POST/habitos una vez. El servidor de laboratorio no admite credenciales del proveedor aportadas por el cliente. No hay fallback a reglas/datos simulados para afirmar que el recorrido de IA real cumplió.
