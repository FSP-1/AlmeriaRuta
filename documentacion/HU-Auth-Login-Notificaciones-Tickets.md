# AlmeriaRuta

## Historias de Usuario

**Version:** 1.0  
**Fecha:** 03/04/2026

## Hoja de control

| Campo | Valor |
|---|---|
| Organismo | Universidad de Almeria |
| Proyecto | AlmeriaRuta |
| Autor | Franco Sergio Pereyra |
| Version/Edicion | 1.0 |
| Fecha version | 03/04/2026 |
| Aprobado por |  |
| Fecha aprobacion | 03/04/2026 |

## Registro de cambios

| Version | Causa del cambio | Responsable del cambio | Fecha del cambio |
|---|---|---|---|
| 1.0 | Version inicial del documento HU de autenticacion, notificaciones y compra | Franco Sergio Pereyra | 03/04/2026 |

## Indice

1. HU 007: Registrarse en la aplicacion
   1. Criterios de aceptacion
   2. Caracteristicas de los campos
2. HU 008: Iniciar sesion en la aplicacion
   1. Criterios de aceptacion
   2. Caracteristicas de los campos
3. HU 009: Actualizar notificaciones de usuario
   1. Criterios de aceptacion
   2. Caracteristicas de los campos
4. HU 010: Comprar ticket (propio o para otro usuario)
   1. Criterios de aceptacion
   2. Caracteristicas de los campos

---

## HU 007: Registrarse en la aplicacion

Como usuario de la aplicacion, quiero poder crear una cuenta con mis datos basicos para guardar mi perfil, acceder a funciones avanzadas y gestionar mis compras de forma segura.

### Criterios de aceptacion

| Nº | Nombre | Descripcion |
|---|---|---|
| 1 | Acceso a registro | Como usuario, puedo abrir la pantalla de registro desde la app. |
| 2 | Datos obligatorios | Debo introducir nombre, email y contrasena para completar el registro. |
| 3 | Validacion email | El sistema valida el formato del correo antes de enviar. |
| 4 | Email unico | El sistema impide registrar dos cuentas con el mismo email. |
| 5 | Confirmacion | Tras registrarme correctamente, el sistema inicia sesion y redirige a Home. |
| 6 | Error controlado | Si hay error de validacion o servidor, se muestra mensaje claro al usuario. |

### Caracteristicas de los campos

| Nombre | Tipo | Longitud | Formato |
|---|---|---|---|
| ID usuario | Entero | 10 | Numerico autoincremental |
| Nombre | Cadena caracteres | 60 | Texto |
| Email | Cadena caracteres | 120 | usuario@dominio.com |
| Contrasena | Cadena caracteres | 8-128 | Texto seguro |
| Fecha registro | Cadena caracteres | 19 | aaaa-mm-dd hh:mm:ss |
| Tipo cuenta | Cadena caracteres | 20 | registrado / no_registrado |

---

## HU 008: Iniciar sesion en la aplicacion

Como usuario registrado de la aplicacion, quiero iniciar sesion con mi email y contrasena para acceder a mi cuenta, ver mis datos y usar funcionalidades exclusivas.

### Criterios de aceptacion

| Nº | Nombre | Descripcion |
|---|---|---|
| 1 | Acceso a login | Como usuario, puedo abrir la pantalla de inicio de sesion. |
| 2 | Credenciales | Debo introducir email y contrasena para autenticarme. |
| 3 | Token de sesion | Si el login es correcto, el sistema devuelve token de sesion valido. |
| 4 | Persistencia | La sesion queda guardada localmente para reutilizarla en siguientes accesos. |
| 5 | Redireccion | Tras iniciar sesion con exito, se navega automaticamente a Home. |
| 6 | Error de credenciales | Si email o contrasena no son validos, se muestra error sin cerrar la app. |

### Caracteristicas de los campos

