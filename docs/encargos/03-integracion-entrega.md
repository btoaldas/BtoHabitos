# BtoHabitos — integración, CI y reproducibilidad

Lanzar después de integrar servidor y Flutter revisados. Leer `AGENTS.md`, S001plan/tasks/contratos y resultados de ambos constructores. No estás solo; preservar trabajo ajeno. Propiedad inicial: `.github/`, `tool/`, `README.md`, `evidence/`, `docs/specs/001-habitos/verificacion.md`, `server/README.md`, `server/.env.example`. Cualquier reparación de fuentes requiere ampliar explícitamente rutas en el encargo de corrección.

Concretar T12,T17–T21 sin inventar aceptación de producto. CI limpia instala y analiza/prueba servidor+Flutter; release por tagv* hace comprobaciones y genera APK. Ejemplo entorno sin claves, comandos exactos desde copia limpia, créditos/licencias comprobados, decisión técnica y capturas de la versión real. Herramienta de persistencia entre procesos y prueba de flujo con cuentas sintéticas nuevas; no purgar registros anteriores. No instalar SDKglobal.

Segundo ángulo: API/SQLite más UI; token y favoritos entre dos procesos reales; proveedor real configurado por coordinador, cancelar0POST/confirmar1POST, A→B vacío y 401tardío controlado. No ejecutar suites concurrentes ni confundir dobles con IA real. Logs y capturas saneados. Variar entradas/resultados para demostrar que el arnés no devuelve éxito por nombre de caso.

El coordinador crea/configura remoto y publica/entrega; este encargo no realiza esas acciones ni cambia credenciales. El constructor entrega comandos y evidencias, fallos concretos y artefactos reproducibles, sin declarar CIremota/release/APIreal si no se ejecutó. El coordinador decide aceptación final y marca tareas con los resultados pertinentes.
