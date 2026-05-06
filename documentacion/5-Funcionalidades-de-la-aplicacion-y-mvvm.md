# 5 - Funcionalidades de la aplicación y MVVM

Este documento amplía el resumen funcional del proyecto con una explicación breve de cada funcionalidad principal y de cómo se reparte la responsabilidad entre View, ViewModel y servicios. Incluye también la capa compartida y el módulo turístico.

## 5.1 Visión general

AlmeriaRuta está organizada en módulos funcionales que comparten una base común: `Provider` + `ChangeNotifier`, servicios HTTP desacoplados y widgets reutilizables. La app se abre directamente en el mapa, pero el proyecto cubre navegación urbana, turismo, tickets, recargas, validación, notificaciones, auth y utilidades transversales.

### Capas comunes del proyecto

- **View**: presenta la interfaz y reacciona al estado.
- **ViewModel**: concentra el estado y la lógica de uso de cada módulo.
- **Service**: habla con backend, almacenamiento local o APIs externas.
- **Shared**: piezas transversales que usan varios módulos.

## 5.2 Home y navegación general

### Qué hace

La Home funciona como panel de acceso rápido a los módulos principales de la app. Su papel no es ejecutar lógica compleja, sino mostrar los accesos y el estado resumido de la aplicación.

### MVVM

- **View**: pinta tarjetas, botones y secciones informativas.
- **HomeViewModel**: expone los servicios principales y su estado visual.
- **Modelos**: `MobilityServiceModel` y estados relacionados.

### Funcionalidades incluidas

- Acceso a mapa, líneas, tickets, recargas, validación y ajustes.
- Bloques informativos de servicios urbanos.
- Entrada contextual según el estado de sesión.

## 5.3 Mapa interactivo

### Qué hace

Es el centro operativo de la app. Muestra paradas, rutas, filtros y capas turísticas sobre el mapa de Almería.

### MVVM

- **View**: `OptimizedMapView`, `MapWidget`, overlays y menús del mapa.
- **MapViewModel**: mantiene filtros, paradas, ruta activa, ubicación, favoritos y modo turístico.
- **Servicios**: carga de paradas, routing peatonal, geolocalización y persistencia de favoritos.

### Funcionalidades incluidas

- Mapa con paradas y marcadores dinámicos.
- Filtros por cercanía, favoritas, todas y por línea.
- Ubicación del usuario y centrado manual.
- Ficha de parada con detalle y acciones rápidas.
- Rutas peatonales con fallback si falla el cálculo.
- Modo navegación cuando hay una ruta activa.
- Menú lateral simple integrado en el mapa.

## 5.4 Líneas y paradas

### Qué hace

Permite consultar la red de autobuses, explorar cada línea y ver sus paradas y tiempos asociados.

### MVVM

- **View**: lista de líneas, detalle de línea y fichas de paradas.
- **LinesViewModel**: carga líneas, gestiona llegadas y prepara los datos para la UI.
- **Service**: consumo de la API local de buses.

### Funcionalidades incluidas

- Listado de líneas urbanas.
- Detalle de línea con paradas ordenadas.
- Consulta de llegadas por línea o parada.
- Acción para saltar al mapa con una parada seleccionada.

## 5.5 Turismo

### Qué hace

El módulo turístico muestra puntos de interés y permite trazar rutas a esos lugares desde la ubicación del usuario o desde una parada cercana.

### MVVM

- **View**: capas turísticas, fichas de POI y hojas de detalle.
- **TourismViewModel**: controla el modo turístico, la categoría activa y el estado de selección.
- **Servicios y utilidades**: planificador de rutas turísticas, datos de lugares y handlers de dirección.

### Funcionalidades incluidas

- Categorías turísticas como playas, museos, monumentos, parques, compras, puerto y ocio.
- Marcadores turísticos en el mapa.
- Hoja de detalle para cada punto de interés.
- Acción “Cómo llegar”.
- Ruta automática con estimación de distancia y tiempo.
- Fallback a línea recta si no hay ruta calculada.

## 5.6 Tickets

### Qué hace

Gestiona la compra de tickets y el flujo de uso posterior, incluyendo validación y consumo de viajes.

### MVVM

- **View**: compra, historial y pantallas de tickets.
- **TicketViewModel**: calcula importes, valida reglas del usuario y coordina el flujo de compra.
- **Services**: flujo de compra, API de tickets y validación.

