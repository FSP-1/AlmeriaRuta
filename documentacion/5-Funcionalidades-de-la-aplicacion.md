# 5 - Funcionalidades de la aplicación (Resumen por funcionalidades)

Este documento describe, de forma compacta y sin código, las funcionalidades generales de la aplicación. Para cada funcionalidad principal se listan las subfuncionalidades más relevantes, la responsabilidad de los componentes y sugerencias de capturas.

> Nota: los nombres de componentes o rutas de fichero se muestran sólo como referencia; aquí se explica el comportamiento funcional.

## 5.1 Home (Pantalla principal)

### Descripción

- Punto de entrada y hub de navegación: presenta accesos rápidos a los módulos principales y el estado general de la aplicación.

### Subfuncionalidades clave

- Tarjetas de acceso rápido a módulos (Líneas, Tickets, Validación, Favoritos).
- Visualización del estado de servicios (activo / informativo / coming soon).
- Acceso directo a notificaciones y ajustes.

### Responsabilidad de componentes

- Vista Home: presentación de tarjetas y acciones.
- ViewModel Home: prepara y expone el estado y la lista de servicios.
- Servicios de persistencia: almacenan preferencias y estado de onboarding.

### Capturas recomendadas

- Home general.
- Tarjeta de línea.
- Panel de notificaciones.

## 5.2 Mapa interactivo

### Descripción

- Mapa que muestra paradas, puntos turísticos y permite calcular rutas a pie o combinadas con bus.

### Subfuncionalidades clave

- Filtrado de paradas (por proximidad, por línea, favoritas).
- Geolocalización y centrado en el usuario.
- Ficha de parada / punto turístico con acción "Cómo llegar".
- Cálculo de rutas (caminar y combinar con bus) y modo navegación.

### Responsabilidad de componentes

- Vista Mapa: renderizar capas, marcadores y controles.
- MapViewModel: orquestar filtros, estado de ruta y llamadas a servicios de routing.
- Servicio de routing (OSRM o fallback): obtener geometrías y estimaciones.

### Capturas recomendadas

- Vista del mapa con filtros activos.
- Panel de filtros abierto.
- Ficha de parada o punto turístico.
- Vista de navegación con polilíneas separadas (caminar / bus / caminar).

## 5.3 Líneas y paradas

### Descripción

- Consulta y exploración de la red de autobuses: listado de líneas, detalle de cada línea y sus paradas.

### Subfuncionalidades clave

- Listado de líneas con información resumida (frecuencia, horario).
- Detalle de línea con listado y orden de paradas.
- Visualizar paradas en el mapa y abrir su ficha.
- Acciones rápidas: ver llegadas, saltar al mapa con parada preseleccionada.

### Responsabilidad de componentes

- Lines View: presenta la lista de líneas y facilita acciones.
- Lines ViewModel: carga, cachea y expone paradas y tiempos estimados de llegada.
- Servicio de datos de líneas: consulta al backend o fuente GTFS.

### Capturas recomendadas

- Listado de líneas.
- Detalle de línea con paradas.
- Pop-up / ficha de parada.

## 5.4 Compra de tickets

### Descripción

- Flujo para adquirir billetes o recargas digitales desde la app.

### Subfuncionalidades clave

- Selección de tipo de ticket y cantidad.
- Cálculo de precio y resumen de compra.
- Integración con métodos de pago (simulados o reales según entorno).
- Confirmación y generación del ticket digital (histórico).

### Responsabilidad de componentes

- Ticket View: interfaz de compra y confirmación.
- Ticket ViewModel: lógica de cálculo, persistencia y orquestación de pagos.

### Capturas recomendadas

- Pantalla de selección.
- Confirmación de compra.
- Ticket en el historial.

## 5.5 Validación de viajes

### Descripción

- Validación mediante QR/NFC y control de usos con trazabilidad.

### Subfuncionalidades clave

- Emisión de QR por viaje / ticket.
- Escaneo y verificación (válido / duplicado / inválido).
- Registro y actualización de usos.

### Responsabilidad de componentes

- Validation View: interfaz de escaneo y resultado.
- Validation ViewModel / Service: verifica y registra validaciones.

