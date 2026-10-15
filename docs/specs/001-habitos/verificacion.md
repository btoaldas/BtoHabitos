# Verificación S001

Estado: Pendiente; no hay código ni pruebas de producto ejecutadas. Las comprobaciones del alta documental no acreditan funcionamiento de la aplicación.

| Requisito | Tareas | Casos requeridos | Resultado | Evidencia/commit/entorno | Segundo ángulo |
|---|---|---|---|---|---|
| RF-01 | T02,T06,T07,T10,T19 | registro/login/restauración/salida/401; dos instancias | No ejecutado | — | UI+storage entre procesos |
| RF-02 | T01,T08,T10,T19 | 21IDs, detalle, cambio semilla | No ejecutado | — | SQLite+UI |
| RF-03 | T03,T09,T10,T19 | CRUD, completar, cancelar, IDOR A/B | No ejecutado | — | API/DB+UI |
| RF-04 | T11,T12,T15,T19 | favorito entre procesos, A→B→A, cajas concurrentes | No ejecutado | — | Hive real+APK relanzado |
| RF-05 | T13,T14,T15,T19 | modelo real, cancelar0/confirmar1, malformado, logout | No ejecutado | — | proveedor real+DB/UI |
| RF-06 | T03,T07,T08,T09,T14,T16,T19 | 400/401/422/5xx/red/timeout/vacío/reintento | No ejecutado | — | pruebas controladas+red real |
| RF-07 | T17,T18,T20,T21 | clon limpio, CI, release, APK instalado, README | No ejecutado | — | descarga/instalación+fuentes |
| RNF-01 | T02,T13,T15,T18,T21 | ausencia de secretos y minimización | No ejecutado | — | inspección+petición capturada saneada |
| RNF-02 | T06,T09,T11,T14,T19 | carreras session/storage/repositorio/401 | No ejecutado | — | barreras determinísticas+dos cuentas |
| RNF-03 | T16,T20 | tres pestañas,48×48,timeout y estados | No ejecutado | — | widgets+APK |
| RNF-04 | T17,T18,T19,T20,T21 | suites,análisis,CI,APK,persistencia | No ejecutado | — | entorno limpio+flujo real |

No declarar cumplimiento con dobles que dependan del nombre del caso. Una prueba roja controlada debe demostrar que el arnés distingue el fallo real cuando corresponda. No repetir suites concurrentemente ni inventar datos retrospectivos. El cierre identifica desviaciones, límites y aprobación humana aplicable.
