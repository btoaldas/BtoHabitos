# S001 — BtoHabitos

- Estado: Aprobada
- Aprobada por: Alberto — 2026-10-15 — «Apruebo BtoHabitos, el plan y las tareas»
Nivel: L — laboratorio personal, con controles de autenticación y concurrencia
Fecha: 2026-10-15
Origen: alcance y criterios académicos comunicados por el coordinador el 15 de octubre. Paquete técnico aún sin aceptación final; no se registra una aprobación humana inexistente.

## 1. Problema y propósito

Una persona necesita convertir ideas de hábitos y tareas en una rutina propia. La aplicación permite explorar plantillas, organizar hábitos privados y recibir ayuda breve sin exponer claves del proveedor ni crear acciones sugeridas sin consentimiento.

## 2. Actores

Persona registrada; visitante que registra/inicia sesión; coordinador que valida el laboratorio y entrega el proyecto.

## 3. Alcance

Aplicación original con Catálogo, Mis hábitos y Asistente; 21 plantillas, cuentas, CRUD privado, favoritos persistentes, modelo real desde servidor, estados y entrega reproducible. Excluye mapas, pagos, notificaciones, datos reales, consejos médicos y copia de otra aplicación.

## 4. Requerimientos funcionales

### RF-01 — Cuenta y sesión
- Actor: visitante o persona registrada.
- Acción: registrar cuenta, entrar, restaurar sesión válida y salir.
- Resultado: acceso a la cuenta propia; salida o expiración vuelve al formulario vacío.
- Medida: 2 usuarios sintéticos aislados; cero restauraciones obsoletas tras salir.
- Dado un acceso válido.
- Cuando se reabre la aplicación.
- Entonces conserva la sesión; una salida explícita impide restaurarla.

### RF-02 — Catálogo real
- Actor: persona registrada.
- Acción: consultar y abrir plantillas de hábitos/tareas.
- Resultado: 21 plantillas obtenidas del servidor con título, categoría, descripción y frecuencia.
- Medida: 21 identificadores únicos; cambiar una plantilla en el servidor se refleja sin recompilar.
- Dado el catálogo disponible.
- Cuando se abre Catálogo.
- Entonces aparece la lista y el detalle de la plantilla elegida.

### RF-03 — Hábitos propios
- Actor: persona registrada.
- Acción: crear desde plantilla o formulario, listar, editar, completar/reabrir y eliminar con confirmación.
- Resultado: rutina privada persistente sin alterar el catálogo ni los hábitos ajenos.
- Medida: altas/ediciones persisten tras relanzar; cancelación elimina cero elementos; acceso ajeno rechazado.
- Dado un hábito propio.
- Cuando se edita o confirma su eliminación.
- Entonces la lista y la base coinciden y la otra cuenta conserva sus datos.

### RF-04 — Favoritos persistentes
- Actor: persona registrada.
- Acción: marcar/desmarcar plantillas y filtrar favoritas.
- Resultado: favoritos propios conservados entre procesos, sin cruzarse entre usuarios.
- Medida: 2 procesos independientes y secuencia A→B→A con resultados separados.
- Dado un favorito de A.
- Cuando se reinicia y vuelve a entrar A.
- Entonces sigue marcado; B no lo observa como propio.

### RF-05 — Asistencia real y confirmación
- Actor: persona registrada.
- Acción: consultar un consejo o pedir una propuesta de hábito y decidir guardarla.
- Resultado: respuesta de un modelo real a través del servidor; propuesta validada y guardada solo tras confirmar.
- Medida: cancelar produce 0 altas; confirmar produce 1; una respuesta tardía tras salir produce 0 altas en otra sesión.
- Dado una propuesta válida.
- Cuando la persona cancela o cambió la sesión.
- Entonces no se crea; al confirmar con la sesión original vigente se guarda una vez.

### RF-06 — Estados y errores legibles
- Actor: persona usuaria.
- Acción: navegar y reintentar cuando la operación falla.
- Resultado: carga, vacío, éxito y error diferenciados en las tres pestañas; controles recuperados.
- Medida: 400/401/422/5xx, timeout, red caída y salida de modelo malformada tienen casos negativos; cero cargas indefinidas.
- Dado un fallo temporal.
- Cuando se restablece el servicio y reintenta.
- Entonces se muestra el resultado actual sin datos de otra sesión.

### RF-07 — Entrega reproducible
- Actor: persona revisora.
- Acción: seguir instrucciones desde una copia limpia y descargar/instalar el APK publicado por el flujo automatizado.
- Resultado: servidor, app y pruebas reproducibles; documentación y capturas corresponden a la versión entregada.
- Medida: 1 flujo CI verde y 1 release con APK instalado; README incluye entorno de ejemplo, créditos y decisión técnica.
- Dado la versión final.
- Cuando se siguen sus comandos y se descarga su APK.
- Entonces se reproduce el recorrido documentado sin secretos incluidos.

## 5. Requerimientos no funcionales

| ID | Categoría | Requisito medible | Verificación |
|---|---|---|---|
| RNF-01 | Privacidad | 0 claves de proveedor/tokens/contraseñas en Git, APK, capturas o cuerpo enviado al proveedor; 0 claves de proveedor en Flutter | Inspección y prueba del adaptador |
| RNF-02 | Concurrencia | 0 respuestas, 401 o escrituras tardías aplicadas a una sesión nueva; 2 controladores concurrentes no reordenan almacenamiento | Pruebas con barreras determinísticas |
| RNF-03 | Interacción | 3 pestañas en español; áreas táctiles mínimas 48×48; toda petición termina o falla en un máximo configurable de 30 segundos | Widget y recorrido real |
| RNF-04 | Calidad | 0 fallos en análisis y suites pertinentes; CI limpia más APK release instalado y persistencia entre 2 procesos | Registros y segundo ángulo |

## 6. Casos límite y fallos

Correo duplicado, formulario inválido, expiración, token manipulado, ID ajeno/inexistente, servidor/proveedor caído, lista vacía, modelo sin JSON válido o con acción desconocida, doble toque, salida durante consulta/CRUD/restauración y apertura/cierre concurrentes de almacenamiento. Un POST ya aceptado puede completar para su usuario original; su resultado jamás se publica bajo otra cuenta.

## 7. Datos y cumplimiento

Cuentas y hábitos sintéticos; correo de prueba, derivado de contraseña, preferencias e identificadores. Los logs omiten contenido sensible. Ámbito personal/laboratorio, sin política institucional atribuida. Retener datos de prueba hasta una decisión explícita de retirada; no purgar por rutina.

## 8. Supuestos y dependencias

El coordinador facilita SDK y configuración privada de un modelo real compatible; los contratos y dobles permiten construir antes de ese acceso. Publicación depende de destino y autoridad concretos. Los detalles técnicos viven en plan/contratos, no implican un despliegue ya realizado.

## 9. Decisiones y aclaraciones

### Sesión 2026-10-15

Alcance comunicado: aplicación independiente de hábitos/tareas, 21 plantillas desde datos del servidor, cuentas y CRUD aislados, favoritos persistentes, asistente real desde servidor, tres pestañas, CI/APK y documentación. Se propone implementación por lotes L01–L03; revisión del paquete técnico y aceptación de producto aún pendientes. No se marca ningún RF como cumplido.


## Aprobación del paquete el 15 de octubre de 2026

Alberto aprobó conjuntamente el alcance, el plan y las tareas con la respuesta explícita «Apruebo BtoHabitos, el plan y las tareas». Se autoriza iniciar la construcción local; esta aprobación no registra todavía aceptación de resultados ni publicación de un remoto nuevo.