### Capturas recomendadas

- Interfaz de escaneo y resultado.

## 5.6 Recargas y gestión de tarjetas

### Descripción

- Gestión de tarjetas virtuales y recarga/renovación de títulos.

### Subfuncionalidades clave

- Listado de tarjetas y estado.
- Proceso de recarga y comprobante.
- Notificaciones de caducidad y saldo bajo.

### Responsabilidad de componentes

- Recharge View: UI de recarga.
- Recharge ViewModel / Service: reglas de recarga y persistencia.

### Capturas recomendadas

- Listado de tarjetas.
- Diálogo de recarga con comprobante.

## 5.7 Búsqueda y favoritos

### Descripción

- Módulo compartido para búsqueda normalizada y gestión de favoritos entre pantallas.

### Subfuncionalidades clave

- Campo de búsqueda reutilizable y normalización de texto.
- Panel de favoritos separado por tipo (paradas / líneas).
- Persistencia local de favoritos.

### Responsabilidad de componentes

- Widgets compartidos: campo de búsqueda y panel de favoritos.
- Favorites ViewModel: gestión y sincronización local.

### Capturas recomendadas

- Campo de búsqueda y panel de favoritos.

## 5.8 Notificaciones

### Descripción

- Gestión de notificaciones del usuario: subscribirse a avisos de llegada, alarmas de recarga y mensajes remotos.

### Subfuncionalidades clave

- Configuración de avisos de llegada por parada/ línea.
- Programación de recordatorios (recargas, caducidad de tarjeta).
- Bandeja remota y sincronización con backend.

### Responsabilidad de componentes

- Vistas y widgets: `lib/features/notifications/views`.
- Lógica y scheduler: `lib/features/notifications/viewmodels` y `lib/features/notifications/services` (p. ej. `notification_scheduler_service.dart`, `local_notification_service.dart`).

### Capturas recomendadas

- Pantalla de configuración de notificaciones.
- Ejemplo de bandeja remota y tarjeta de ajustes de llegada.

## 5.9 Servicios urbanos (informativos)

### Descripción

- Servicios de información urbana que no son rutas de transporte pero que complementan la experiencia: parkings, zona azul, estaciones de bikeshare, etc.

### Subfuncionalidades clave

- Listado y visualización de recursos urbanos por categoría.
- Indicadores de disponibilidad/estado (si aplica).
- Acciones rápidas: abrir detalle, ubicar en mapa o navegar a la pasarela de pago.

### Responsabilidad de componentes

- Modelado y catálogo: `lib/features/home/models/mobility_service_model.dart` y componentes en `lib/shared/widgets`.
- Vistas de detalle o paneles específicos (si existen dentro del proyecto) y adaptadores a APIs externas.

### Capturas recomendadas

- Vista resumen de servicios urbanos.
- Detalle de recurso (p. ej. parking o bike station) y su ubicación en mapa.

## 5.10 Conexión API y optimización

### Descripción

- Patrón de integración entre vistas, viewmodels y servicios que consumen el backend.

### Subfuncionalidades clave

- Servicios API para líneas, paradas y llegadas.
- Caché y deduplicación de llamadas.
- Offloading de tareas pesadas (routing) fuera del hilo UI.

### Responsabilidad de componentes

- Servicios API: encapsulan la comunicación con backend.
- ViewModels: orquestan y exponen estado.
- Workers / Jobs: tareas en background y caché.

### Capturas recomendadas

- Diagrama simplificado del flujo app → viewmodel → servicio → backend.

## 5.11 Plantilla de capturas y consejos de inclusión

Para cada funcionalidad y subfuncionalidad incluya:

- Nombre de la funcionalidad y la subfuncionalidad.
- Captura (ruta/nombre de archivo) y breve comentario explicativo.
- Contexto: dispositivo y resolución usada para la captura.

Ejemplo de entrada:

- Funcionalidad: Mapa interactivo
  - Subfuncionalidad: Vista de filtros
    - Captura: documentacion/screenshots/map_filters_panel.png
    - Comentario: muestra filtros por distancia y línea aplicada; útil para validar que el filtrado coincide con las paradas mostradas.
