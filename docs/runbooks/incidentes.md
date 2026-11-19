# Incidentes

Que mirar primero, por sintoma. El orden importa: cada paso descarta una
causa.

## El feed de eventos esta vacio o muestra menos de lo que hay

1. Cuantas filas hay y cuantas puede listar la API:

   ```sql
   SELECT count(*) AS total, (SELECT count(*) FROM v_api_events) AS listables
   FROM events;
   ```

2. Si la diferencia es grande, por que quedan fuera:

   ```sql
   SELECT count(*) FILTER (WHERE ai_event_id     IS NULL) AS sin_id_de_ia,
          count(*) FILTER (WHERE received_at     IS NULL) AS sin_received_at,
          count(*) FILTER (WHERE detected_object IS NULL) AS sin_objeto,
          count(*) FILTER (WHERE confidence      IS NULL) AS sin_confianza
   FROM events;
   ```

El esquema `Event` de la API exige esas cuatro columnas y aqui las cuatro
admiten `NULL`. Una fila incompleta **no** tumba la respuesta -- el backend
las filtra en SQL a proposito -- pero tampoco se lista. Si todas las filas
caen en una misma columna, el escritor que las produce esta mal configurado.

## Una camara aparece caida y el servicio de IA esta corriendo

```sql
SELECT name, reported_status, effective_status, silent_for, last_error
FROM v_camera_health WHERE name = 'camera-01';
```

- `effective_status = 'offline'` con `reported_status = 'online'`: la IA dejo
  de reportar. Mira `silent_for`. No es la base, es el enlace o el proceso.
- `effective_status = 'unknown'`: la fila existe pero nadie reporto nunca.
  Normal en una camara que solo nombro un evento.
- `last_error` con texto: la IA si reporto, y reporto un fallo.

