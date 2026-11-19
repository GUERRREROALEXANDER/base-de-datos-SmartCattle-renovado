# `users`

Las personas que usan el sistema. La escribe y la lee **el backend**, que
registra cuentas, inicia sesión con JWT y aplica los roles
(`/api/auth/*`, `/api/users`). La primera cuenta registrada en una base vacía
es `owner`; las siguientes, `worker`.

| Columna | Tipo | NULL | Por qué |
| --- | --- | --- | --- |
| `id` | `BIGINT` identidad | no | |
| `email` | `TEXT` | no, `UNIQUE` | Con `CHECK (email = lower(email))`. Ver abajo. |
| `password_hash` | `TEXT` | no | Un hash **bcrypt**. Nunca la contraseña. |
| `full_name` | `TEXT` | no | |
| `role` | `TEXT` | no, `'worker'` | `owner` o `worker`. Indexada por `users_role_idx`. |
| `is_active` | `BOOLEAN` | no, `TRUE` | Se baja para retirar el acceso. |
| `created_at` | `TIMESTAMPTZ` | no, `now()` | |
| `updated_at` | `TIMESTAMPTZ` | no, `now()` | Lo refresca el trigger `users_updated_at_trg`, no la aplicación. |
| `last_login_at` | `TIMESTAMPTZ` | sí | Último inicio de sesión correcto. Llegó con la migración `0005`, no está en `schema.sql`: una base creada sólo con `schema.sql` no la tiene, y el backend no puede registrar a nadie. Por eso se instala con `install.sql`. |
| `preferences` | `JSONB` | no, `'{}'` | Preferencias de la interfaz (migración `0029`). `CHECK` de que es un objeto, para que nadie tenga que comprobar la forma antes de leer una clave. **Nunca secretos:** se devuelve tal cual al navegador. |

## El `CHECK` de minúsculas sostiene al `UNIQUE`

