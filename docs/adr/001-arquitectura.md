# ADR 001 — Arquitectura del laboratorio

- Fecha: 2026-10-15.
- Estado: **decisión aprobada para construcción local** según el plan S001 aprobado por Alberto el 15 de octubre de 2026.
- Alcance de la aprobación: arquitectura y construcción académica local. No implica aceptación de la app integrada, del proveedor real, CI remota, APK publicado ni uso productivo.

## Contexto

El producto académico requiere cuentas, un catálogo remoto de 21 plantillas, CRUD privado, favoritos persistentes y un asistente real. Debe poder ejecutarse en un laboratorio local con datos sintéticos, sin depender de infraestructura ajena ni exponer credenciales en el cliente. El recorrido y el aislamiento tienen prioridad sobre la operación productiva.

## Decisión

- **Cliente:** Flutter/Dart con GetX para estado y navegación, en capas de presentación, controladores, servicios, repositorios y modelos. Dio centraliza HTTP, token, timeouts y errores. El token vive en almacenamiento seguro. Hive conserva únicamente IDs de favoritos, separados por usuario.
- **Servidor:** FastAPI/Pydantic con SQLite. El servidor deriva el propietario del JWT validado; no acepta identidad del cliente para filtrar datos. Cada operación SQLite administra sus conexiones. La semilla inserta IDs ausentes sin sobrescribir datos existentes.
- **Seguridad de cuentas:** scrypt con salt aleatorio por contraseña; JWT firmado mediante biblioteca mantenida, algoritmo HS256 fijo y expiración. La clave se configura privadamente en el servidor y debe tener al menos 32 bytes.
- **Asistente:** el servidor envía consulta y agregados mínimos a un proveedor HTTPS compatible con OpenAI. Exige respuesta JSON estructurada, `stream=false`, `max_tokens=512` y timeout acotado. Solo configura `thinking={"type":"disabled"}` para proveedores que lo requieran. El cliente confirma explícitamente una propuesta antes del CRUD.
- **Entorno:** API en `127.0.0.1:18310`; Android emulado usa `10.0.2.2:18310`. No se abre el bind del servidor a interfaces de red.

## Ventajas y costes

La separación cliente/servidor mantiene la clave de IA fuera del APK y permite que las pruebas ejerciten el contrato HTTP real. SQLite hace reproducible el aislamiento por propietario y la persistencia entre procesos sin servicio de base de datos externo. Hive limitado a favoritos evita duplicar datos privados y reduce la reconciliación offline.

El laboratorio exige configurar el servidor y no representa disponibilidad o escalabilidad productiva. Cambiar el secreto JWT invalida todos los tokens previos; no hay revocación por sesión. Los favoritos son locales al dispositivo. Un proveedor incompatible con el formato JSON estricto no sirve para este adaptador. El asistente transmite el texto libre ingresado, por lo que la persona debe evitar datos sensibles.

En Flutter, el cambio de sesión invalida operaciones anteriores antes de esperas; las colas compartidas serializan el acceso al almacenamiento seguro y Hive. Una respuesta o 401 obsoletos no deben modificar una sesión nueva. Estos controles son parte de la implementación, pero su aceptación conjunta permanece pendiente de la verificación de integración.

## Alternativas descartadas

- Renombrar o copiar otra aplicación incumple la identidad original e independiente.
- Una base remota añade infraestructura y credenciales fuera del laboratorio; SQLite basta para la escala y la evidencia académica previstas.
- Poner la clave del modelo en Flutter expone el secreto a quien inspeccione el APK.
- Respuestas basadas en reglas o dobles pueden ayudar a pruebas determinísticas, pero no acreditan el asistente real.
- Guardar hábitos offline añade resolución de conflictos y sincronización; queda fuera del alcance mínimo.
- Guardar hábitos privados completos en Hive duplicaría el origen servidor y elevaría el riesgo de exposición local.

## Estado de validación

La app Flutter y el servidor están integrados localmente en el historial del proyecto. Este ADR registra la decisión de arquitectura, no una aceptación de resultados. La ejecución conjunta de suites, recorrido UI/API/SQLite con dos cuentas, verificación entre procesos, proveedor real, CI remota y APK publicado siguen pendientes del coordinador. La especificación y los criterios están en el [plan S001](../specs/001-habitos/plan.md) y el [contrato HTTP](../specs/001-habitos/contracts/README.md).
