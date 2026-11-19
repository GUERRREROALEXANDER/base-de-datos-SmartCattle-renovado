# `animals`

El registro de animales. La identificación individual por IA es una fase
futura: hoy esta tabla la llena el personal, no la visión.

| Columna | Tipo | NULL | Por qué |
| --- | --- | --- | --- |
| `tag` | `TEXT` | no, **PK** | El arete. Ver abajo. |
| `status` | `TEXT` | no, `'active'` | `active`, `inactive` o `lost`. Indexada por `animals_status_idx`. |
| `camera_id` | `BIGINT` → `cameras` | sí, `SET NULL` | Dónde se vio por última vez. Retirar una cámara no borra al animal. |
| `zone_id` | `BIGINT` → `zones` | sí, `SET NULL` | |
| `name` | `TEXT` | sí | Para que el personal reconozca de qué animal habla una alerta. |
| `last_detection` | `TIMESTAMPTZ` | sí | Lo escribe el servicio de IA. |
| `created_at` | `TIMESTAMPTZ` | no, `now()` | |
| `updated_at` | `TIMESTAMPTZ` | no, `now()` | Trigger `animals_updated_at_trg`. |

## El arete es la clave primaria

No hay `id` numérico. El arete es la identidad real del animal: la que está
físicamente en su oreja y la que usa el personal. Un segundo identificador
obligaría a traducir entre los dos en cada consulta y a decidir, en cada
