# `database/`

| Archivo | Que es |
| --- | --- |
| [`install.sql`](install.sql) | **Una base nueva se crea con esto.** Aplica el esquema y todas las migraciones, en orden. |
| [`schema.sql`](schema.sql) | Estado final de las **tablas**. No incluye indices, vistas ni comentarios posteriores. |
| [`migrations/`](migrations/) | Un archivo por cambio, numerado, idempotente. |
| [`tests/`](tests/) | Comprobaciones en SQL plano. Silencio es exito. |
| [`seed-dev.sql`](seed-dev.sql) | Camaras, zonas, personal y hato de desarrollo. |
| [`seed-dev-events.sql`](seed-dev-events.sql) | 40 eventos repartidos en 48 horas. Se puede repetir. |

Documentacion en [`../docs/`](../docs/): diccionario por tabla, runbooks,
diagrama, recetario de consultas, convenciones, seguridad y rendimiento.

## `schema.sql` solo no alcanza

Describe las tablas y nada mas. Los indices de claves ajenas, los indices
parciales, las tres vistas, la funcion de retencion, los comentarios de columna
y `zones.outline` llegaron despues, como migraciones.

Una base creada con `schema.sql` a secas tiene las tablas correctas y ninguna
de esas cosas, y la diferencia no se nota hasta que una consulta va lenta o
