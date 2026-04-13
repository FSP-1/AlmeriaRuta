# Cambios - Refactor Tickets y Persistencia

Fecha: 2026-04-13

## Objetivo
- Reducir tamaño y acoplamiento en vistas de tickets.
- Reutilizar lógica en servicios compartidos.
- Mantener tickets locales tras cerrar la app.
- Simplificar UX en validación mostrando solo tickets con su mensaje.

## Cambios aplicados

### 1) Refactor de flujo de validación en servicio compartido
Archivo: `lib/shared/services/ticket_validation_flow_service.dart`

- Se centralizó lógica de:
  - Apertura de validación (`ValidateTripView`).
  - Resultado de uso y agotamiento del ticket.
  - Carga de notificaciones con tickets activos.
  - Conteo total de tickets no usados (local + remoto no duplicado).
  - Marcar notificación como leída y eliminar notificación agotada.

Resultado:
- Menos duplicación entre compra y validación.

### 2) Refactor de flujo de compra/regalo en servicio de feature
Archivo: `lib/features/tickets/services/ticket_purchase_flow_service.dart`

- Se extrajo lógica de:
  - Precondiciones para compra regalo.
  - Validación de destinatario.
  - Envío de notificación de compra regalo.
  - Sincronización post-validación del ticket local.

Resultado:
- `buy_ticket_view.dart` queda más limpio y centrado en UI.

### 3) Persistencia de tickets locales
Archivo: `lib/features/tickets/viewmodels/ticket_viewmodel.dart`

- Se añadió persistencia con `SharedPreferences`:
  - Clave: `local_tickets`.
  - `loadTickets()` para hidratar tickets al iniciar.
  - `_saveTickets()` para guardar cambios.
  - `persistTicketsState()` para persistir cuando cambian usos sin agotar.
- `useTicket()` pasó a `Future<void>` y persiste estado.

Resultado:
- Los tickets comprados localmente ya no se pierden al cerrar la app.

### 4) Extracción de componentes UI

#### 4.1 Compra de tickets
Archivo nuevo: `lib/features/tickets/widgets/buy_ticket_widgets.dart`

Widgets extraídos:
- `TicketTypeSelector`
- `GiftPurchaseSection`
- `QuantitySelector`
- `PaymentMethodsSection`
- `InsufficientBalanceBanner`
- `PurchaseErrorBanner`
- `TotalPriceCard`
- `BuyButton`

#### 4.2 Hub y validación
Archivo nuevo: `lib/features/tickets/widgets/tickets_hub_widgets.dart`

Widgets extraídos:
- `TicketsHubIntroCard`
- `HubActionCard`
- `TicketSelectionEmptyState`
- `TicketUseCard`

Archivo nuevo: `lib/features/tickets/widgets/ticket_selection_widgets.dart`

Widgets extraídos:
- `TicketSelectionList`

Resultado:
- Menos código inline en vistas grandes.
- Mayor reutilización y mantenibilidad.

### 5) Reorganización de estructura (widgets en raíz del feature)

- Movidos componentes desde `views/widgets` a:
  - `lib/features/tickets/widgets/buy_ticket_widgets.dart`
  - `lib/features/tickets/widgets/tickets_hub_widgets.dart`

Resultado:
- Estructura de feature más limpia.

### 6) Separación de vista de selección de ticket
Archivo nuevo: `lib/features/tickets/views/ticket_selection_view.dart`

- `TicketSelectionView` se extrajo fuera de `tickets_hub_view.dart`.

Resultado:
- `tickets_hub_view.dart` más corto y enfocado en navegación/hub.

### 7) Ajustes UX solicitados

- Se quitó el bloque/mensaje extra de "Billetes recibidos por notificación" en validación.
- Se mantienen las tarjetas de ticket con su mensaje de notificación.
- Badge de conteo de tickets no usados en card del hub (no dentro de la vista interna).

### 8) Limpieza de warnings

- Corregidos warnings por:
  - `invalid_use_of_visible_for_testing_member`
  - `use_build_context_synchronously`
  - `control_flow_in_finally`

## Archivos principales tocados

- `lib/features/tickets/views/buy_ticket_view.dart`
- `lib/features/tickets/views/tickets_hub_view.dart`
- `lib/features/tickets/views/ticket_selection_view.dart`
- `lib/features/tickets/viewmodels/ticket_viewmodel.dart`
- `lib/features/tickets/services/ticket_purchase_flow_service.dart`
- `lib/shared/services/ticket_validation_flow_service.dart`
- `lib/features/tickets/widgets/buy_ticket_widgets.dart`
- `lib/features/tickets/widgets/tickets_hub_widgets.dart`
- `lib/features/tickets/widgets/ticket_selection_widgets.dart`
- `test/features/tickets/viewmodels/ticket_viewmodel_test.dart`

## Validación

- `flutter analyze lib/features/tickets` -> sin issues.
- `flutter test` -> 109/109 tests OK.
