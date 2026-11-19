# Glosario

Los terminos que este repositorio usa con un significado preciso.

**arete** (*ear tag*) — El identificador fisico en la oreja del animal, y la
clave primaria de `animals`. No hay `id` numerico.

**zona segura** (*safe zone*) — El area de la que el ganado no deberia salir.
Un rectangulo en `zones` (`x_min..y_max`), opcionalmente un poligono
(`outline`). Coordenadas **de 0 a 1**, no pixeles.

**caja** (*box*, *bounding box*) — El rectangulo que la IA dibuja alrededor de
un objeto detectado: `events.box`, `[x1, y1, x2, y2]` **en pixeles**.
Normalizarla es dividir por `events.width` y `events.height`.

> La inconsistencia es real y vale la pena saberla: `zones` esta normalizado
> y `events.box` no. La zona se dibuja una vez y tiene que sobrevivir a un
> cambio de resolucion; la caja describe un cuadro concreto, del que se conoce
> la resolucion.

**evento** (*event*) — Una deteccion que disparo una regla. Hoy solo
`cattle_out_of_zone`. Fila en `events`.

**alerta** (*alert*) — El aviso que se manda **a raiz** de un evento. Fila en
`alerts`. Un evento puede producir varias: por correo y por WhatsApp son dos
filas.

**`detected_at`** — Cuando lo detecto la IA. Reloj del PC del predio.

