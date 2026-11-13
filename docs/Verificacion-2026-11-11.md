# Verificación del incremento · 11 de noviembre de 2026

## Resultado

- 18 pruebas automatizadas de Flutter superadas: contenido, diagnóstico, navegación, reanudación, evaluación, calendario, descargas y sincronización local.
- `dart analyze lib tool test`: sin incidencias. El lanzador `flutter analyze` falló al comunicar la ruta con caracteres acentuados al servidor de análisis; se utilizó el analizador directo sobre las mismas carpetas de código y pruebas.
- PostgreSQL 16 desechable: instalación del esquema, aislamiento de dos identidades, permisos de lectura, rechazo de acceso anónimo y escrituras directas, validación de respuestas y tipos, reenvío sin duplicados, reversión de un lote erróneo y paginación de 101 sesiones. Las bases de prueba se eliminaron al terminar.
- Dos cuadernos Sembast independientes convergen con un servicio simulado, incluido el caso en el que se pierde la respuesta después de guardar en el servidor. Dos repasos simultáneos se conservan sin contar como dos recuperaciones espaciadas.
- Chrome con perfil de prueba: la caché inicial no contiene paquetes de las unidades. Tras descargar «Sumar lo que pasa el filtro», recargar con la red desactivada permite reanudar en la pregunta 2. Con la caché HTTP desactivada, borrar el paquete e intentar descargarlo sin red muestra un error. Reconectar y descargar de nuevo conserva el borrador.

- Compilación web final verificada en navegador: acceso a cuentas desde la pantalla principal, aviso de servicio pendiente y tamaño/versión de las descargas visibles.

## Límites

La aplicación incluye tres lecciones y permite descargar otras nueve. Las sesiones terminadas y los repasos tienen sincronización manual preparada; no está activada porque aún no existe el proyecto de Supabase. La autenticación real, la pasarela HTTP y la convergencia entre dispositivos físicos no se han probado. Borradores, diagnósticos, selección de materias y descargas siguen siendo locales.

Quedan pendientes la revisión docente de las doce lecciones, privacidad y accesibilidad del piloto, pruebas Android/iOS, y ensayo de recuperación de una copia en el servicio real. Esta entrega es un avance demostrable hacia el MVP, no la aceptación completa prevista para diciembre.
