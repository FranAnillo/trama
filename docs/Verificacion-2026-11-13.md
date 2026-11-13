# Verificación de la entrega · 13 de noviembre de 2026

## Comprobado

- 24 pruebas Flutter superadas. Cobertura de líneas ejecutables: 821/1041, 78,9 %. No se interpreta como cobertura completa de todos los comportamientos.
- Análisis estático sin incidencias sobre `lib`, `tool` y `test`.
- PostgreSQL 16 desechable: permisos, aislamiento entre dos identidades, validación, reintentos, reversión de lotes y paginación de 101 sesiones.
- Publicación Sites, versión 2: `https://trama-informatica.ireperezsant.chatgpt.site/`.
- Integridad pública: doce lecciones, treinta y seis ejercicios y veintiocho recursos del arranque offline comparados con la compilación local. Las doce unidades se verifican también mediante el cliente HTTP de Dart.
- Chrome con perfil temporal sobre la URL pública: descargar una unidad, confirmar una respuesta, recargar sin conexión, reanudar, quitar contenido sin perder el borrador, reconectar, completar las tres preguntas y conservar 10 XP tras recargar.
- Corregido un fallo específico del alojamiento que redirige `/index.html` a `/`. La prueba local reproduce la redirección para evitar regresiones.
- APK de depuración compilado y firma verificada: `dev.trama.trama`, versión `0.1.0+1`, mínimo API 24 y objetivo API 36.
- AAB de release compilado; pendiente de firma de subida. Archivos de entrega en `releases/`, excluidos de Git, con huellas SHA-256.

## Límites

No se han realizado pruebas Android en un dispositivo físico ni enviado la app a Play Console. La comprobación de alineación ELF de las bibliotecas de 64 bits no sustituye la ejecución en un dispositivo de páginas de 16 KB. No se ha configurado Supabase; las pruebas de sincronización usan un servicio simulado y PostgreSQL local. La revisión docente, privacidad y accesibilidad del piloto siguen pendientes.

El estado de GitHub Actions debe consultarse en el repositorio; validar los archivos YAML en local no equivale a haber superado una ejecución remota.
