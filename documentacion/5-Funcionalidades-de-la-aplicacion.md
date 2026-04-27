# 5 - Funcionalidades de la aplicación (Resumen por funcionalidades)

Este documento describe, de forma compacta y sin código, las funcionalidades generales de la aplicación. Para cada funcionalidad principal se listan las subfuncionalidades más relevantes, la responsabilidad de los componentes y sugerencias de capturas.

> Nota: los nombres de componentes o rutas de fichero se muestran sólo como referencia; aquí se explica el comportamiento funcional.

## 5.1 Home (Pantalla principal)

### Descripción

- Punto de entrada y hub de navegación: presenta accesos rápidos a los módulos principales y el estado general de la aplicación.

### Descripción ampliada

- La pantalla Home actúa como la capa de descubrimiento y acceso rápido: no contiene lógica de negocio compleja, sino atajos que llevan al usuario a módulos concretos (Mapa, Líneas, Tickets, Validación, Recargas). Su responsabilidad es presentar el estado resumido de los servicios (por ejemplo, notificaciones urgentes o accesos directos a funciones recientes) y facilitar la elección del flujo siguiente.

La Home también contiene bloques informativos (por ejemplo, avisos municipales o accesos a favoritos) y manejadores de contexto (usuario logueado, modo turista). El objetivo de diseño es que la Home sea ligera, instantánea y orientada a la acción, delegando la carga y el procesamiento a sus respectivos ViewModels y servicios.

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

### Descripción ampliada

- El mapa es el centro operativo de la app: combina datos estáticos (paradas, líneas, POIs turísticos) con datos dinámicos (posición del usuario, llegadas estimadas, alertas). Debe ofrecer distintos niveles de interacción: exploración (buscar y filtrar), planificación (calcular rutas combinadas, ver detalles de paradas) y navegación (seguir una ruta en tiempo real).

El `MapViewModel` es responsable de reconciliar las distintas fuentes de datos y exponer solo el estado necesario para la UI (lista de marcadores filtrados, polilíneas segmentadas, estado de navegación). El servicio de routing (OSRM u otro) se usa únicamente para geometrías de calle y rutas a pie; las rutas en bus se construyen con la secuencia real de paradas para mantener fidelidad visual.

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

### Descripción ampliada

- El módulo de Líneas sirve para entender la topología de la red: cada línea expone su recorrido, número de paradas, horarios y frecuencias. Las paradas contienen metadatos (identificadores, coordenadas, líneas asociadas) y pueden consultarse en detalle para ver tiempos de llegada y opciones de conexión.

Los ViewModels de líneas implementan caching y deduplicación de llamadas al backend, presentando la información de forma reactiva a las vistas. Cuando el usuario selecciona 'ver en mapa', la app debe centrar la vista e indicar la parada seleccionada sin recalcular todo el dataset.

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

### Descripción ampliada

- El flujo de compra está pensado para ser sencillo y transaccional: seleccionar tipo/cantidad, revisar el precio, confirmar y generar un comprobante digital. El ViewModel valida entradas, calcula totales y delega el proceso de pago al servicio correspondiente. Tras la compra el ticket queda persistido en el historial y, si aplica, se emite una notificación de confirmación.

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

### Descripción ampliada

- La validación gestiona el ciclo de comprobación de un viaje (emisión y verificación de tokens o QR). Debe garantizar idempotencia (evitar validaciones duplicadas) y trazabilidad (registro del resultado con sello temporal). La UI muestra el resultado inmediato y posibles acciones correctivas (rechazar/reintentar).

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

### Descripción ampliada

- Gestiona instrumentos de pago/títulos (tarjeta virtual, perfiles de recarga). Las operaciones críticas (recarga, expiración) deben exponer confirmaciones claras y conservar un registro. Integrar notificaciones de saldo bajo y caducidad mejora la experiencia.

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

### Descripción ampliada

- Módulo transversal que permite búsqueda normalizada (autocompletado, normalización fonética mínima) y guarda accesos recurrentes en favoritos. Debe ofrecer interfaces reutilizables para múltiples vistas y un contrato claro para persistencia local y sincronización.

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

### Descripción ampliada

- Cobertura completa de notificaciones locales y remotas: configuración de reglas de llegada a paradas, recordatorios de recarga, y despliegue de bandeja remota. La lógica de scheduling se separa del UI y debe considerar permisos nativos, política de throttling y persistencia de estado.

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

### Descripción ampliada

- Contiene fuentes de información urbana complementaria: parkings, zona azul, estaciones de bicicletas, etc. Estos servicios son mayormente informativos y deben integrarse como capas en el mapa o listados, con posibles acciones (navegar, abrir pasarela de pago, ver disponibilidad) cuando la API lo soporte.

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

### Descripción ampliada

- Patrón técnico de integración: separar responsabilidades entre ViewModels (estado y orquestación), Servicios (comunicación HTTP / parsing) y utilidades (cache, deduplicación, manejo de errores). Para operaciones pesadas (routing, ensamblado de polilíneas) se recomienda offloading a isolates o procesos background y aplicar cache con TTL para reducir latencia y uso de red.

Incluye buenas prácticas: encapsular endpoints en servicios testables, centralizar política de reintento/timeout y exponer contratos de datos estables hacia las vistas.

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

---

He ampliado la descripción de cada bloque para que el documento sea más útil como referencia de producto y guía para desarrolladores. Actualizo la lista TODO a continuación.
