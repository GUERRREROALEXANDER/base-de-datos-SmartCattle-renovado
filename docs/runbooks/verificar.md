# Comprobar una base sin tocarla

Para responder "esta bien esta base?" sin escribir nada. Util contra
produccion, donde las comprobaciones de `database/tests/` **no** se pueden
correr porque insertan filas.

## Esta completa

```sql
-- Las seis tablas
SELECT count(*) FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('alerts', 'animals', 'cameras', 'events', 'users', 'zones');
-- Esperado: 6

-- Las vistas de las migraciones
SELECT count(*) FROM information_schema.views
WHERE table_schema = 'public' AND table_name LIKE 'v_%';
-- Esperado: 3 (2 si faltan las columnas de estado del backend)

-- confidence se amplio
SELECT data_type FROM information_schema.columns
WHERE table_name = 'events' AND column_name = 'confidence';
-- Esperado: double precision
```

Si `confidence` dice `real`, la migracion `0001` no se aplico, y entonces
probablemente ninguna.

## Cuanto pesa y donde

```sql
SELECT relname,
       pg_size_pretty(pg_total_relation_size(relid)) AS total,
       pg_size_pretty(pg_indexes_size(relid))        AS indices,
       n_live_tup                                    AS filas_aprox
FROM pg_catalog.pg_statio_user_tables s
