# Estado de BtoHabitos — 2026-10-15

Nivel: L, laboratorio académico personal, con controles adicionales por autenticación y concurrencia. Módulos aplicables: requisitos, arquitectura/datos/seguridad, móvil y CI; operación productiva, pagos y correo quedan fuera.

## Ahora

Revisar el paquete técnico `docs/specs/001-habitos/` y los encargos `docs/encargos/`. No hay código de producto ni implementación aceptada. El alta local no autoriza remoto o publicación.

## Siguiente

1. L01: servidor y primera rebanada Flutter, con registro/login, 21 plantillas y CRUD privado.
2. L02: favoritos entre procesos y asistente real con confirmación y guardas de sesión.
3. L03: integración, errores, recorridos negativos, CI/APK, README y capturas.
4. Publicación y entrega por el coordinador tras comprobar destino y autoridad.

## Dependencias y decisiones externas

- El coordinador aportará configuración privada del proveedor/modelo de IA; no bloquea construcción ni pruebas determinísticas, sí la aceptación del recorrido real de IA.
- Flutter/SDK y Android: disponibilidad y validación en el entorno del coordinador; el constructor no reinstala ni cambia el SDK global.
- Remoto: plataforma, propietario, nombre y visibilidad concretos aún sin resolver para este proyecto. No crear ni publicar por herencia de otro repositorio.
- Incorporación al mapa de proyectos y registro durable: se entrega al coordinador la clasificación y el commit basal; no se copia contexto privado a este árbol.

## Después

Mejoras opcionales solo tras cerrar la entrega: recordatorios, estadísticas históricas y sincronización offline de escrituras. No forman parte de la aceptación actual.

<!-- sdd:indice:inicio -->
| Spec | Estado | Lotes |
|---|---|---|
| [001 Hábitos](docs/specs/001-habitos/spec.md) | Propuesta para revisión técnica | L01–L03 |
<!-- sdd:indice:fin -->
