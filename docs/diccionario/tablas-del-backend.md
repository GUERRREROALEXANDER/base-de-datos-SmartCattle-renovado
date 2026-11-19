# Tablas del backend

Las tablas que **crea y escribe sólo SmartCattle-Backend**, con sus propias
migraciones de Alembic. Viven en la misma base que las compartidas y las
referencian, así que se documentan aquí aunque no estén en `schema.sql`.

Al ser de un solo servicio pueden tener `NOT NULL` y `CHECK` estrictos sin
obligar a nadie más (ver [integraciones.md](../integraciones.md)). Toda clave
ajena tiene índice, igual que en las compartidas: la regla de la prueba
`05_foreign_keys_are_indexed` vale para la base entera, y el backend la
comprueba en su CI.

| Tabla | Para qué | Filas que crecen | Migración del backend |
| --- | --- | --- | --- |
| `farms` | Fincas de cada dueño | No | `0007` |
| `lots` | Potreros, establos y corrales de una finca | No | `0007` |
| `security_alerts` | Incidentes que el personal atiende y cierra | **Sí, con los eventos** | `0008` |
| `camera_occupancy` | Último conteo de ganado por cámara | No (una por cámara) | `0009` |
| `video_analyses` | Resumen de un video analizado | Lento | `0003` |
| `video_analysis_alerts` | Detecciones dentro de ese video | Lento | `0003` |
| `video_uploads` | Videos subidos y su cola de procesamiento | Lento | `0010` |
| `occupancy_samples` | Conteo de ganado por cámara, uno por minuto | **Sí, 1 440 por cámara al día** | `0016` |
| `camera_status_changes` | Cada cambio de estado de una cámara | Lento | `0016` |
| `audit_log` | Quién hizo qué | Con el uso | `0016` |
| `site_settings` | Ajustes del sitio entero, no de una cuenta: clave y valor en JSON. Hoy sólo `video_inicio`, el video de la portada | No (una fila por clave) | `0023` |
| 8 catálogos | Valores permitidos con etiqueta en inglés y español | No | `0015` |

Además, el backend agrega siete vistas de reportes (migración `0017`), descritas
al final.

## `farms`

| Columna | Tipo | NULL | Por qué |
| --- | --- | --- | --- |
| `id` | `BIGINT` identidad | no | |
| `owner_id` | `BIGINT` → `users` | no, `RESTRICT` | Una finca siempre tiene dueño. `RESTRICT` y no `CASCADE`: borrar una cuenta no puede llevarse fincas, lotes y su historial por efecto colateral. |
| `name` | `TEXT` | no | `UNIQUE (owner_id, name)`: un dueño no repite nombre; dos dueños sí pueden tener su «La Esperanza». |
| `location` | `TEXT` | sí | Texto libre: vereda, municipio. |
| `area_hectares` | `DOUBLE PRECISION` | sí | `CHECK (> 0)`. |
| `latitude`, `longitude` | `DOUBLE PRECISION` | sí | `CHECK` de rango, y `CHECK ((latitude IS NULL) = (longitude IS NULL))`: media coordenada no ubica nada. |
| `created_at`, `updated_at` | `TIMESTAMPTZ` | no | |

## `lots`

