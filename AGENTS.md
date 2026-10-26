# BtoHabitos — gobernanza del proyecto

Proyecto personal de formación y laboratorio: hábitos y tareas cotidianas. Es una aplicación nueva, independiente de ExploraEC, sin ámbito institucional ni uso productivo autorizado. Estado al 15 de octubre de 2026: servidor y aplicación construidos; pruebas locales, recorrido web y APK Android real verificados. CI remota y release `v1.0.0` correctas; APK público descargado, cotejado e instalado en emulador nuevo. Entrega CEDIA 49762 confirmada el 15 de octubre a las 20:36 como Enviado para calificar, Sin calificar. Aceptación técnica cerrada, calificación docente pendiente. La matriz de aceptación está en `docs/specs/001-habitos/verificacion.md`.

## Objetivo y alcance

Un usuario registra su cuenta, consulta 21 plantillas servidas desde una base, organiza sus propios hábitos, conserva favoritos y consulta un asistente con un modelo real llamado exclusivamente desde el servidor. Interfaz mínima: Catálogo, Mis hábitos y Asistente. Especificación y aceptación: `docs/specs/001-habitos/`.

No incluye mapas, geolocalización, pagos, notificaciones, consejos médicos, datos reales de terceros ni copia o cambio de marca de otra aplicación.

## Arquitectura y contratos

Flutter/Dart, GetX y capas de presentación/controladores/servicios/repositorios/modelos. Dio comparte autenticación; el token se guarda mediante almacenamiento seguro y nunca en Hive. Hive conserva únicamente identificadores de plantillas favoritas, separados por usuario. FastAPI y SQLite atienden autenticación, catálogo, CRUD y asistente. Contrato exacto: `docs/specs/001-habitos/contracts/README.md`.

El servidor de laboratorio escucha en `127.0.0.1:18310`. Android emulado usa `API_BASE_URL=http://10.0.2.2:18310`; el valor se configura al compilar. El proveedor de IA se configura únicamente en el entorno privado del servidor, con API compatible con OpenAI. Ninguna clave de proveedor llega a Flutter.

## Autoridad, conservación y colaboración

Está autorizada la preparación y construcción local del producto académico. El repositorio se creó localmente y hoy está publicado en GitHub como `btoaldas/BtoHabitos`, público, rama `main`, por autorización expresa de Alberto. La creación del remoto, su propietario y visibilidad, publicación, entrega en el aula y despliegue externo pertenecen al coordinador y requieren su autoridad concreta; los constructores no los ejecutan.

El 15 de octubre Alberto autorizó expresamente crear y publicar `btoaldas/BtoHabitos` en GitHub, público, con rama `main`, código, historial y APK educativo. El coordinador ejecuta y comprueba esta publicación. Esto no autoriza despliegue de infraestructura ni distribución productiva.

Anunciar toda mutación con alcance, impacto, comprobación y recuperación. No borrar, sobrescribir recursos ajenos, desactivar servicios ni reescribir historia sin aprobación específica. Conservar archivos y datos preexistentes. Una recuperación destructiva necesita autorización aunque esté descrita en un plan. Los ensayos usan directorios temporales ignorados dentro del proyecto; no crear proyectos hermanos.

Los trabajadores tienen propiedad explícita de rutas. No están solos: no revertir cambios de otros; integrar únicamente trabajo revisado. Construcción, revisión y aceptación son responsabilidades distintas. Credenciales, publicación, envíos y aceptación final permanecen en el coordinador. El contexto privado se entrega por un canal local no versionado, nunca como parte de fuentes o entregables.

## Datos y seguridad

Usar cuentas y hábitos sintéticos en pruebas. No registrar tokens, contraseñas, claves, cabeceras de autorización, consultas privadas completas ni datos personales en Git o evidencias. Las contraseñas se derivan con scrypt y salt aleatorio; JWT se valida con algoritmo fijado, firma y expiración. El servidor deriva siempre el propietario de la sesión, no de un campo del cliente.

Los cambios de sesión invalidan operaciones anteriores antes de cualquier espera. Una respuesta o 401 tardío no modifica ni cierra una sesión nueva. Serializar almacenamiento seguro y apertura/cierre/escritura de Hive entre instancias; capturar la caja original. En web, cerrar la caja antes de eliminar una base si alguna limpieza autorizada lo requiere; evitar sondeos que dejen conexiones abiertas.

## SDD y documentación

Especificación, plan y tareas preceden al código. Construir por lotes con controles tempranos de aislamiento, concurrencia e integridad y aceptación conjunta al completar el recorrido. Distinguir construida, validada y cerrada. Marcar una tarea solo con evidencia reproducible; no inventar aprobaciones. Documentos: `docs/specs/`, decisiones: `docs/adr/`, avances: `docs/bitacora/`, cierres: `docs/hitos/` y cambios externos: `docs/manifiestos/`.