| Nombre | Tipo | Longitud | Formato |
|---|---|---|---|
| Email | Cadena caracteres | 120 | usuario@dominio.com |
| Contrasena | Cadena caracteres | 8-128 | Texto seguro |
| Token | Cadena caracteres | 128-512 | JWT/Token firmado |
| Expiracion token | Cadena caracteres | 19 | aaaa-mm-dd hh:mm:ss |
| Estado sesion | Booleano | 1 | 0 = cerrada, 1 = activa |

---

## HU 009: Actualizar notificaciones de usuario

Como usuario de la aplicacion, quiero actualizar y gestionar mis notificaciones para consultar avisos de bus y, si estoy registrado, recibir notificaciones personales de tickets.

### Criterios de aceptacion

| Nº | Nombre | Descripcion |
|---|---|---|
| 1 | Carga de notificaciones | Al entrar en notificaciones, el sistema carga el listado actualizado. |
| 2 | Notificaciones de bus | Tanto registrado como no registrado pueden ver avisos de bus configurados. |
| 3 | Notificaciones personales | Solo usuario registrado ve notificaciones personales (ej. ticket recibido). |
| 4 | Marcar leida | Puedo marcar una notificacion como leida sin provocar error si ya estaba leida. |
| 5 | Eliminar notificacion | Puedo borrar una notificacion de la bandeja. |
| 6 | Ticket agotado | Si el ticket asociado se agota, la notificacion relacionada se elimina de la bandeja. |
| 7 | Contador no leidas | Home muestra badge con cantidad de notificaciones no leidas. |

### Caracteristicas de los campos

| Nombre | Tipo | Longitud | Formato |
|---|---|---|---|
| ID notificacion | Entero | 10 | Numerico autoincremental |
| ID usuario | Entero | 10 | Numerico |
| Tipo notificacion | Cadena caracteres | 30 | bus / ticket_gift / sistema |
| Titulo | Cadena caracteres | 120 | Texto |
| Mensaje | Cadena caracteres | 300 | Texto |
| Leida | Booleano | 1 | 0 = no leida, 1 = leida |
| Payload JSON | Cadena caracteres | Variable | JSON con metadatos |
| Fecha creacion | Cadena caracteres | 19 | aaaa-mm-dd hh:mm:ss |

---

## HU 010: Comprar ticket (propio o para otro usuario)

Como usuario de la aplicacion, quiero comprar tickets para mi o para otro usuario (si soy registrado), para gestionar desplazamientos propios y compartir viajes cuando sea necesario.

### Criterios de aceptacion

| Nº | Nombre | Descripcion |
|---|---|---|
| 1 | Acceso a compra | Como usuario, puedo entrar en la seccion de compra de tickets. |
| 2 | Compra propia | Puedo comprar ticket para mi cuenta y usarlo directamente. |
| 3 | Compra para tercero | Solo usuario registrado puede comprar ticket para otro usuario mediante su email. |
| 4 | Restriccion no registrado | Usuario no registrado no puede enviar tickets a terceros. |
| 5 | Metodos de pago | No registrado: Google Pay, Apple Pay, Visa. Registrado: ademas, saldo de cuenta. |
| 6 | Notificacion al receptor | Si la compra es para tercero, el receptor recibe notificacion con payload de ticket. |
| 7 | Redireccion a validar | En compra propia exitosa, la app redirige automaticamente a validar viaje. |
| 8 | Confirmacion y trazabilidad | El sistema confirma la compra y guarda el ticket para validacion posterior. |

### Caracteristicas de los campos

| Nombre | Tipo | Longitud | Formato |
|---|---|---|---|
| ID ticket | Cadena caracteres | 10-36 | Alfanumerico/UUID |
| Email receptor | Cadena caracteres | 120 | usuario@dominio.com |
| Cantidad | Entero | 2 | >= 1 |
| Metodo pago | Cadena caracteres | 20 | saldo / gpay / applepay / visa |
| Importe | Real | 6 | NNN.NN |
| Usos restantes | Entero | 2 | >= 0 |
| Estado ticket | Cadena caracteres | 15 | activo / agotado |
| Fecha compra | Cadena caracteres | 19 | aaaa-mm-dd hh:mm:ss |
