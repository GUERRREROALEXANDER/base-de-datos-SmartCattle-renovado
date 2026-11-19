# Acceso del asistente de IA

Migración `0033`. Esto es sólo la parte de la base: **el asistente todavía no existe**
en ningún servicio. Cuando exista, entra por aquí.

## La regla

**El backend consulta con SQL fijo y parámetros. El modelo nunca escribe SQL.** El
modelo elige una herramienta («informe de estos días»), y el backend corre la
consulta de esa herramienta con la cuenta de la sesión del usuario.

No es una preferencia. Con SQL libre, el propio modelo podría ejecutar
`RESET ROLE` o reescribir `app.current_account_id`, y las dos barreras de abajo
dejarían de servir: bastaría una frase maliciosa en una pregunta.

## Cómo se abre una consulta

```sql
BEGIN READ ONLY;
SET LOCAL ROLE smartcattle_assistant;
SELECT set_config('app.current_account_id', $1, true);  -- la cuenta, de la sesión
SELECT ... FROM v_assistant_events WHERE detected_at >= $2;
COMMIT;
```

`SET LOCAL` y el `true` de `set_config` duran sólo la transacción. Eso es lo que
permite usarlo con la conexión con pooler de Neon, donde la siguiente transacción
puede ser de otro usuario.

La cuenta sale del token, **nunca del texto de la pregunta**. Es el `account_id` de
quien pregunta: un trabajador usa el de su dueño.

## Lo que puede leer

| Objeto | Qué responde |
| --- | --- |
| `assistant_daily_reports(first_day, last_day, tz)` | El informe diario de la cuenta. Ver [diccionario/detections.md](diccionario/detections.md). |
| `v_assistant_detections` | Ganado por postura y personas, por cámara y minuto. |
