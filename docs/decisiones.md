# Registro de decisiones

Las decisiones que ya se tomaron, con lo que se descarto y por que. Sirve para
no volver a discutirlas, y para poder cambiarlas sabiendo que se rompe.

## 1. El arete es la clave primaria de `animals`

**Decidido.** No hay `id` numerico.

Alternativa descartada: `id BIGINT` mas `tag TEXT UNIQUE`. Habria evitado el
`ON UPDATE CASCADE`, pero obliga a traducir entre dos identificadores en cada
consulta y a decidir en cada pantalla cual mostrar. El arete es la identidad
real: la que esta en la oreja del animal y la que usa el personal.

**Que cuesta:** una clave natural cambia. Un arete se cae y se repone, y sin
`ON UPDATE CASCADE` en `events.animal_tag` el historico quedaria apuntando a
un arete inexistente.

## 2. Nombres en ingles

**Decidido.** Tablas y columnas en ingles, igual que la API REST.

Se llego con una migracion que renombro todo, incluidos los valores
guardados (`'activo'` a `'active'`, `'ganado_fuera_zona'` a
`'cattle_out_of_zone'`). **Rompio a los tres servicios a la vez.**

**No se repite.** Cualquier cambio de nombre a partir de aqui se coordina con
el equipo antes de aplicarse.

## 3. `animals` no lleva datos zootecnicos

**Decidido.** Sin raza, sexo ni fecha de nacimiento. Estuvieron en el
planteamiento inicial y se quitaron.

SmartCattle rastrea el ganado **por seguridad**: donde esta y si salio de su
zona. No gestiona el hato ni su valoracion. Esos datos no ayudan a localizar
un animal ni a detectar que se escapo.

`name` si se conserva: el personal reconoce de que animal habla una alerta.

## 4. Los enumerados son `TEXT` con `CHECK`

**Decidido.** No tipos `ENUM` de PostgreSQL.

`ALTER TYPE` para agregar un valor no se puede ejecutar dentro de una
transaccion junto con otros cambios. Un `CHECK` se reemplaza en el mismo
`ALTER TABLE` que el resto de la migracion.

**Excepcion deliberada:** `events.type` no lleva `CHECK`. Los tipos de evento
los define el servicio de IA, que evoluciona aparte. El costo es que quien lee
tiene que filtrar los tipos que no conoce, y el backend lo hace.

## 5. `ai_event_id UUID UNIQUE` para la idempotencia

**Decidido.** La idempotencia de la ingesta la resuelve la base, no la
aplicacion.

Alternativa descartada: que el backend compruebe antes de insertar. Entre la
