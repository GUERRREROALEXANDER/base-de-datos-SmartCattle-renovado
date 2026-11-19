# Rendimiento

Que indices hay, para que consulta existe cada uno, y como comprobar que
sirven.

## Los indices de `events`

`events` es la tabla que crece sin techo, y la que tiene mas indices. Cada uno
responde a una consulta concreta:

| Indice | Consulta | Origen |
| --- | --- | --- |
| `events_detected_at_idx` | La interfaz, ordenada por cuando paso | `schema.sql` |
| `events_type_detected_idx` | Por tipo, ordenada por fecha | `schema.sql` |
| `events_animal_tag_idx` | Los eventos de este animal | `schema.sql` |
| `events_camera_id_idx` | Los eventos de esta camara, y el `SET NULL` al retirarla | `0002` |
| `events_zone_id_idx` | Igual, por zona | `0002` |
| `events_received_at_idx` | El feed del backend, ordenado por recepcion | `0004` |
| `events_api_listable_idx` | Solo las filas que la API puede representar | `0009` |

Siete indices sobre la tabla de mayor escritura es mucho, y hay que decirlo:
**cada indice se paga en cada `INSERT`**. La ingesta de la IA es un `INSERT`
por deteccion, asi que esto no es gratis. La compensacion es que ninguna
consulta de lectura recorre la tabla completa.

## Los indices de los graficos y el informe diario

La cuenta vive en `cameras`, asi que una consulta de una cuenta en un rango pasa por
dos indices y no hace falta un `account_id` copiado en cada fila:

| Indice | Consulta | Origen |
| --- | --- | --- |
| `ix_cameras_account_id` | Las camaras de una cuenta | `0030` |
| `detection_logs_pkey` (`camera_id, minute`) | El rango de fechas de cada una | `0031` |
| `detection_logs_minute_idx` | La retencion y lo que mira todas las camaras | `0031` |
| `cameras_account_display_name_key` | Unicidad del nombre por cuenta | `0030` |

Medido con 3 cuentas, 60 camaras y 90 dias por minuto (7,9 millones de filas, 950
MB), en PostgreSQL 18 local, con una cuenta de 20 camaras:

| Consulta | Tiempo |
| --- | --- |
| `daily_reports()` de un dia | 54 ms |
| `daily_reports()` de 30 dias | 856 ms |
