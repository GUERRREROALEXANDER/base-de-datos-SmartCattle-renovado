# Convenciones

Reglas que ya sigue el esquema. Escritas para que el siguiente cambio no las
rompa sin darse cuenta.

## Nombres en ingles

Tablas y columnas en ingles, igual que la API REST, para que ningun servicio
traduzca entre los dos. Se llego aqui con una migracion que renombro todo
(`activo` paso a `active`, `ganado_fuera_zona` paso a `cattle_out_of_zone`), y
fue un cambio que rompio a todos los servicios a la vez. No se repite.

La documentacion va en espanol, porque la lee el equipo.

## Plural para las tablas, singular para las columnas

`cameras`, `events`, `alerts`. Una columna que apunta a otra tabla lleva el
singular mas `_id`: `camera_id`, `event_id`. La excepcion es `animal_tag`,
porque no apunta a un `id` sino al arete.

## Todo timestamp es TIMESTAMPTZ

Nunca `TIMESTAMP`. Lo comprueba `database/tests/02_timestamps_are_utc.sql`. Un
timestamp sin zona se lee con la del cliente, y aqui hay clientes en dos husos:
el PC del predio y Render.

## Los enumerados son TEXT con CHECK, no ENUM

`status`, `role`, `channel`, `level`, `source`. Un tipo `ENUM` de PostgreSQL
obliga a `ALTER TYPE` para agregar un valor, y eso no se puede hacer dentro de
una transaccion con otros cambios. Un `CHECK` se reemplaza en el mismo
`ALTER TABLE` que el resto de la migracion.

