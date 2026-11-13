# Activación de cuentas de Trama · pendiente

El propietario confirma el 11 de noviembre de 2026 que aún no hay un proyecto de Supabase. Esta entrega no crea infraestructura ni activa cuentas externas. La aplicación funciona como invitado.

## Preparar un entorno de pruebas

1. Crear un proyecto propiedad de la escuela o del responsable del piloto y acordar su región y condiciones antes de introducir datos del alumnado.
2. Aplicar `schema.sql` y después `rubrics.sql` desde el editor SQL del proyecto. Las claves de respuestas se regeneran con `dart tool/rubrics.dart`. La tabla privada no es accesible para clientes. Los intentos se insertan por la función autenticada, que valida las respuestas y fuerza el propietario de la sesión.
3. Crear dos usuarios de prueba en Auth, con correo y contraseña, desde la administración. No usar datos reales en esta fase. La aplicación no ofrece registro ni recuperación de contraseña todavía.
4. Compilar la web con la URL del proyecto y la clave pública (`publishable` o `anon`), nunca con una clave secreta o `service_role`:

```sh
bash tool/web.sh --dart-define=SUPABASE_URL=https://PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=CLAVE_PUBLICA
```

El nombre histórico `SUPABASE_ANON_KEY` admite también una clave publicable. La clave pública identifica a la aplicación; el token de Auth identifica a la persona. Las credenciales privadas de administración no se incorporan al código ni se comparten en el chat. Referencias: [claves de API](https://supabase.com/docs/guides/api/api-keys), [contraseña y Auth](https://supabase.com/docs/guides/auth/passwords), [funciones y permisos](https://supabase.com/docs/guides/database/functions).

5. En dos perfiles limpios del navegador, completar lecciones sin cuenta, abrir **Cuenta y sincronización**, aceptar la vinculación e iniciar sesión con el mismo usuario. Pulsar **Sincronizar ahora** en ambos y repetir en el primero. Comprobar que coinciden sesiones, XP únicos y próximos repasos.
6. Simular un corte después del envío y reintentar. Abrir un tercer perfil con el segundo usuario y comprobar que no recibe datos del primero. Cerrar la pantalla de cuenta y confirmar que se vuelve a pedir la contraseña.
7. Verificar exportación/restauración de una copia, borrado de una cuenta y su progreso remoto, accesibilidad, textos de privacidad y uso en dispositivos antes de autorizar un piloto real. Borrar una cuenta en Auth elimina sus eventos por la relación en cascada; los datos locales se gestionan por separado.

## Alcance de esta entrega

Se sincronizan sesiones finalizadas y repasos. Los borradores, diagnósticos, materias elegidas y descargas siguen siendo locales. Cada cuaderno local se vincula una vez a una cuenta; para otra persona se necesita otro perfil del navegador. No hay sesión persistente, registro público, recuperación de contraseña ni sincronización en segundo plano.

Los eventos llevan identificadores calculados a partir de su contenido; los reintentos no duplican evidencias. La aplicación conserva intentos concurrentes de repaso y evita contarlos como recuperaciones espaciadas adicionales si ocurren antes de la siguiente fecha. El piloto admite las rondas 0–127 por lección; ampliar y volver a generar las rúbricas antes de superar ese límite. Las versiones nuevas de contenido necesitan migraciones explícitas antes de cambiar el significado de una lección existente.

Las pruebas locales usan PostgreSQL 16 y una función mínima que simula la identidad autenticada. Cubren instalación, permisos, aislamiento de dos identidades, validación, reenvío, transacciones y paginación. **No validan el inicio de sesión real, la pasarela HTTP de Supabase ni dos dispositivos físicos.**
