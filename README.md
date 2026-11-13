# Trama · Cuaderno de informática

[Demostración pública](https://trama-informatica.ireperezsant.chatgpt.site/) · [Despliegue y CI](docs/Despliegue.md) · [Preparación de Google Play](docs/google-play/Preparacion.md)

Aplicación Flutter en español con tres rutas con doce microlecciones originales, 36 ejercicios y un simulador de caché. Funciona sin cuenta. Las respuestas confirmadas, la selección de materias y las sesiones terminadas se guardan en este dispositivo. Cada lección cuenta una sola vez para los XP, aunque se repita.

## Probarla en este Mac

Abre **Abrir Trama.command** en Finder. Sirve la compilación web incluida en `build/web` en el puerto local 8783. Usa el mismo navegador y dirección para recuperar el progreso. Para cerrar el servidor que abre el lanzador, pulsa Control+C en esa ventana.

1. Pulsa **Elegir mis materias** y selecciona una o varias.
2. Puedes usar **Diagnóstico opcional** para obtener una recomendación o **Ver las 4 lecciones** para elegir libremente. Abre una lección y comprueba dos respuestas. Recarga y pulsa **Continuar donde lo dejaste**. La última respuesta guarda el resultado automáticamente.
3. En **Mi progreso** aparecen los aciertos de la última sesión. Para experimentar con la caché, abre Arquitectura de Computadores y prueba las lecturas A, A y B.
4. Al terminar, **Repasar hoy** muestra cuándo corresponde resolver una variante sin ayuda. Puedes usar **Ensayar una variante** antes de la fecha. En **Mi progreso** el recuerdo diferido se presenta por separado.
5. Abre **Unidades sin conexión** para descargar cualquiera de las nueve lecciones adicionales. Las tres primeras vienen incluidas. Cada descarga muestra su tamaño; quitarla conserva las respuestas y el historial.
6. Tras la primera carga y la instalación completa de los recursos web, se puede recargar en modo avión. El almacenamiento privado del navegador o borrar los datos del sitio puede eliminar el progreso local.

## Construir desde el código

Usa Flutter **3.47.9** y Python 3 para empaquetar el modo offline web.

```sh
flutter pub get --enforce-lockfile
dart analyze lib tool test
flutter test --no-pub
flutter run -d chrome
bash tool/web.sh
python3 -m http.server 8783 --directory build/web --bind 127.0.0.1
```

El modo offline de arranque se prepara con el script de distribución. En Android con el SDK configurado se puede ejecutar `flutter build apk --debug`. En macOS con Xcode completo, `flutter build ios --simulator --debug`. La configuración de CI está en `.github/workflows/build.yml`. Los identificadores de aplicación y la firma de distribución necesitan configuración del propietario antes de publicar.

Para firmar Android, configura en el entorno protegido `TRAMA_UPLOAD_KEYSTORE` (ruta absoluta), `TRAMA_STORE_PASSWORD`, `TRAMA_KEY_ALIAS` y `TRAMA_KEY_PASSWORD`. Genera el paquete con `flutter build appbundle --release`. Sin esos secretos el build de release queda sin firma de distribución.

## Diseño y alcance

Abre `docs/Trama-diseno.html` para consultar las ocho fases. La versión Markdown en la misma carpeta contiene los diagramas Mermaid editables. El catálogo documenta 47 entradas del plan. El diagnóstico inicial y las doce lecciones funcionan en local. La ficha de revisión docente en `docs/revision-docente.html` recoge enunciados, soluciones, variantes y fuentes. La revisión externa queda pendiente. Las descargas selectivas están implementadas. La sincronización manual de sesiones terminadas y repasos está preparada y probada en local, pendiente de crear y conectar el proyecto de Supabase. La ejecución de Python libre continúa fuera del MVP.

## Verificación y presentación

La batería cubre reanudación, escrituras concurrentes o repetidas, sesiones de versiones anteriores y calendario de repaso. En la fase 8 de `docs/Trama-diseno.html` se detalla el objetivo de presentación del 16 de diciembre de 2026 y los criterios de aceptación. La verificación en dispositivos Android e iOS sigue pendiente.

## Incremento del 11 de noviembre: descargas y sincronización

Los paquetes se generan desde `lib/catalog_source.dart` con `dart tool/content.dart`. Las nueve lecciones adicionales se descargan a petición y se verifican por tamaño y SHA-256 antes de guardarse. Los paquetes no forman parte de la caché inicial de la web. Una instalación anterior conserva sus respuestas, pero debe descargar una vez las lecciones adicionales. Tras actualizar, cierra las pestañas de Trama y vuelve a abrir la misma dirección para que se active la nueva versión. No borres los datos del sitio.

La sincronización requiere una acción expresa y una cuenta del piloto. Envía sesiones terminadas y repasos; borradores, diagnósticos, materias elegidas y descargas permanecen en cada dispositivo. El cuaderno queda vinculado a una única cuenta; para otra persona se usa un perfil de navegador separado. No hay todavía registro público, recuperación de contraseña en la app ni sincronización automática. La contraseña no se guarda y el token solo dura mientras está abierta la pantalla de cuenta.

La guía `backend/README.md` recoge la activación pendiente. En Android e iOS también se debe definir `TRAMA_CONTENT_URL` con la dirección HTTPS que aloje la carpeta `content/`. La compilación de desarrollo sin esa dirección permite usar las tres lecciones incluidas.

Verificación reproducible: `flutter test --no-pub` y `python3 tool/check_backend.py` (requiere Docker e imagen `postgres:16-alpine`). Esta última prueba crea y elimina su propia base desechable. No sustituye la prueba de autenticación en Supabase ni las pruebas en dispositivos físicos.
