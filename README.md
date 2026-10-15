# BtoHabitos

Aplicación personal de formación para convertir plantillas de hábitos y tareas en una rutina propia, con favoritos persistentes y un asistente conectado a un modelo desde el servidor.

**Estado, 15 de octubre de 2026:** alta documental y paquete SDD preparados para revisión; todavía no hay aplicación, servidor, pruebas de producto ni APK implementados. Este repositorio es local y no tiene remoto.

## Producto previsto

- Catálogo de 21 plantillas recuperadas del servidor, con detalle y favoritos.
- Mis hábitos: crear, consultar, editar, marcar completado y eliminar con confirmación, separado por cuenta.
- Asistente: consejo breve o propuesta de hábito; crear solo después de confirmación expresa.

## Arquitectura prevista

Flutter/GetX, Dio, almacenamiento seguro para el token y Hive para favoritos por usuario; FastAPI/SQLite para cuentas, catálogo y hábitos. La IA utiliza un proveedor compatible con OpenAI únicamente desde el servidor. Los detalles y las alternativas constan en [la decisión técnica](docs/adr/001-arquitectura.md).

La API local se prevé en `127.0.0.1:18310`; Android emulado accederá por `10.0.2.2:18310`, configurable con `--dart-define=API_BASE_URL=...`. Las variables y los comandos reproducibles se documentarán y comprobarán con el código entregado. No se incluyen claves ni una configuración real de proveedor.

## Documentación

[Especificación](docs/specs/001-habitos/spec.md), [plan](docs/specs/001-habitos/plan.md), [tareas](docs/specs/001-habitos/tasks.md), [contrato HTTP](docs/specs/001-habitos/contracts/README.md), [estado](ROADMAP.md) y [evidencia](evidence/README.md).

El cierre exige instrucciones exactas desde un clon limpio, archivo de entorno de ejemplo sin secretos, capturas reales, pruebas, decisión técnica, créditos y APK release generado por CI. Ninguno se declara completado en esta fase.

## Créditos

Proyecto original de formación CEDIA MOD3. Se declarará la asistencia de IA utilizada en la construcción y revisión. Se identificarán las bibliotecas y sus licencias efectivas antes de la publicación; no se copia ExploraEC ni se asigna una licencia a material ajeno.