Reutilizar bibliotecas y procedimientos determinísticos pertinentes; documentar adaptar/crear/no aplica. No instalar hooks ni automatizaciones por inferencia. Consultar primero el grafo disponible para estructura y llamadas; después buscar texto puntual y leer funciones concretas. Evitar inventarios completos y contexto duplicado. El índice se hará al existir código; el alta documental no necesita indexar símbolos inexistentes.

## Verificación y ejecución

Comandos disponibles y ejecutados localmente: `flutter analyze`, `flutter test`, pruebas del servidor con `pytest` y auxiliares con `unittest`. Resultados actuales: análisis sin incidencias, 92 pruebas Flutter, 160 del servidor y 8 de auxiliares aprobadas; UI/API reales con cuentas sintéticas y proveedor de IA real. El APK local se compiló, instaló y relanzó: sesión/favoritos entre procesos y aislamiento A→B→A comprobados. El APK local conserva una URI de compilación privada y permanece fuera de la publicación; el artefacto público se generó en CI limpio. Los flujos CI main 38834146256, CI tag 38834361808 y Release 38834361906 están correctos. El APK público SHA-256 `6a947d78234922d7d9fcab06030282ee37ad8c7c1e7ea0d0d2fa8713cc766be8` pasó firma, privacidad, instalación nueva, persistencia, aislamiento y asistente real. Recibos en `evidence/l03/`. Los datos y secretos no deben viajar en el APK.

No declarar terminado por un build, HTTP 200, una captura o un exit 0. Cada RF exige evidencia y segundo ángulo proporcional: pruebas controladas más recorrido real, consultas de base o persistencia entre procesos. Registrar límites, versiones, comandos y resultados en `evidence/` y en la verificación SDD.

## Git y recuperación

Rama inicial `main`, commits técnicos y neutrales con historia real por lote. No remoto, push, publicación ni despliegue implícitos. Respaldar el estado antes de cambios externos; documentar destino, versión, verificación y recuperación. Recuperar por commits/artefactos; no resetear, limpiar ni borrar sin la autorización correspondiente.

<!-- skill-anexos:navegacion-e2e-coherencia-20261025:begin -->
## Navegación E2E y acceso autorizado — regla vigente (2026-10-25)

Esta regla se aplica automáticamente a la navegación web y a las pruebas E2E web de este proyecto y sus agentes, skills y subdirectorios. En este ámbito prevalece sobre instrucciones anteriores incompatibles, como exigir un navegador visible, un perfil personal, una ruta fija de caché de otro sistema o el tecleo manual de credenciales disponibles.

- Aplicar los skills `playwright` y `chromium-headless`: Chromium interno de Playwright en modo headless, sin abrir ventanas ni depender de Chrome del usuario o de una extensión. Reutilizar el runtime, la configuración y las pruebas del proyecto; resolver el ejecutable con la API y comprobar los parámetros efectivos. Las pruebas nativas de escritorio o móvil conservan su herramienta específica. Si el usuario solicita expresamente su Chrome o su sesión, aplicar `chrome-browser` y los permisos de esa superficie.
- Si el usuario autoriza expresamente cuenta, destino y tarea autenticada, aplicar `acceso-web-autorizado` automáticamente: recuperar e introducir internamente la credencial pertinente de Obsidian, Llavero o la fuente local autorizada, o la que proporcione el usuario. No exigir invocación manual del skill ni volver a pedir su tecleo. Esta cláusula por sí sola no autoriza entrar a cuentas.
- Comprobar origen y cuenta antes de introducir y enviar credenciales; respetar MFA, CAPTCHA y permisos. No eludir una denegación. Máximo dos intentos; no exponer secretos en scripts, argumentos, registros, snapshots, capturas, trazas, repositorios ni informes. Para accesos reales prevalece la fuente autorizada vigente sobre literales heredados.
- El acceso conserva las autorizaciones específicas para envíos, publicaciones, firmas, pagos, borrados y cambios de datos o producción. Cerrar solo la sesión propia. La instalación global no demuestra que este proyecto pase sus pruebas: en otro equipo, cloud o CI comprobar skills, dependencias y navegador por separado; no copiar perfiles ni almacenes de credenciales por inferencia.

Para seleccionar Chromium completo, usar `channel="chromium"` con headless activo (por ejemplo, `headless=True` en Python o `headless: true` en JavaScript). El agente realiza internamente la navegación y las capturas de evidencia cuando la herramienta y el alcance estén autorizados; solicita intervención solo ante una autorización que falte, MFA, CAPTCHA, permisos o un recurso inaccesible. Esta precisión prevalece sobre ejemplos anteriores que deleguen al usuario abrir y capturar una página que el agente puede comprobar dentro del alcance autorizado.

Los procedimientos específicos de grabación o demostración de una interfaz solicitada conservan sus herramientas y permisos. Las comprobaciones internas y E2E web de esos repositorios siguen el carril anterior; los motores productivos existentes conservan su arquitectura.

<!-- skill-anexos:navegacion-e2e-coherencia-20261025:end -->
