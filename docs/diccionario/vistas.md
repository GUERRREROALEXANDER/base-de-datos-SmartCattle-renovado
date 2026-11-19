# Vistas y funciones

No estan en `schema.sql`: las crean las migraciones `0011` a `0014` y `0020`.

## `v_api_events`

Los eventos que el esquema `Event` de la API puede representar, con el nombre
de la camara resuelto.

El filtro existe porque cuatro columnas que la API **exige** admiten `NULL`
aqui: `ai_event_id`, `received_at`, `detected_object` y `confidence`. Estaba
escrito tres veces -- feed, metricas, consultas a mano -- y las copias
divergieron.

Usar esta vista en vez de `events` es el habito correcto para cualquier
consulta que quiera "los eventos" como los entiende la aplicacion.

## `v_camera_health`

El estado **efectivo** de cada camara.

`reported_status` dice lo ultimo que dijo el servicio de IA, y una IA que se
cayo hace una hora sigue diciendo `online`. La vista aplica el mismo
vencimiento que el backend (60 s) y expone `silent_for`.

Tres valores de `effective_status`:

- `online` / `error`: lo que reporto, y el reporte esta fresco.
- `offline`: el reporte vencio, **sin importar** lo que diga la columna.
- `unknown`: nadie reporto nunca. **No es lo mismo que `offline`:** es una
  camara que existe como fila pero que nadie configuro, y eso pide una
  respuesta distinta que una averiada.

