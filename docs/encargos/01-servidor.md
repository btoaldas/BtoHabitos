# BtoHabitos — servidor original de hábitos

Lee primero `AGENTS.md` y `docs/specs/001-habitos/{spec,plan,tasks,data-model}.md`, contrato `contracts/README.md`. Trabajas en paralelo con Flutter: no estás solo; no revertir cambios ajenos. Propiedad exclusiva: `server/`. No tocar archivos fuera de esa ruta. La revisión del paquete por el coordinador precede al lanzamiento.

Construye servidor FastAPI/SQLite conforme al contrato: scrypt/JWT, 21 plantillas en JSON semilla idempotente, CRUD por usuario, adaptador IA compatible con OpenAI solo servidor y pruebas. Historial de hábitos separado de favoritos locales. Env.example sin secretos; servidor loopback18310 y README exacto. T01–T04,T13. Bibliotecas compatibles fijadas; no JWT artesanal, contraseñas en claro ni claves por defecto funcionales.

Prueba primero autorización: cada operación con token manipulado/expirado y ID de otro usuario, sin confiar en user_id del cliente. Barrera de proveedores falsos: inspeccionar petición y afirmar que no lleva correo/token/detalle; variar respuesta/malformado/timeout y verificar diferencias reales. Propuesta de IA jamás escribe hábitos. Semilla dos veces conserva21IDs; CRUD persiste al cerrar/reabrir SQLite. Proveedor no configurado da503, no respuesta simulada oculta.

No abrir notas privadas, configurar proveedor real, conectarse a servicios ajenos, copiar otra app, instalar SDK global, crear servicios de arranque, borrar datos previos, publicar o enviar. Pruebas con bases nuevas sintéticas aisladas; ninguna purga fuera de fixtures creadas por las pruebas.

Aceptación del coordinador: entorno limpio instala/arranca, suite del servidor verde con casos negativos verificables, lectura/CRUD real con dos cuentas y21plantillas. Entrega lista de archivos, comandos+resultados, contrato final, límites reales, próximos pasos de proveedor. No marcar tareas/criterios de producto aceptados por tu cuenta ni crear commits, remotos o pushes dentro del área del motor.
