# Hito: BtoHabitos validado técnicamente — 15 de octubre de 2026

## Resultado

Objetivo técnico cumplido sobre fuentes publicadas en `99acfecbac94fd8a0a54181239adbdc5a25c612d`. Las 21 tareas S001 están verificadas. La aceptación técnica del paquete fue realizada por el coordinador. La entrega Moodle de la actividad 49762 se confirmó a las 20:36 como “Enviado para calificar”; la calificación sigue “Sin calificar”, sin aceptación docente acreditada.

## Evidencia

- Suites: servidor 160/160, Flutter 92/92, helpers 8/8, 22 pruebas focales y dos regresiones; análisis Flutter sin hallazgos.
- CI main [38834146256](https://github.com/btoaldas/BtoHabitos/actions/runs/38834146256), CI tag [38834361808](https://github.com/btoaldas/BtoHabitos/actions/runs/38834361808) y Release [38834361906](https://github.com/btoaldas/BtoHabitos/actions/runs/38834361906): correctos.
- Release pública [v1.0.0](https://github.com/btoaldas/BtoHabitos/releases/tag/v1.0.0). APK CI: 53,853,576 bytes; SHA-256 `6a947d78234922d7d9fcab06030282ee37ad8c7c1e7ea0d0d2fa8713cc766be8`. Descarga sin autenticación HTTP 200, digest coincidente, CRC ZIP válido y escaneo sin archivos privados, rutas privadas del host ni secretos reales.
- Instalación nueva con firma válida y hash instalado coincidente en emulador Android 16/API 36 `5560`; relanzamiento PID 5195→5609 conservó sesión/favorito. A: 2 hábitos/2 completados; B: 0 hábitos/0 favoritos y sin respuesta del asistente de A; retorno a A conservó favorito. Consejo real: cero altas; aplicación: cero errores.
- Recibos canónicos: [resultado de APK CI](../../evidence/l03/resultado-apk-ci.json), [descarga/privacidad](../../evidence/l03/descarga-apk-ci.json), [entrega Moodle](../../evidence/l03/entrega-moodle.json).

## Límites y observación de datos

La prueba Android fue en emulador, no en dispositivo físico. La firma es educativa y no equivale a firma de producción. El APK local `6555d808f37f8355aea77862c29d381e64f2254fdad4075d4b8f930e5bfb54f8` conserva URI de compilación privada y queda excluido; el APK CI de release es el entregado.

Se conservan los resultados históricos: Android local 20:02:39 y web 20:04:37 registraron 2 hábitos/1 completado; el estado observado cambió a 2/2 a las 20:06:26; la revisión visual empezó a las 20:08:45 y sus taps no apuntaron al checkbox. El APK CI registró 2/2 a las 20:35:14. El origen del cambio no está atribuido; no se infiere bug automático ni intervención de persona.