### Funcionalidades incluidas

- Compra de tickets individuales y múltiples.
- Reglas distintas para usuario registrado y no registrado.
- Redirección al flujo de validación tras la compra.
- Historial de tickets y control de usos.

## 5.7 Validación de viajes

### Qué hace

Permite validar un viaje y controlar cuántos usos quedan, con trazabilidad del resultado.

### MVVM

- **View**: pantalla de validación y resultado.
- **ValidationViewModel**: controla estados, validaciones y usos restantes.
- **Service**: lógica de validación y persistencia del resultado.

### Funcionalidades incluidas

- Validación por QR.
- Registro del resultado de validación.
- Control de usos restantes en tickets múltiples.
- Bloqueo cuando no quedan viajes disponibles.

## 5.8 Recargas y tarjetas

### Qué hace

Gestiona la tarjeta virtual y los flujos de recarga o consulta de estado.

### MVVM

- **View**: tarjetas, avisos y acciones de recarga.
- **RechargeViewModel**: reglas de tarjeta, saldo, caducidad e historial.
- **Service**: operaciones de persistencia y comunicación con backend si aplica.

### Funcionalidades incluidas

- Visualización de tarjetas y estado.
- Recarga de saldo.
- Avisos de caducidad.
- Historial de operaciones.

## 5.9 Notificaciones

### Qué hace

Agrupa notificaciones locales y avisos remotos relacionados con la movilidad, la llegada de buses y la caducidad de títulos.

### MVVM

- **View**: configuración, lista de notificaciones y tarjetas informativas.
- **NotificationsViewModel**: organiza reglas, estado y sincronización de notificaciones.
- **Services**: scheduler local, servicio local de notificaciones, almacenamiento y API remota.

### Funcionalidades incluidas

- Avisos de llegada a una parada concreta.
- Avisos de caducidad de mensual.
- Bandeja remota para usuario registrado.
- Restauración automática al iniciar la app.

## 5.10 Autenticación y perfil

### Qué hace

Gestiona el acceso, el estado de sesión y la experiencia de usuario registrado.

### MVVM

- **View**: login, registro, perfil y recuperación.
- **AuthViewModel**: sesión, usuario actual, login/logout y control de permisos.
- **Service**: conexión con backend de autenticación.

### Funcionalidades incluidas

- Inicio de sesión.
- Registro de usuario.
- Cierre de sesión.
- Vista de perfil.
- Diferencias de funcionalidad entre usuario invitado y registrado.

## 5.11 Servicios compartidos

### Qué hace

`lib/shared/` contiene utilidades comunes que no pertenecen a una sola feature, pero que simplifican el mantenimiento y evitan duplicar lógica.

### MVVM / responsabilidades

- **Services**: `bus_api_service`, `line_search_utils`, `onboarding_service`, `ticket_validation_flow_service`, `line_models`.
- **Widgets**: `app_search_field`, `favorites_panel` y piezas reutilizables de UI.
- **Uso transversal**: mapa, líneas, tickets, onboarding y validación consumen esta capa.

### Funcionalidades incluidas

- Modelos comunes de líneas y paradas.
- Búsqueda compartida y normalización de consultas.
- Onboarding y flujos comunes de arranque.
- Utilidades de validación de tickets.
- Widgets reutilizables para búsquedas y paneles.

## 5.12 Resumen rápido por módulo

- **Home**: acceso rápido y resumen de la app.
- **Mapa**: exploración, filtros y navegación.
- **Líneas**: consulta de red, paradas y llegadas.
- **Turismo**: puntos de interés y rutas turísticas.
- **Tickets**: compra y control de usos.
- **Validación**: confirmación del viaje y trazabilidad.
- **Recargas**: tarjeta virtual, saldo y caducidad.
- **Notificaciones**: avisos locales y remotos.
- **Auth**: sesión, perfil y permisos.
- **Shared**: servicios y widgets transversales.

## 5.13 Relación con el resto de documentación

- Consulta la arquitectura general en el README raíz.
- Para el algoritmo de turismo en bus, revisa `ALGORITMO_RUTA_TURISTICA.md`.
- Para contratos de backend, revisa `API_CONTRATO_BACKEND.md`.
- Para cobertura y validación, revisa `8-Estrategia-y-cobertura-de-tests.md`.
