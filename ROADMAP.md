# Estado de BtoHabitos — 2026-10-15

Nivel: L, laboratorio académico personal. Alcance aprobado S001: catálogo de 21 plantillas, autenticación, hábitos privados, favoritos por usuario, asistente real y APK educativo.

## Ahora

Producto construido, validado técnicamente y entregado. CEDIA 49762 confirmó **Enviado para calificar — Sin calificar**, 15 de octubre a las **20:36**, con el enlace `https://github.com/btoaldas/BtoHabitos`. La calificación depende del docente.

## Etapas completadas

1. Especificación, plan y tareas aprobados por Alberto; construcción versionada por lotes.
2. Flutter y servidor integrados: análisis sin incidencias, 92 pruebas Flutter, 160 servidor y 8 auxiliares. Web/API reales con dos cuentas, persistencia, concurrencia y proveedor de IA real.
3. GitHub público `btoaldas/BtoHabitos`, rama `main`, autorizado y publicado. CI main 38834146256, CI tag 38834361808 y Release 38834361906 correctos.
4. Release `v1.0.0` sobre `99acfec`, APK de CI descargado también sin autenticación: SHA-256 coincidente, firma y privacidad comprobadas. Instalación nueva en Android emulado, relanzamiento con sesión/favorito persistentes, A/B aisladas y consejo real sin altas.
5. Enlace entregado en Moodle y comprobado tras recargar. Captura y Word final con GitHub, commits, APK y examen enviados al grupo privado autorizado de cuatro personas; ecos de salida comprobados, lectura no confirmada.

Evidencia: [matriz S001](docs/specs/001-habitos/verificacion.md), [APK exacto](evidence/l03/resultado-apk-ci.json), [descarga](evidence/l03/descarga-apk-ci.json), [Moodle](evidence/l03/entrega-moodle.json) y [hito técnico](docs/hitos/2026-10-15-producto-validado.md).

## Límites y decisiones futuras

El APK es educativo, con firma de depuración y API predeterminada para el emulador. No se desplegó infraestructura productiva ni se probó un teléfono físico. Credenciales, cuentas y bases del laboratorio permanecen privadas. Cualquier mejora de alcance o distribución productiva requiere una decisión nueva.

<!-- sdd:indice:inicio -->
| Spec | Estado | Lotes |
|---|---|---|
| [001 Hábitos](docs/specs/001-habitos/spec.md) | Aprobada; 21 tareas verificadas, aceptación técnica y entrega completas; calificación docente pendiente | L01–L03 |
<!-- sdd:indice:fin -->
