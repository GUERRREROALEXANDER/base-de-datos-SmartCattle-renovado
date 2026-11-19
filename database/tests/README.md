# Comprobaciones del esquema

SQL plano, sin dependencias. Cada archivo comprueba una cosa y **falla
ruidosamente**: usa `ASSERT`, que aborta la transaccion con un mensaje en vez
de devolver una tabla que nadie lee.

**Silencio es exito.**

## Las dos clases de comprobacion

Importa la diferencia, porque las dos hacen falta:

- **Que existe.** Listan nombres: tablas, indices, constraints, vistas,
  funciones, comentarios. Detectan que un `ALTER` se llevo algo.
- **Que funciona.** Insertan una fila mala y exigen que la base la rechace.
  Detectan algo redefinido **conservando el nombre**, que es el caso que la
  primera clase no ve.

`03_check_constraints.sql` lista los `CHECK` por nombre;
`24_check_constraints_reject.sql` comprueba que rechazan. Una constraint se
puede reescribir para que no rechace nada y la primera sigue pasando.

## Los archivos

| Archivo | Que sostiene |
| --- | --- |
| `01_tables_and_columns.sql` | Las seis tablas; `animals.tag` sigue siendo la PK |
| `02_timestamps_are_utc.sql` | Ninguna fecha sin zona horaria |
| `03_check_constraints.sql` | Los `CHECK` existen, y los de enumerados rechazan |
| `04_lowercase_email_is_unique.sql` | Una direccion no se registra dos veces |
| `05_foreign_keys_are_indexed.sql` | Toda clave ajena tiene indice (la convencion, no una lista) |
| `06_idempotency_markers.sql` | La semilla no se duplica; los indices siguen |
| `07_event_idempotency.sql` | `ai_event_id` hace idempotente la ingesta |
| `08_cascade_and_set_null.sql` | El historico sobrevive; las alertas no |
| `09_updated_at_trigger.sql` | El trigger dispara, en las dos tablas |
| `10_partial_indexes.sql` | Los indices parciales **siguen siendo parciales** |
| `11_frame_bounds.sql` | La resolucion es positiva, y opcional |
