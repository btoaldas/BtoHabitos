# Verificación S001 — cierre local

Estado: **local funcional verificado** sobre fuentes `9ffd795`. La aceptación final y la entrega dependen de CI remota, APK final generado en runner limpio y entrega Moodle. El APK de compilación local detectó una URI de compilación privada en sus tres ABI; no publicar ese APK. La compilación local sí fue instalada y recorrida.

| Req. | Alcance verificado local | Evidencia |
|---|---|---|
| RF-01 | Sesión, aislamiento A/B; token y favorito persistieron entre dos procesos Android reales (PID 6642→7028; reporte del coordinador, sin leer JWT). | [Android](../../../evidence/l03/resultado-android-local.json), [L01](../../../evidence/l01/resultado.json) |
| RF-02 | Semilla 21 IDs únicos y cambio DB→API; recarga Flutter sin recompilar; UI Android recorrió 21 tarjetas en cinco pantallas. | `server/tests/test_catalogo_db.py:14-37`; `test/catalogo_test.dart:15-32`; [Android](../../../evidence/l03/resultado-android-local.json) |
| RF-03 | CRUD, completado y aislamiento cubiertos por API/SQLite; R2 web confirmó una propuesta y eliminó solo el fixture nuevo ID 3. Dos originales idénticos al final. | [L01](../../../evidence/l01/resultado.json), [fixture R2](../../../evidence/l02/propuesta-temporal-r2.json) |
| RF-04 | Favorito persistió entre dos procesos Android; cuenta B mostró cero favoritos. | [Android](../../../evidence/l03/resultado-android-local.json) |
| RF-05 | API real: primer 502 legible sin mutaciones; segunda pasada, consejo y propuesta HTTP 200 sin escrituras. UI web R2 confirmó propuesta (1 alta) y UI Android mostró consejo real (0 altas). | [L02](../../../evidence/l02/asistente-real.json), [fixture R2](../../../evidence/l02/propuesta-temporal-r2.json), [Android](../../../evidence/l03/resultado-android-local.json) |
| RF-06 | Errores, timeout y recuperación: servidor y Flutter; estados 500/reintento/vacío y 422/503 en widgets. La matriz extensa del asistente corresponde a controladores. | `test/estados_widget_test.dart:24`; `test/asistente_test.dart:147,182,242,273`; [L02](../../../evidence/l02/asistente-real.json) |
| RF-07 | Suites/análisis y APK local instalado verificados. El APK local no es publicable por URI privada. | [build local](../../../evidence/l03/build-local.json), [Android](../../../evidence/l03/resultado-android-local.json) |
| RNF-01 | Pruebas de privacidad y evidencia saneada; APK local detecta URI privada y queda excluido de publicación. | [build local](../../../evidence/l03/build-local.json) |
| RNF-02 | Carreras focales, persistencia SQLite en tres procesos, aislamiento API y persistencia móvil entre dos procesos. | `server/tests/test_catalogo_db.py:84`; [Android](../../../evidence/l03/resultado-android-local.json) |
| RNF-03 | Control táctil 48×48 medido por helper en flujos/estados/widgets de autenticación; recorrido nativo del catálogo en cinco pantallas. | `test/support/widget_helpers.dart:104`; [Android](../../../evidence/l03/resultado-android-local.json) |
| RNF-04 | Servidor 160/160, Flutter 92/92, helpers 8/8, análisis sin hallazgos; focales 22/22 y canarios R1→R2 corregidos, según resultados existentes. | [L01](../../../evidence/l01/resultado.json), [L02](../../../evidence/l02/asistente-real.json), [build local](../../../evidence/l03/build-local.json) |

**Gates finales:** CI remota; APK de CI en runner limpio, descargable y verificable; entrega Moodle. La autorización para publicar `btoaldas/BtoHabitos` como repositorio público está concedida y su ejecución corresponde al coordinador. El [remoto público](https://github.com/btoaldas/BtoHabitos) está creado; push, CI, release y entrega aún no están acreditados.

Observación posterior independiente: a las 20:06:26 (Ecuador), el hábito sintético ID 2 cambió de completado=false a true y la API mostró 2/2. La causa está en investigación; no se atribuye un bug. El cierre Android de las 20:02:39 conserva 2 hábitos/1 completado y el ensayo web de las 20:04:37 conservó sus dos originales con 1 completado; esos recibos históricos no se modifican.
