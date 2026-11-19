# Seguridad de los datos

Lo que esta tabla guarda y lo que pasa si se filtra.

## Lo que hay aqui que no debe salir

| Dato | Donde | Riesgo si se filtra |
| --- | --- | --- |
| `users.password_hash` | `users` | Con bcrypt, inservible por volumen. Con SHA sin salt, las cuentas se recuperan. |
| `users.email`, `full_name` | `users` | Datos personales del personal del predio. |
| `cameras.stream_url` | `cameras` | Acceso al video en vivo si la URL es publica. |
| La cadena de conexion | `.env`, Render | Acceso total a todo lo anterior. |

## Las reglas que ya estan puestas

### La contrasena nunca se guarda

`users.password_hash` guarda **bcrypt**. Es la decision mas importante de este
esquema y la mas facil de deshacer por comodidad.

SHA-256 se recorre a miles de millones de intentos por segundo en una GPU, asi
que un hash sin salt de una contrasena humana se revierte con una tabla.
bcrypt lleva salt por fila y un coste ajustable, y eso es lo que hace inviable
el ataque por volumen.

**Esta deuda esta abierta:** el frontend guarda hoy SHA-256 sin salt en
`localStorage` para su sesion de demostracion. Mientras la autenticacion real
no exista, esa es la que corre en el despliegue.

### `stream_url` no puede traer credenciales

El backend la rechaza si trae usuario y contrasena, porque la columna se
publica tal cual en `GET /api/cameras`. Una URL RTSP de la forma
