# Plan S001 — BtoHabitos

Estado: Propuesta para revisión técnica — 2026-10-15. No se ha iniciado implementación ni se registra aprobación humana del paquete.

## Comprobación contra la constitución

Cumple identidad independiente, nivel L/laboratorio, tres capas de Flutter y separación servidor/app. Datos sintéticos, mínimo privilegio, secretos fuera de Git y del APK; no mapas ni integración institucional. Publicación y credenciales permanecen en el coordinador. La arquitectura no copia otra aplicación; reutiliza bibliotecas y patrones de concurrencia conocidos, implementados y probados para este dominio.

## Estructura y propiedad

Flutter en la raíz: `lib/{bindings,controllers,models,repositories,services,screens,widgets,theme}/`, `test/`, `android/`, `web/`, `pubspec.yaml`. Servidor independiente en `server/{app,tests,seeds}/`, `server/pyproject.toml`, `server/.env.example`. Scripts de reproducción en `tool/`; evidencia en `evidence/`; CI en `.github/workflows/`. Contratos y datos se fijan en los documentos vecinos.

Un constructor es propietario de `server/`; otro de fuentes Flutter, pruebas y plataformas generadas. No comparten archivos. Tras integrar ambas partes, un lote final es propietario de CI, herramientas, documentación de ejecución y pruebas de recorrido; no se lanzan dos escritores sobre las mismas rutas.

## Decisiones técnicas

- Flutter/GetX: vistas declarativas, controladores con estado explícito y servicios inyectables; navegación conserva las tres pestañas y puerta de autenticación. Dio concentra token, timeouts y traducción de errores. Almacenamiento seguro se abstrae para probar cola y restauración reales sin depender del plugin en unitarias.
- FastAPI/Pydantic/SQLite: contrato tipado y despliegue local mínimo; datos versionados en JSON semilla, carga transaccional e idempotente de 21 plantillas. Bibliotecas estables con versiones compatibles fijadas, no versiones inventadas. scrypt con salt aleatorio por contraseña; JWT mediante biblioteca mantenida, algoritmo HS256 fijo, expiración y secreto externo de al menos 32 bytes. Sin JWT artesanal ni contraseñas en claro.
- Hive: solo IDs favoritos de plantillas por usuario. Capturar caja y usuario en cada operación; cola compartida entre instancias para abrir/flush/cerrar. Salir cierra la caja original y conserva sus favoritos; no hay caché de hábitos privados ni escrituras offline. No usar `boxExists` para sondear bases web. No copiar recetas de borrado que dejen IndexedDB abierta.
- IA: el servidor llama a un proveedor compatible con OpenAI por HTTPS salvo proveedor local explícito. Modelo/base/key por entorno privado. Enviar consulta y contexto agregado mínimo (conteos por categoría y estado); nunca correo, ID/token o detalle de hábitos. Respuesta estructurada y validada como consejo o propuesta. No modo REGLAS como aceptación final; las pruebas determinísticas usan dobles declarados.
- Sesiones: generación local y token original capturados; incrementar generación antes de cualquier espera al salir/expirar/cambiar cuenta. Interceptores descartan errores obsoletos antes de cerrar por 401. Serializar almacenamiento seguro entre instancias; restauración tardía y onClose no reviven sesión. CRUD/propuestas verifican sesión antes/después; un resultado antiguo no se escribe en la UI de B.

## Lotes y controles tempranos

### L01 — Cuenta, catálogo y CRUD (T01–T10)

Primera rebanada observable: registrar/iniciar sesión, cargar 21 plantillas reales y crear un hábito desde una plantilla. Antes de ampliar UI, probar token manipulado/expirado, IDOR A/B, semilla idempotente y generación de sesión. Completar lista vacía, edición, completar/reabrir y eliminación confirmada. Los constructores servidor/Flutter pueden trabajar en paralelo contra el mismo contrato.

### L02 — Persistencia y asistente (T11–T15)

Dependencia: contratos L01 estables. Probar primero colas de dos instancias y cierre/restauración; después favoritos entre procesos. Adaptador de proveedor con validación estricta y cero escrituras; Flutter confirma usando el CRUD original. Probar cancelación/doble toque/logout/401 tardío y salida malformada. La aceptación real de IA requiere la configuración privada proporcionada por el coordinador.

### L03 — Integración y entrega (T16–T21)

Dependencia: recorrido L01/L02 integrado. Ejecutar suites/análisis pertinentes una vez por revisión transversal, repetir solo fallos o cambios que invaliden evidencia. Recorrido real con SQLite más UI, dos cuentas y dos procesos. CI en copia limpia y release `v*` con APK; el coordinador maneja el remoto y su publicación. README exacto, capturas reales, créditos y evidencia enlazada a commit.

## Comandos de aceptación previstos

El constructor debe concretar y probar: instalación del servidor en entorno virtual, `pytest`, `uvicorn app.main:app --host 127.0.0.1 --port 18310`, `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --release --dart-define=API_BASE_URL=...`, instalación y relanzamiento del APK. No se afirma que estos archivos/comandos estén disponibles en el alta.

## Reutilización y límites

Reutilizar bibliotecas de HTTP/validación/criptografía y scripts SDD existentes. Crear solo scripts mecánicos útiles para semilla, pruebas de flujo o verificación reproducible del proyecto; no copiar fuentes de ExploraEC ni crear un skill por cada tarea. No instalar hooks, SDK global, servicios de arranque ni software externo por inferencia.

## Recuperación y dependencias externas

Historial real por lote, base de pruebas nueva y separada, sin modificar bases ajenas. Un cambio de esquema tiene migración idempotente y conservación de datos. No reset, purga o sustitución destructiva sin autorización específica. El coordinador conserva decisiones de remoto, configuración de IA, SDK, publicación y entrega; no bloquean el trabajo local que no depende de ellas.
