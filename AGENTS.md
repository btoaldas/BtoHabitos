# BtoHabitos — gobernanza del proyecto

Proyecto personal de formación y laboratorio: hábitos y tareas cotidianas. Es una aplicación nueva, independiente de ExploraEC, sin ámbito institucional ni uso productivo autorizado. Estado: alta documental y revisión técnica; todavía no hay aplicación implementada.

## Objetivo y alcance

Un usuario registra su cuenta, consulta 21 plantillas servidas desde una base, organiza sus propios hábitos, conserva favoritos y consulta un asistente con un modelo real llamado exclusivamente desde el servidor. Interfaz mínima: Catálogo, Mis hábitos y Asistente. Especificación y aceptación: `docs/specs/001-habitos/`.

No incluye mapas, geolocalización, pagos, notificaciones, consejos médicos, datos reales de terceros ni copia o cambio de marca de otra aplicación.

## Arquitectura y contratos

Flutter/Dart, GetX y capas de presentación/controladores/servicios/repositorios/modelos. Dio comparte autenticación; el token se guarda mediante almacenamiento seguro y nunca en Hive. Hive conserva únicamente identificadores de plantillas favoritas, separados por usuario. FastAPI y SQLite atienden autenticación, catálogo, CRUD y asistente. Contrato exacto: `docs/specs/001-habitos/contracts/README.md`.

El servidor de laboratorio escucha en `127.0.0.1:18310`. Android emulado usa `API_BASE_URL=http://10.0.2.2:18310`; el valor se configura al compilar. El proveedor de IA se configura únicamente en el entorno privado del servidor, con API compatible con OpenAI. Ninguna clave de proveedor llega a Flutter.

## Autoridad, conservación y colaboración

Está autorizada la preparación y construcción local del producto académico. Este repositorio empieza sin remoto. La creación del remoto, su propietario y visibilidad, publicación, entrega en el aula y despliegue externo pertenecen al coordinador y requieren su autoridad concreta; los constructores no los ejecutan.

Anunciar toda mutación con alcance, impacto, comprobación y recuperación. No borrar, sobrescribir recursos ajenos, desactivar servicios ni reescribir historia sin aprobación específica. Conservar archivos y datos preexistentes. Una recuperación destructiva necesita autorización aunque esté descrita en un plan. Los ensayos usan directorios temporales ignorados dentro del proyecto; no crear proyectos hermanos.

Los trabajadores tienen propiedad explícita de rutas. No están solos: no revertir cambios de otros; integrar únicamente trabajo revisado. Construcción, revisión y aceptación son responsabilidades distintas. Credenciales, publicación, envíos y aceptación final permanecen en el coordinador. El contexto privado se entrega por un canal local no versionado, nunca como parte de fuentes o entregables.

## Datos y seguridad

Usar cuentas y hábitos sintéticos en pruebas. No registrar tokens, contraseñas, claves, cabeceras de autorización, consultas privadas completas ni datos personales en Git o evidencias. Las contraseñas se derivan con scrypt y salt aleatorio; JWT se valida con algoritmo fijado, firma y expiración. El servidor deriva siempre el propietario de la sesión, no de un campo del cliente.

Los cambios de sesión invalidan operaciones anteriores antes de cualquier espera. Una respuesta o 401 tardío no modifica ni cierra una sesión nueva. Serializar almacenamiento seguro y apertura/cierre/escritura de Hive entre instancias; capturar la caja original. En web, cerrar la caja antes de eliminar una base si alguna limpieza autorizada lo requiere; evitar sondeos que dejen conexiones abiertas.

## SDD y documentación

Especificación, plan y tareas preceden al código. Construir por lotes con controles tempranos de aislamiento, concurrencia e integridad y aceptación conjunta al completar el recorrido. Distinguir construida, validada y cerrada. Marcar una tarea solo con evidencia reproducible; no inventar aprobaciones. Documentos: `docs/specs/`, decisiones: `docs/adr/`, avances: `docs/bitacora/`, cierres: `docs/hitos/` y cambios externos: `docs/manifiestos/`.

Reutilizar bibliotecas y procedimientos determinísticos pertinentes; documentar adaptar/crear/no aplica. No instalar hooks ni automatizaciones por inferencia. Consultar primero el grafo disponible para estructura y llamadas; después buscar texto puntual y leer funciones concretas. Evitar inventarios completos y contexto duplicado. El índice se hará al existir código; el alta documental no necesita indexar símbolos inexistentes.

## Verificación y ejecución

Los comandos finales se incorporarán y ejecutarán cuando el constructor entregue código; no se afirma que existan ahora. Plan: `flutter analyze`, `flutter test`, pruebas del servidor con `pytest`, build APK release y pruebas de flujo con API y base reales. CI analiza y prueba en un entorno limpio; una etiqueta de versión genera un APK descargable. Los datos y secretos no viajan en el APK.

No declarar terminado por un build, HTTP 200, una captura o un exit 0. Cada RF exige evidencia y segundo ángulo proporcional: pruebas controladas más recorrido real, consultas de base o persistencia entre procesos. Registrar límites, versiones, comandos y resultados en `evidence/` y en la verificación SDD.

## Git y recuperación

Rama inicial `main`, commits técnicos y neutrales con historia real por lote. No remoto, push, publicación ni despliegue implícitos. Respaldar el estado antes de cambios externos; documentar destino, versión, verificación y recuperación. Recuperar por commits/artefactos; no resetear, limpiar ni borrar sin la autorización correspondiente.
