# ADR001 — Arquitectura del laboratorio

Fecha: 2026-10-15. Estado: propuesta para revisión técnica.

## Contexto

Una app académica independiente necesita cuentas,21plantillas,CRUD privado,persistencia y un asistente real reproducibles sin infraestructura ajena. Se prioriza el recorrido de usuario y aislamiento, no una plataforma productiva.

## Decisión propuesta

Flutter/GetX con Dio y almacenamiento seguro; Hive solo para favoritos por usuario. FastAPI/Pydantic con SQLite y JSON semilla. Contraseña derivada mediante scrypt y JWT de biblioteca mantenida; secretos por entorno. Adaptador de IA compatible con OpenAI en servidor, nunca clave dentro del APK. Tres pestañas en español.

## Alternativas descartadas

Renombrar otra app no cumple identidad independiente. Base remota añade infraestructura innecesaria al laboratorio; SQLite permite evidenciar persistencia y propiedad. Clave de IA en Flutter expone credenciales. Respuestas por reglas no acreditan modelo real. Escrituras offline añaden reconciliación y quedan fuera del mínimo.

## Consecuencias y comprobación

Android emulado accede al host por10.0.2.2; la ejecución fuera del laboratorio exige otro destino autorizado y HTTPS. SQLite y archivos de entorno quedan fuera de Git. La cola de almacenamiento/guardas de sesión forman parte del contrato y se prueban con interleavings controlados. El modelo real y la publicación dependen del coordinador; los dobles solo permiten desarrollo, no aceptación final.
