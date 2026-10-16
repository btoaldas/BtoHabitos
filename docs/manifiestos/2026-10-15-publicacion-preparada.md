# Publicación y entrega preparadas — 15 de octubre de 2026

Estado: operación autorizada y ejecutada; publicación, APK de CI, aceptación técnica y entrega Moodle comprobados. El plan inicial se conserva y los resultados se registran al final.

## Destino propuesto y autoridad

- Plataforma: GitHub.
- Propietario y nombre: `btoaldas/BtoHabitos`.
- Visibilidad autorizada: pública; rama predeterminada: `main`.
- El 15 de octubre Alberto confirmó expresamente: «Sí, publicar btoaldas/BtoHabitos público». La pregunta aprobada incluía crear y publicar el repositorio, código, historial y APK educativo con rama `main`.
- Actividad de entrega: `https://cursos.cedia.org.ec/mod/assign/view.php?id=49762`.
- El aula solicita el enlace del repositorio. La entrega y su comprobación pertenecen al coordinador.

## Contenido previsto

Historia Git real de construcción, fuentes Flutter y FastAPI, locks, pruebas, documentación y evidencia saneada. Fuentes ejecutables verificadas: `9ffd795deef718901556191c8a6c66583df3c607`; las revisiones documentales posteriores no se presentan como cambios funcionales.

Quedan fuera configuraciones privadas, bases y cuentas del laboratorio, entornos virtuales, temporales, logs crudos y documentos personales. El APK compilado localmente conserva una URI de compilación privada en sus tres ABI: se mantiene como artefacto privado de prueba y no se usará como descarga pública. El APK de entrega se construirá en un runner limpio de GitHub Actions, después de comprobar calidad y el destino autorizado.

El APK es educativo, versión `1.0.0+1`, firmado con la clave de depuración según la configuración Android. Su API predeterminada apunta al host del emulador (`http://10.0.2.2:18310`). Un teléfono físico requiere un endpoint HTTPS autorizado por separado; no se publica infraestructura del laboratorio como parte de esta operación.

## Secuencia y comprobación

1. Registrar la decisión explícita de destino y visibilidad; revisar el archivo Git completo para descartar secretos y datos privados.
2. Crear el remoto acordado y publicar `main` sin reescribir historia. Comparar identidad, rama, HEAD y contenido remoto.
3. Exigir CI remota verde. Crear una etiqueta de versión educativa únicamente tras la verificación local y remota pertinente.
4. Descargar el APK generado por Actions/Release, cotejar SHA-256, firma y contenido; verificar su instalación y recorrido real con datos sintéticos. No confundir el APK local con el artefacto de CI.
5. Actualizar README, matriz y documento editable con las URLs reales de repositorio, commits, Actions y Release, y con sus estados comprobados.
6. Enviar el enlace en la actividad final mediante su formulario; recargar y comprobar estado, URL y fecha. Conservar constancia sin confundir enviado con calificado.
7. Compartir documento y constancia solamente en el grupo privado autorizado de cuatro participantes, después de verificar la entrega. Conservar identificadores y estado real de los mensajes.

## Recuperación y límites

Conservar commits, artefactos y evidencias anteriores. Si una comprobación falla, detener el paso dependiente y registrar el motivo. Corregir mediante commits y versiones nuevas. Este manifiesto no autoriza borrar remotos, retirar releases, reescribir historia ni reemplazar recursos existentes.

## Resultado ejecutado y comprobado

- Repositorio público `https://github.com/btoaldas/BtoHabitos`, rama `main`, historia real publicada; release `v1.0.0` sobre `99acfecbac94fd8a0a54181239adbdc5a25c612d`.
- CI main 38834146256, CI tag 38834361808 y Release 38834361906: success. APK público de 53 853 576 bytes, SHA-256 `6a947d78234922d7d9fcab06030282ee37ad8c7c1e7ea0d0d2fa8713cc766be8`. Dos descargas coincidentes, una anónima HTTP 200; firma, CRC ZIP y privacidad comprobadas.
- APK descargado exacto instalado sin reemplazar aplicaciones en un emulador nuevo. Relanzamiento en proceso nuevo, sesión/favorito, A/B y asistente real: PASS, cero errores de app. [Recibo](../../evidence/l03/resultado-apk-ci.json).
- Moodle actividad 49762: enlace exacto del repositorio guardado por formulario y verificado después de recargar; última modificación 2026-10-15 20:36, Enviado para calificar, Sin calificar. [Constancia saneada](../../evidence/l03/entrega-moodle.json).
- Captura y Word final de cinco páginas y once enlaces enviados únicamente al grupo privado autorizado de cuatro personas. Salida confirmada por identificador y eco; lectura sin confirmar. Los identificadores, documentos y captura permanecen en el respaldo privado, fuera de Git.
- No se reemplazó el APK local ni se reescribió la historia. Los recursos y recibos anteriores se conservan; las revisiones documentales no alteran la versión de la release.
