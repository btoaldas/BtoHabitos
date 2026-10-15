# Modelo de datos propuesto — S001

Estado: diseño para revisión, sin base creada.

| Entidad | Campos y restricciones |
|---|---|
| Usuario | id estable entero, email normalizado único, password_hash con salt/parámetros scrypt, created_at UTC; nunca devolver password_hash |
| Plantilla | id estable entero, titulo 1–100, descripcion 1–500, categoria bienestar/organizacion/aprendizaje, frecuencia diaria/semanal, tipo habito/tarea; 21 filas de JSON versionado |
| Hábito | id entero, user_id FK e índice, plantilla_id FK opcional, titulo 1–100, descripcion hasta500, categoria enum, frecuencia enum, tipo enum, completado bool, created_at/updated_at UTC |
| Favoritos locales | caja Hive `favoritos_<usuarioId>`, conjunto de IDs de plantillas; sin token, contraseña ni detalle de hábitos |

SQLite activa claves foráneas. CRUD filtra siempre por user_id derivado del token. Un ID ajeno se trata como inexistente404, sin revelar su dueño. Semilla transaccional y repetible: conserva IDs y verifica21; no genera duplicados, no purga hábitos. Cambios de esquema posteriores requieren migración y comprobación de conservación.

No se almacena historial del asistente en el servidor ni se envía al proveedor. Contexto agregado: total de hábitos, completados y conteos por categoría. Los hábitos no se almacenan offline en Flutter; la base local del servidor es la fuente autoritativa.