| Columna | Tipo | NULL | Por qué |
| --- | --- | --- | --- |
| `id` | `BIGINT` identidad | no | |
| `farm_id` | `BIGINT` → `farms` | no, `CASCADE` | Un lote no existe fuera de su finca. La API igual se niega a borrar una finca con lotes (`409`), así que el `CASCADE` sólo actúa si alguien borra a mano. |
| `name` | `TEXT` | no | `UNIQUE (farm_id, name)`. |
| `kind` | `TEXT` | no | `paddock`, `stable`, `pen` o `pasture`. La API pone `paddock` si no se dice: un lote se puede registrar sólo con el nombre. |
| `area_square_meters` | `DOUBLE PRECISION` | sí | `CHECK (> 0)`. Si hay medidas, sale de largo × ancho. |
| `length_meters`, `width_meters` | `DOUBLE PRECISION` | sí | Medidas de un lote rectangular (migración `0014`). `CHECK (> 0)` y `CHECK ((length_meters IS NULL) = (width_meters IS NULL))`: un solo lado no describe ninguna forma. Quien no sabe las medidas no manda nada. |
| `capacity` | `INTEGER` | sí | Cabezas que caben. `CHECK (>= 0)`. |
| `boundary` | `JSONB` | sí | Polígono en coordenadas geográficas. `NULL` de SQL, no `null` de JSON, cuando no hay. |
| `camera_id` | `BIGINT` → `cameras` | sí, `SET NULL` | La cámara que vigila el lote. Retirar la cámara no borra el lote. |
| `active` | `BOOLEAN` | no, `TRUE` | |
| `created_at`, `updated_at` | `TIMESTAMPTZ` | no | |

## `security_alerts`

No es `alerts`. `alerts` modela **notificaciones salientes** (su `channel` sólo
admite `email`, `whatsapp`, `telegram`, `sms`, `n8n`, y su `status` son estados
de envío). Un incidente que alguien reconoce y resuelve en el tablero es otro
registro. Cuando existan las notificaciones, van a referenciar una alerta de
seguridad, no a reemplazarla.

| Columna | Tipo | NULL | Por qué |
| --- | --- | --- | --- |
| `id` | `UUID` | no | |
| `event_id` | `UUID` → `events.ai_event_id` | sí, `SET NULL` | Apunta al id que puso la IA, no al `BIGINT`: es el que conoce la API. Sobrevive a la retención de `prune_events`. |
| `camera_id` | `BIGINT` → `cameras` | sí, `SET NULL` | |
| `alert_type` | `TEXT` | no | El tipo de evento que la disparó. |
| `severity` | `TEXT` | no | `low`, `medium` o `high`. |
| `status` | `TEXT` | no, `'open'` | `open` → `acknowledged` → `resolved`. El backend valida la transición con la fila bloqueada, así que dos personas no reconocen la misma alerta a la vez. |
| `message` | `VARCHAR(300)` | no | |
| `created_at` | `TIMESTAMPTZ` | no | |
| `acknowledged_at`, `acknowledged_by` | `TIMESTAMPTZ`, `BIGINT` → `users` | sí, `SET NULL` | Quién y cuándo la vio. Retirar a la persona no borra el registro. |
| `resolved_at`, `resolved_by` | `TIMESTAMPTZ`, `BIGINT` → `users` | sí, `SET NULL` | |

Índice `(status, created_at DESC)`: el tablero lista las abiertas, más nuevas
primero.

## `camera_occupancy`

Una fila por cámara, **sobrescrita** en cada reporte. No es histórico: la regla
de no guardar detecciones por cuadro sigue en pie, y esto es sólo el último
número.

| Columna | Tipo | NULL | Por qué |
| --- | --- | --- | --- |
| `camera_id` | `BIGINT` → `cameras` | no, PK, `CASCADE` | Sin cámara, el conteo no es de nada. |
| `cattle_inside`, `cattle_outside` | `INTEGER` | no | `CHECK (>= 0)`. |
| `observed_at` | `TIMESTAMPTZ` | no | Reloj de la IA. Un reporte observado antes que el guardado se ignora, para que un reintento atrasado no haga retroceder el tablero. |
| `received_at` | `TIMESTAMPTZ` | no | Reloj del backend. Es el que decide si el conteo está vigente, igual que `last_report_at` en `cameras`. |

## `video_analyses` y `video_analysis_alerts`

El resumen de un video analizado y las detecciones que contiene. Las escribe
el análisis simulado del navegador y el worker de YOLO por igual, con el mismo
formato.

`video_analysis_alerts.analysis_id` → `video_analyses` con `CASCADE`: una
detección no significa nada sin su video. `cls` es `cattle` o `person`, y
`time_sec` es la posición dentro del video, no una hora real.

## `video_uploads`

