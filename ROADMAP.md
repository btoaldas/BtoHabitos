# Estado de BtoHabitos — 2026-10-15

Nivel: L, laboratorio académico personal, con controles adicionales por autenticación y concurrencia. Módulos aplicables: requisitos, arquitectura/datos/seguridad, móvil y CI; operación productiva, pagos y correo quedan fuera.

## Ahora

Completar la publicación y entrega del producto construido y versionado hasta `9ffd795`. Alberto aprobó el paquete S001 y autorizó el remoto público `btoaldas/BtoHabitos`, rama `main`, el 15 de octubre. Servidor, Flutter, favoritos, hábitos privados e IA real ya se comprobaron localmente; análisis sin incidencias, 92 pruebas Flutter, 160 del servidor y 8 auxiliares aprobadas. El APK local pasó instalación, relanzamiento, aislamiento y las tres pestañas. La aceptación final sigue abierta hasta verificar CI remota, APK público y entrega.

## Siguiente

1. Incorporar la evidencia local final y cerrar la matriz S001 solo donde existan pruebas reproducibles.
2. Publicar el historial en el remoto autorizado, ejecutar CI y generar el APK descargable desde una etiqueta.
3. Descargar el APK de CI y comprobar hashes, firma, privacidad y recorrido de la versión exacta.
4. Entregar el enlace de GitHub en CEDIA y comprobar que queda enviado para calificar; después compartir documento y constancia al grupo privado autorizado.

## Dependencias y decisiones externas

- El proveedor real está configurado privadamente en el servidor y ya respondió consejos y propuestas; una primera respuesta inválida fue rechazada sin escrituras. Sus credenciales no forman parte del repositorio.
- Flutter/SDK y Android están disponibles en un entorno aislado; NDK oficial instalado y APK local verificado sin modificar un SDK global.
- Remoto autorizado expresamente: GitHub `btoaldas/BtoHabitos`, público, rama `main`. Publicación y comprobación por el coordinador.
- Incorporación al mapa de proyectos y registro durable: se entrega al coordinador la clasificación y el commit basal; no se copia contexto privado a este árbol.

## Después

Mejoras opcionales solo tras cerrar la entrega: recordatorios, estadísticas históricas y sincronización offline de escrituras. No forman parte de la aceptación actual.

<!-- sdd:indice:inicio -->
| Spec | Estado | Lotes |
|---|---|---|
| [001 Hábitos](docs/specs/001-habitos/spec.md) | Aprobada; construcción local verificada, aceptación final en curso | L01–L03 |
<!-- sdd:indice:fin -->
