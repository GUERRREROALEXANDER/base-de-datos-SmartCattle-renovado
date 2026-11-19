# `detection_logs`, `detections` y `daily_reports()`

Lo que vio la IA y el informe diario que sale de ahí. Migraciones `0031` y `0032`.

## `detection_logs`

Una fila por cámara y minuto: **el último reporte de ese minuto**. La escribe sólo
el backend (`PUT /api/ai/cameras/{id}/detection-log`), y es la misma tabla de su
migración `0019_detection_logs`. Cada lado la crea sólo si falta.

| Columna | Tipo | NULL | Por qué |
| --- | --- | --- | --- |
| `camera_id` | `BIGINT` → `cameras` | no, PK, `CASCADE` | La PK empieza por esta columna: sirve a la clave ajena y a los rangos por cámara. |
| `minute` | `TIMESTAMPTZ` | no, PK | El minuto, con los segundos en cero. |
| `cattle_lying`, `cattle_standing`, `cattle_walking` | `INTEGER` | no | Reses vistas en esa postura. `CHECK (>= 0)`. |
| `cattle_unknown` | `INTEGER` | no | Reses cuya postura no se pudo estimar. No es lo mismo que de pie. |
| `people` | `INTEGER` | no | Personas vistas. |
| `avg_confidence` | `DOUBLE PRECISION` | sí | Entre 0 y 1. |
| `observed_at` | `TIMESTAMPTZ` | no | Reloj de la IA. Un reporte atrasado no reescribe el minuto. |

Índice extra en `minute`, para la retención y lo que mira todas las cámaras.

**Por qué no una fila por detección.** La IA evalúa varias veces por segundo, y la
regla del proyecto es no guardar por cuadro. Lo que se pierde: no se puede
consultar una detección individual, ni seguir a un animal concreto.

**Crece** unos 64 MB por cámara al año, índices incluidos (medido: 7,9 millones de
filas en 950 MB). El plan gratuito de Neon da 1 GB, así que hay que podar:

```sql
SELECT prune_detection_logs(interval '90 days');
```

