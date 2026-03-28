# AlmeríaRuta

# Historias de Usuario

Versión: 1.1

Fecha: 28/03/2026

## Hoja de Control

| Versión | Fecha | Descripción del cambio |
|---|---|---|
| 1.0 | 22/01/2026 | Documento base de HU |
| 1.1 | 28/03/2026 | Incorporación HU de Favoritos y Notificaciones (V2) y adaptación a formato plantilla |

## Índice

1. HU 001: Gestión de favoritos (líneas y paradas)
2. HU 002: Gestión de notificaciones (mensual y llegada)

## 1 HU 001: Gestión de favoritos (líneas y paradas)

Como usuario, quiero marcar líneas y paradas como favoritas, para acceder rápidamente a ellas desde diferentes pantallas sin tener que buscarlas.

Prioridad: Alta

### 1.1 Criterios de aceptación

| Nº | Nombre | Descripción |
|---:|---|---|
| 1 | Añadir favorito | El usuario puede añadir una **línea** o una **parada** como favorito. |
| 2 | Eliminar favorito | El usuario puede eliminar una **línea** o una **parada** de favoritos. |
| 3 | Indicador visual | El estado (favorito / no favorito) se refleja inmediatamente en la UI. |
| 4 | Persistencia | Los favoritos se guardan localmente y permanecen tras cerrar y abrir la app. |
| 5 | Listado por tipo | Se puede listar favoritos separados por tipo: **líneas** y **paradas**. |
| 6 | Selección rápida | Se puede seleccionar un favorito para usarlo como entrada en flujos (p. ej., selección de parada en notificaciones). |

### 1.2 Características de los campos

| Nombre | Tipo | Longitud | Formato |
|---|---|---:|---|
| Favoritos Id | Cadena caracteres | 20 | Alfanumérico |
| Favoritos Nombre | Cadena caracteres | 10 | Alfanumérico |
| Favoritos Tipo | Enum | N/A | STOP/LINE |

## 2 HU 002: Gestión de notificaciones (mensual y llegada)

Como usuario, quiero configurar notificaciones (caducidad de mensual y aviso de llegada), para no olvidarme de renovar el abono y para minimizar tiempos de espera en paradas.

Prioridad: Alta

### 2.1 Criterios de aceptación

| Nº | Nombre | Descripción |
|---:|---|---|
| 1 | Activación | El usuario puede activar/desactivar cada tipo de notificación. |
| 2 | Caducidad mensual: fecha | El usuario puede seleccionar la fecha de caducidad de la mensual. |
| 3 | Caducidad mensual: hora | El usuario puede seleccionar la hora del aviso. |
| 4 | Caducidad mensual: cálculo | El aviso se programa para `caducidad - 3 días` a la hora indicada. |
| 5 | Caducidad mensual: no programar en pasado | Si la fecha/hora resultante ya pasó, no se programa ningún aviso. |
| 6 | Llegada: antelación | El usuario puede seleccionar la antelación del aviso: 1/3/5/10/15 minutos. |
| 7 | Llegada: selección de parada | El usuario puede seleccionar una parada objetivo (p. ej., desde Favoritos o navegando por líneas/paradas). |
| 8 | Llegada: selección de línea (si aplica) | Si la parada tiene varias líneas con tiempos distintos, el sistema permite elegir la línea para el aviso. |
| 9 | Llegada: limpiar selección | Existe un botón para limpiar la selección de parada/línea, dejando el aviso sin objetivo. |
| 10 | Confirmación de cambios | La configuración solo se guarda/aplica cuando el usuario pulsa **Aceptar**. |
| 11 | Degradación por red | Si falla la red al cargar líneas/paradas o llegadas, se informa al usuario y la app no se bloquea. |
| 12 | Aviso inmediato (caso límite) | Si el bus ya está dentro del margen (≤ X minutos), la app puede mostrar el aviso inmediatamente (útil para pruebas). |

### 2.2 Características de los campos

| Nombre | Tipo | Longitud | Formato |
|---|---|---:|---|
| Notificación Mensual Activa | Booleano | 1 | TRUE/FALSE |
| Mensual Fecha Caducidad | Fecha | 10 | yyyy-MM-dd |
| Mensual Hora Aviso | Hora | 5 | HH:mm |
| Notificación Llegada Activa | Booleano | 1 | TRUE/FALSE |
| Llegada Minutos Antelación | Entero | 2 | 1/3/5/10/15 |
| Llegada Parada Id | Cadena caracteres | 20 | Alfanumérico |
| Llegada Parada Nombre | Cadena caracteres | 10 | Alfanumérico |
| Llegada Línea Id | Cadena caracteres | 20 | Alfanumérico |
| Llegada Línea Nombre | Cadena caracteres | 10 | Alfanumérico |

