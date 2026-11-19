# Quien escribe que

Tres servicios comparten esta base. Ninguno es dueno del esquema, y eso es la
causa de casi toda la nulabilidad que hay aqui.

| Tabla | Escribe | Lee |
| --- | --- | --- |
| `cameras` | Backend (estado), personal (altas) | Backend, IA |
| `cameras.reported_status`, `last_report_at`, ... | **Solo** el backend, via `PUT /api/ai/cameras/{id}/status` | Backend |
| `zones` | Backend (`/api/zones`, lo que dibuja el personal) | Backend, IA (la zona segura) |
| `users` | Backend (`/api/auth/*`, `/api/users`) | Backend |
| `animals` | Backend (`/api/animals`); la IA reporta `last_detection` por el backend | Backend |
| `events` | Backend (`POST /api/ai/events`), y la IA puede escribir directo | Backend, tablero |
| `alerts` | Nadie todavia | Nadie todavia |
| `farms`, `lots`, `security_alerts`, `camera_occupancy`, `video_uploads` | **Solo** el backend | Backend |
| `video_analyses`, `video_analysis_alerts` | **Solo** el backend | Backend |
| `occupancy_samples`, `camera_status_changes`, `audit_log` | **Solo** el backend | Backend (`/api/reports/*`, `/api/audit-log`), y cualquiera por las vistas `v_*` |
| Catalogos (`lot_kinds`, `user_roles`, ...) | Nadie: los siembra la migracion `0015` del backend | Backend (`/api/catalogs`) |
| `cameras.account_id`, `display_name` | **Solo** el backend (`/api/cameras/saved`) | Backend, y el asistente por sus vistas |
| `detection_logs` | **Solo** el backend (`PUT /api/ai/cameras/{id}/detection-log`) | Backend (`/api/reports/*`), `daily_reports()` y el asistente |
| `users.preferences` | Nadie todavia | Nadie todavia |

## Lo que se deduce de la tabla anterior

### Casi todo admite `NULL` porque hay mas de un escritor

