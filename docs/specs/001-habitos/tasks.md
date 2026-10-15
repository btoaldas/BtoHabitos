# Tareas S001 — BtoHabitos

- Estado: Aprobado
- Aprobado por: Alberto — 2026-10-15 — «Apruebo BtoHabitos, el plan y las tareas»

## L01 — Cuenta, catálogo y CRUD

- [ ] T01 (RF-02) Crear semilla idempotente de 21 plantillas y lectura en `server/seeds/plantillas.json`, `server/app/catalogo.py`. Evidencia esperada: SQLite con 21 IDs únicos tras dos inicializaciones; cambio servidor visible sin recompilar app.
- [ ] T02 (RF-01, RNF-01) Implementar cuentas, scrypt y JWT en `server/app/auth.py`, `server/app/security.py`, `server/tests/test_auth.py`. Evidencia esperada: registro/login/duplicado/expiración/manipulación; cero contraseña o token en logs.
- [ ] T03 (RF-03, RF-06) Implementar CRUD propietario en `server/app/habitos.py`, `server/tests/test_habitos.py`. Evidencia esperada: ciclo persistente y aislamiento A/B para cada método; 400/401/404/422 coherentes.
- [ ] T04 (RF-01, RF-02, RF-03) Documentar instalación y contratos ejecutables en `server/pyproject.toml`, `server/README.md`, `server/.env.example`. Evidencia esperada: entorno nuevo arranca en loopback18310 y suite del servidor verde.
- [ ] T05 [P] (RF-01, RF-02, RF-03, RF-06) Crear estructura Flutter y navegación en `pubspec.yaml`, `lib/main.dart`, `lib/bindings/app_binding.dart`. Evidencia esperada: aplicación original con puerta de acceso y tres pestañas; no otra app renombrada.
- [ ] T06 (RF-01, RNF-02) Implementar sesión/Dio/almacenamiento seguro en `lib/controllers/auth_controller.dart`, `lib/services/api_client.dart`, `lib/services/secure_token_storage.dart`. Evidencia esperada: dos instancias con escritura/lectura retenidas no restauran token antiguo; 401 tardío A no cierra B.
- [ ] T07 (RF-01, RF-06) Crear formularios en `lib/screens/login_screen.dart`, `lib/screens/register_screen.dart`, `test/auth_widget_test.dart`. Evidencia esperada: validación, errores legibles, salir/expirar deja correo/clave vacíos y teclado cerrado.
- [ ] T08 (RF-02, RF-06) Crear catálogo/detalle en `lib/controllers/catalogo_controller.dart`, `lib/screens/catalogo_screen.dart`, `test/catalogo_test.dart`. Evidencia esperada: 21 registros desde API, carga/vacío/error/reintento y detalle correcto.
- [ ] T09 (RF-03, RF-06, RNF-02) Crear Mis hábitos y formulario en `lib/controllers/habitos_controller.dart`, `lib/screens/habitos_screen.dart`, `lib/screens/habito_form_screen.dart`. Evidencia esperada: alta/edición/completar/reabrir/eliminar confirmado; cancelación cero mutaciones; resultado tardío descartado.
- [ ] T10 (RF-01, RF-02, RF-03, RF-06) Verificar primera rebanada real y registrar `evidence/l01/resultado.json`. Evidencia esperada: UI+SQLite con dos cuentas y catálogo real; suites focales pertinentes verdes, sin aislamiento simulado por etiquetas.

## L02 — Favoritos y asistente

- [ ] T11 (RF-04, RNF-02) Implementar favoritos y cola portable en `lib/repositories/favoritos_repository.dart`, `lib/controllers/catalogo_controller.dart`, `test/favoritos_repository_test.dart`. Evidencia esperada: cajas Hive reales cerradas/reabiertas y dos instancias concurrentes; A→B→A conserva únicamente favoritos propios.
- [ ] T12 (RF-04) Comprobar persistencia entre procesos en `tool/verificar_persistencia.dart`, `evidence/l02/persistencia.json`. Evidencia esperada: proceso1 guarda y termina; proceso2 lee los mismos IDs sin datos de otra cuenta; almacenamiento seguro real también persiste.
- [ ] T13 [P] (RF-05, RNF-01) Crear adaptador de IA y validación en `server/app/asistente.py`, `server/tests/test_asistente.py`. Evidencia esperada: proveedor recibe solo consulta/contexto agregado, respuesta estricta y cero escrituras de hábitos; timeout/malformado/caída rechazados.
- [ ] T14 (RF-05, RF-06, RNF-02) Crear asistente y confirmación en `lib/services/asistente_service.dart`, `lib/screens/asistente_screen.dart`, `test/asistente_test.dart`. Evidencia esperada: cancelar0POST, confirmar1POST, doble toque1, logout/respuesta/401 tardíos0altas bajo sesión nueva.
- [ ] T15 (RF-04, RF-05, RNF-01) Registrar recorrido con modelo real en `evidence/l02/asistente-real.json`. Evidencia esperada: identidad técnica del modelo y resultado saneado, alta real tras confirmar, favorito recuperado tras relanzar; no marcar con respuesta simulada.

## L03 — Calidad, integración y entrega

- [ ] T16 (RF-06, RNF-03) Completar errores y accesibilidad en `lib/widgets/estado_operacion.dart`, `test/estados_widget_test.dart`. Evidencia esperada: escenarios 400/401/422/5xx/red/timeout en español, cargas terminan, recuperación real y controles48×48.
- [ ] T17 (RF-07, RNF-04) Crear CI y release en `.github/workflows/ci.yml`, `.github/workflows/release.yml`. Evidencia esperada: análisis/suites/build en copia limpia; tag v* produce APK descargable sin secretos y pruebas fallidas bloquean release.
- [ ] T18 (RF-07, RNF-01, RNF-04) Completar documentación y entorno en `README.md`, `server/.env.example`, `docs/adr/001-arquitectura.md`. Evidencia esperada: comandos copiados y ejecutados desde copia limpia, créditos reales y secreto ausente en Git/APK.
- [ ] T19 (RF-01, RF-02, RF-03, RF-04, RF-05, RF-06, RNF-02, RNF-04) Ejecutar aceptación integrada y registrar `evidence/l03/resultado.json`. Evidencia esperada: suites/análisis verdes y recorrido real de dos cuentas con DB, persistencia, proveedor y pruebas de carreras controladas; no repetir suites concurrentemente.
- [ ] T20 (RF-07, RNF-03, RNF-04) Capturar UI y verificar APK en `evidence/l03/capturas/`, `evidence/l03/apk.json`. Evidencia esperada: APK release instalado, relanzado y recorrido documentado; capturas de la versión exacta sin credenciales.
- [ ] T21 (RF-07, RNF-01, RNF-04) Completar matriz/hito y preparar entrega en `docs/specs/001-habitos/verificacion.md`, `docs/hitos/2026-10-15-producto-validado.md`. Evidencia esperada: RF→casos→resultados→commit, límites explícitos y enlace de release; publicación/envío solo por coordinador con destino autorizado.


## Aprobación del paquete el 15 de octubre de 2026

Alberto aprobó conjuntamente el alcance, el plan y las tareas con la respuesta explícita «Apruebo BtoHabitos, el plan y las tareas». Se autoriza iniciar la construcción local; esta aprobación no registra todavía aceptación de resultados ni publicación de un remoto nuevo.
