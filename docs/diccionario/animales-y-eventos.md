# Como se relacionan `animals` y `events`

La relacion mas sutil del esquema, y la unica que todavia no se usa.

## Hoy: un evento no sabe de que animal es

`events.animal_tag` existe y esta **vacio en todas las filas**. El servicio de
IA detecta *una vaca*, no *esa vaca*: identifica la clase del objeto
(`detected_object = 'cow'`), no al individuo.

Por eso el tablero cuenta animales detectados y no puede decir cuales. La
identificacion individual es una fase futura.

## Cuando se use: la cascada importa

`events.animal_tag` apunta a `animals.tag`, que es una clave primaria
**natural**. Un arete se cae y se repone, asi que el valor cambia.

```sql
-- Reponer un arete
UPDATE animals SET tag = 'A-442' WHERE tag = 'A-441';
```

Con `ON UPDATE CASCADE`, los eventos de ese animal siguen el cambio. Sin ella,
el `UPDATE` fallaria -- la clave ajena lo rechazaria -- o, si alguien la
hubiera definido sin accion, dejaria el historico apuntando a un arete que no
existe.

Es el costo de una clave natural, y el motivo por el que esa clausula esta
