# Cierre local — 15 de octubre de 2026

Estado: **local funcional verificado** sobre `9ffd795`. Android 16/API 36 ARM64 instaló el APK local `com.bto.habitos` (53,853,576 bytes; SHA-256 `6555d808f37f8355aea77862c29d381e64f2254fdad4075d4b8f930e5bfb54f8`): catálogo de 21 tarjetas en cinco pantallas, aislamiento A/B y persistencia nativa de sesión/favorito entre PID 6642→7028 (reporte del coordinador). Consejo real visible; cero altas ni errores logcat.

En Flutter web R2, glm-4.5-air: cancelar produjo cero altas; confirmar produjo una y se eliminó por UI únicamente el fixture nuevo ID 3, dentro de la operación anunciada. Los dos hábitos originales quedaron idénticos y uno completado. Suites existentes: servidor 160/160, Flutter 92/92, helpers 8/8, focales 22/22; análisis sin hallazgos. No se repitieron.

API observó un 502 legible sin mutaciones y, en segunda pasada, dos respuestas HTTP 200 (consejo/propuesta) sin escrituras. Se conserva el 502 como límite observado; causa no determinada. El APK local detectó URI de compilación privada en tres ABI: no publicable. Se requiere APK CI limpio.

Alberto autorizó la publicación pública de `btoaldas/BtoHabitos`; el coordinador la ejecutará. El remoto público https://github.com/btoaldas/BtoHabitos está creado; push, CI, release y Moodle siguen pendientes. Gates restantes: CI remota, APK final CI descargable y entrega Moodle.

Evidencia: [L01](../../evidence/l01/resultado.json), [L02](../../evidence/l02/asistente-real.json), [Android](../../evidence/l03/resultado-android-local.json), [build local](../../evidence/l03/build-local.json), [fixture temporal R2](../../evidence/l02/propuesta-temporal-r2.json).

Observación posterior independiente: a las 20:06:26 (Ecuador), el hábito sintético ID 2 cambió de completado=false a true y la API mostró 2/2. La causa está en investigación; no se atribuye un bug. El cierre Android de las 20:02:39 conserva 2 hábitos/1 completado y el ensayo web de las 20:04:37 conservó sus dos originales con 1 completado; esos recibos históricos no se modifican.
