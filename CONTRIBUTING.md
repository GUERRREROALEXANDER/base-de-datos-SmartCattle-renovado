# Como cambiar esta base

Tres servicios leen y escriben aqui. Un cambio mal coordinado los rompe a la
vez, y ya paso una (ver [docs/decisiones.md](docs/decisiones.md), punto 2).

## Agregar una columna

1. Migracion nueva en `database/migrations/`, con el siguiente numero.
2. **Nulable**, o con `DEFAULT`. Una columna `NOT NULL` sin valor por defecto
   falla en una tabla con filas, y obliga a los demas escritores a inventar un
   dato que no tienen.
3. Idempotente: `ADD COLUMN IF NOT EXISTS`.
4. `COMMENT ON COLUMN` si el nombre y el tipo no alcanzan para usarla bien.
5. Agregarla a `database/install.sql`.
6. Comprobacion en `database/tests/` si hay una regla que valga la pena
   sostener.
7. Ficha en `docs/diccionario/`.

## Agregar un indice

En su propia migracion, con **la consulta que lo justifica escrita en el
comentario**. Un indice sin consulta conocida se paga en cada `INSERT` y no lo
usa nadie.

Si la consulta filtra, el indice va parcial: `WHERE status = 'pending'` pesa
lo que la cola, no lo que el historico.

## Quitar algo

