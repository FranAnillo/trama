# Despliegue y entrega continua

## Demostración pública

https://trama-informatica.ireperezsant.chatgpt.site/

Alojamiento Sites, proyecto registrado en `.openai/hosting.json`. El exportado para ese servicio se prepara en `work/public-site/`; el código Flutter se conserva en la raíz. La demo permite estudiar como invitado. Supabase sigue sin configurar.

El service worker normaliza las respuestas de navegación almacenadas que llegaron mediante una redirección. Esto permite recargar offline en alojamientos que redirigen `index.html` a `/`.

## Despliegue automático con GitHub

`.github/workflows/build.yml` define:

1. Análisis de código, pruebas unitarias y de interfaz con cobertura, y comprobación PostgreSQL de aislamiento y transacciones.
2. Compilación de la web, verificación SHA-256 de contenido y recorrido completo en Chrome con recarga offline.
3. Publicación en GitHub Pages desde `main`, únicamente si las comprobaciones anteriores pasan.
4. Verificación HTTP de que la web pública coincide con los artefactos de esa compilación.
5. APK de depuración descargable como artefacto, preparado para pruebas.

El flujo se ejecuta al subir cambios a `main`, en solicitudes de cambio y manualmente. Las solicitudes de cambio pasan pruebas, pero no publican. Los permisos de escritura de Pages y el token de identidad solo se conceden al trabajo de despliegue.

Al conectar el repositorio definitivo, activar **Settings → Pages → Source: GitHub Actions**. Usar la rama principal `main`. La web calcula el prefijo `/<nombre-del-repositorio>/`; para un dominio propio puede definirse `PAGES_BASE_PATH=/`.

La URL de GitHub Pages será el destino de los despliegues automáticos. La demo de Sites es un alojamiento separado y no cambia al ejecutar GitHub Actions. Si se desea mantener Sites como dominio definitivo, hará falta un mecanismo de despliegue de ese proveedor para CI; no se guardan sus credenciales temporales como secretos permanentes.

La variable `TRAMA_CONTENT_URL` permite elegir el origen HTTPS de los paquetes para Android. Hasta configurar un origen definitivo se usa la demo pública de Sites. La firma y los paquetes de Google Play están documentados en `google-play/Preparacion.md`.

## Verificación reproducible

```sh
flutter pub get --enforce-lockfile
dart analyze lib tool test
flutter test --no-pub --coverage
python3 tool/check_backend.py
bash tool/web.sh
python3 tool/check_integrity.py
python3 -m pip install -r tool/requirements-test.txt
python3 tool/browser_check.py
```

La prueba del navegador usa un perfil temporal, completa una lección descargada, verifica reanudación sin red, elimina y vuelve a descargar contenido y comprueba que se conservan el borrador y los XP. No utiliza perfiles del usuario.

Para probar una publicación existente:

```sh
python3 tool/check_integrity.py --url https://URL-PUBLICA/
python3 tool/browser_check.py --url https://URL-PUBLICA/
dart tool/check_remote_content.dart https://URL-PUBLICA/
```

La comprobación de integridad exige los artefactos locales de esa misma publicación. Las pruebas de navegador de esta entrega esperan la versión sin Supabase; adaptar la prueba de cuenta al activar ese servicio.
