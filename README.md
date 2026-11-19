# SmartCattle — base de datos

PostgreSQL. El esquema compartido por los tres servicios de SmartCattle.

```
database/
  install.sql      <- una base nueva se crea con esto
  schema.sql         estado final de las tablas
  migrations/        un archivo por cambio, en orden, idempotentes
  tests/             comprobaciones en SQL plano
  seed-dev.sql       datos de desarrollo
docs/
  diccionario/       ficha por tabla: cada columna y por que es asi
  runbooks/          respaldo, restauracion, migraciones, Neon, incidentes
  erd.md             diagrama del modelo
  consultas.md       recetario, con la trampa de cada consulta
  convenciones.md    reglas que sigue el esquema
  seguridad.md       que guarda y que pasa si se filtra
  rendimiento.md     los indices y como comprobar que sirven
```

## Empezar

Base nueva:

```powershell
psql "$env:DATABASE_URL" -v ON_ERROR_STOP=1 -f database/install.sql
```

**No basta `schema.sql`.** Describe las tablas, pero los indices, las vistas,
los comentarios y la funcion de retencion llegaron en migraciones.
`install.sql` aplica las dos cosas en orden.

Base que ya tiene datos: ver
[docs/runbooks/aplicar-migraciones.md](docs/runbooks/aplicar-migraciones.md).
**Respalda primero.**

## Comprobar

```powershell
Get-ChildItem database/tests/*.sql | Sort-Object Name | ForEach-Object {
  psql "$env:DATABASE_URL" -v ON_ERROR_STOP=1 -f $_.FullName
}
```

Silencio es exito: usan `ASSERT`, que solo habla cuando algo esta mal.

CI corre esto en cada push contra un PostgreSQL 17 real, aplica todo **dos
