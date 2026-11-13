# Preparación para Google Play

Estado a 13 de noviembre de 2026: APK de depuración y AAB de release generados. El AAB todavía no tiene firma de subida. No se ha enviado la aplicación a Google Play ni se ha creado una cuenta de desarrollador.

## Artefactos y firma

- El APK de depuración sirve para instalar y probar en un teléfono. No es un paquete de publicación en Google Play.
- Para la tienda se genera un Android App Bundle (AAB) de release y se firma con la clave de subida del propietario. Play App Signing gestiona la firma de distribución.
- El identificador actual es `dev.trama.trama`. Revisarlo y confirmarlo antes de la primera subida: después no se cambia para mantener la misma aplicación.
- Versión inicial: `0.1.0`, código `1`. Cada nueva subida debe usar un código mayor al anterior.
- Se compila con objetivo Android API 36. Verificarlo en el APK/AAB generado; no basta con revisar el archivo de configuración.
- Los paquetes nativos deben superar la comprobación de páginas de memoria de 16 KB y probarse en un dispositivo o emulador compatible antes del envío.

## Compilar en local

Con Flutter 3.47.9, JDK 21 y Android SDK configurados:

```sh
flutter pub get --enforce-lockfile
flutter test --no-pub
flutter build apk --debug --dart-define=TRAMA_CONTENT_URL=https://trama-informatica.ireperezsant.chatgpt.site/
```

Para release, definir `TRAMA_UPLOAD_KEYSTORE`, `TRAMA_STORE_PASSWORD`, `TRAMA_KEY_ALIAS` y `TRAMA_KEY_PASSWORD` en el entorno protegido y ejecutar:

```sh
flutter build appbundle --release --build-number 2 --dart-define=TRAMA_CONTENT_URL=https://trama-informatica.ireperezsant.chatgpt.site/
```

La clave y su copia de seguridad pertenecen al responsable de la aplicación. No se suben al repositorio. Un AAB sin firma no está listo para Play. La pantalla de cuentas continúa desactivada mientras no se configure Supabase.

## GitHub Actions

El flujo «Preparar Android para Google Play» se ejecuta manualmente desde `main`, con un número de compilación. Usa el entorno `android-release`; configurar estos secretos en ese entorno:

- `TRAMA_KEYSTORE_BASE64`: contenido de la clave de subida codificado en base64.
- `TRAMA_STORE_PASSWORD`, `TRAMA_KEY_ALIAS`, `TRAMA_KEY_PASSWORD`.

El flujo falla si falta la firma. Genera APK y AAB firmados, calcula SHA-256, conserva los artefactos y borra la clave temporal del ejecutor. No publica automáticamente en Play Console. Puede definirse la variable `TRAMA_CONTENT_URL` para usar el alojamiento definitivo; debe terminar en `/`.

## Ficha propuesta

Nombre: **Trama · Informática**

Descripción breve:

> Aprende informática con microlecciones, ejercicios y práctica sin conexión.

Descripción:

> Trama es un cuaderno de estudio de informática en español. Elige entre Fundamentos de Programación, Redes de Computadores y Arquitectura de Computadores y avanza con prácticas cortas y explicaciones de cada respuesta.
>
> Esta primera versión ofrece doce microlecciones, treinta y seis ejercicios, un diagnóstico opcional para orientar el punto de partida y un simulador de caché. Puedes descargar las unidades adicionales para seguir estudiando sin conexión.
>
> Tu progreso se guarda en el dispositivo. Si interrumpes una práctica después de comprobar una respuesta, podrás continuar desde la siguiente pregunta. Los repasos ofrecen variantes para comprobar qué recuerdas con el paso del tiempo.
>
> Trama es un recurso complementario de aprendizaje. No sustituye una asignatura universitaria ni ofrece titulaciones o acreditaciones.

Categoría propuesta: Educación. La app actual no incluye anuncios ni compras.

## Pendiente antes de enviar

1. Cuenta verificada de Google Play Console y titularidad de la aplicación.
2. Confirmar identificador, clave de subida y copia de seguridad.
3. Revisión docente, pruebas Android en un dispositivo real y comprobación de tamaño de página de 16 KB.
4. Política de privacidad publicada con responsable y contacto reales, y formulario Data safety coherente con la versión exacta. Revisar los registros del alojamiento además de los datos locales.
5. Clasificación de contenido, público objetivo, correo de soporte y declaración de anuncios.
6. Icono de 512×512, gráfico promocional y capturas auténticas de la app Android. El icono de Trama está disponible en `web/icons/Icon-512.png`; no se presentan capturas web como si fueran Android.
7. Subir primero a pruebas internas y atender los requisitos de prueba que correspondan a la cuenta antes de solicitar producción.

Referencias oficiales consultadas el 11 de noviembre de 2026: [publicar Flutter en Android](https://docs.flutter.dev/deployment/android), [nivel objetivo de API](https://support.google.com/googleplay/android-developer/answer/11926878), [Android App Bundle](https://developer.android.com/guide/app-bundle).
