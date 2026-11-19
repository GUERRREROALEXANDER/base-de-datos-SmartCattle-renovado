# `events`

Lo que detectan las reglas. **La tabla que más crece**, y la que manda en el
diseño del esquema.

| Columna | Tipo | NULL | Por qué |
| --- | --- | --- | --- |
| `id` | `BIGINT` identidad | no | |
| `type` | `TEXT` | no | Hoy sólo `cattle_out_of_zone`. Texto libre, no enum: ver abajo. |
| `level` | `TEXT` | no, `'medium'` | `low`, `medium`, `high`. **Ningún servicio la escribe todavía.** |
| `source` | `TEXT` | no, `'camera'` | `camera` o `image`. |
| `camera_id` | `BIGINT` → `cameras` | sí, `SET NULL` | Retirar una cámara no borra su histórico. |
| `zone_id` | `BIGINT` → `zones` | sí, `SET NULL` | De qué zona salió. Sin usar aún. |
| `animal_tag` | `TEXT` → `animals` | sí, `SET NULL` + `ON UPDATE CASCADE` | El arete. Sin usar aún: la IA no identifica animales todavía. |
| `detected_object` | `TEXT` | sí | `cow`, etc. |
| `confidence` | `DOUBLE PRECISION` | sí | De 0 a 1, con `CHECK`. Era `REAL`; ver migración `0001`. |
| `box` | `JSONB` | sí | `[x1, y1, x2, y2]` **en píxeles**, no normalizado como `zones`. |
| `width`, `height` | `INTEGER` | sí | Resolución del cuadro, que es lo que da sentido a `box`. |
| `detected_at` | `TIMESTAMPTZ` | no, `now()` | Cuándo lo detectó la IA. |
| `received_at` | `TIMESTAMPTZ` | sí | Cuándo lo recibió el backend. |
| `ai_event_id` | `UUID` | sí, `UNIQUE` | Lo que hace idempotente la ingesta. |

## `detected_at` y `received_at` son dos relojes distintos

`detected_at` es el reloj del servicio de IA, que corre en el PC del predio.
`received_at` es el del backend. Se separan bajo demora de red, y **la
