# 7.- Refactorización de widgets y limpieza de vistas

## Objetivo

Durante el desarrollo de AlmeriaRuta se detectaron varias vistas con demasiada responsabilidad acumulada. El objetivo de esta fase fue reducir el tamaño de las pantallas principales, separar lógica visual en widgets reutilizables y dejar cada pantalla más alineada con MVVM.

Las pantallas que más se beneficiaron fueron:

- [HomeView](../V2/almeriarutav02/lib/features/home/views/home_view.dart)
- [NotificationsView](../V2/almeriarutav02/lib/features/notifications/views/notifications_view.dart)
- [OptimizedMapView](../V2/almeriarutav02/lib/features/map/views/optimized_map_view.dart)

## Problemas detectados

Antes del refactor, varias vistas mezclaban demasiado contenido:

- UI principal, tarjetas y helpers en el mismo archivo.
- Bottom sheets muy grandes con lógica de selección, detalle y acciones.
- Widgets de estado, banners y formularios anidados sin separación clara.
- Código de mapa con filtros, capas, onboarding y acciones FAB en la misma vista.

Eso provocaba:

- archivos demasiado largos,
- mantenimiento más difícil,
- mayor riesgo de regresiones al tocar un detalle pequeño,
- y una vista menos clara para seguir el flujo de datos.

## Refactor realizado

### Home

La pantalla principal se dividió en piezas más pequeñas para que `HomeView` actuara como contenedor y no como componente monolítico.

Widgets y piezas extraídas:

- [home_section_card.dart](../V2/almeriarutav02/lib/features/home/views/widgets/home_section_card.dart)
- [home_info_card.dart](../V2/almeriarutav02/lib/features/home/views/widgets/home_info_card.dart)
- [home_accessibility_info_card.dart](../V2/almeriarutav02/lib/features/home/views/widgets/home_accessibility_info_card.dart)
- [coming_soon_dialog.dart](../V2/almeriarutav02/lib/features/home/views/widgets/coming_soon_dialog.dart)

Resultado:

- `HomeView` quedó centrada en composición y navegación.
- Las tarjetas se reutilizan con menos duplicación.
- El badge de notificaciones y el acceso a servicios se leen mejor desde la UI.

### Notificaciones

La zona de notificaciones se refactorizó para separar la bandeja remota, los ajustes de llegada y la recarga en componentes dedicados.

Piezas relevantes:

- [notifications_view.dart](../V2/almeriarutav02/lib/features/notifications/views/notifications_view.dart)
- [remote_inbox_section.dart](../V2/almeriarutav02/lib/features/notifications/views/widgets/remote_inbox_section.dart)
- [recharge_settings_card.dart](../V2/almeriarutav02/lib/features/notifications/views/widgets/recharge_settings_card.dart)
- [arrival_settings_card.dart](../V2/almeriarutav02/lib/features/notifications/views/widgets/arrival_settings_card.dart)
- [notifications_stop_picker.dart](../V2/almeriarutav02/lib/features/notifications/views/notifications_stop_picker.dart)

Resultado:

- la pantalla quedó dividida por bloques funcionales,
- la lógica de selección de parada se aisló,
- el flujo de configuración es más legible,
- y el scheduling de llegada se desacopló de la pantalla para poder funcionar en segundo plano.

### Mapa

El mapa fue uno de los módulos con más fragmentación aplicada. Se separaron controles, sheets, banners y turismo para reducir el tamaño de `OptimizedMapView`.

Piezas relevantes:

- [optimized_map_view.dart](../V2/almeriarutav02/lib/features/map/views/optimized_map_view.dart)
- [map_fab_actions.dart](../V2/almeriarutav02/lib/features/map/views/map_fab_actions.dart)
- [map_onboarding_flow.dart](../V2/almeriarutav02/lib/features/map/views/map_onboarding_flow.dart)
- [map_selection_sheets.dart](../V2/almeriarutav02/lib/features/map/widgets/map_selection_sheets.dart)
- [map_overlay_banners.dart](../V2/almeriarutav02/lib/features/map/widgets/map_overlay_banners.dart)
- [tourism_category_sheet.dart](../V2/almeriarutav02/lib/features/map/tourism/widgets/tourism_category_sheet.dart)
- [tourist_place_sheet.dart](../V2/almeriarutav02/lib/features/map/tourism/widgets/tourist_place_sheet.dart)
- [tourism_markers_layer.dart](../V2/almeriarutav02/lib/features/map/tourism/widgets/tourism_markers_layer.dart)

Resultado:

- la vista principal del mapa se quedó más declarativa,
- los diálogos y bottom sheets se movieron a widgets más pequeños,
- el modo turístico se aisló del flujo principal,
- y las acciones FAB quedaron separadas del render del mapa.

## Beneficios obtenidos

- Menos responsabilidad por archivo.
- Widgets más reutilizables.
- Código visual más fácil de leer y revisar.
- Menor acoplamiento entre UI y comportamiento.
- Mejor base para seguir corrigiendo bugs sin tocar grandes bloques.

## Relación con la arquitectura MVVM

Este refactor no cambió el patrón base, sino que lo reforzó:

- las vistas se limitan a composición visual,
- los ViewModels siguen concentrando el estado y la lógica,
- y los widgets extraídos ayudan a que la UI sea más mantenible sin mezclar reglas de negocio.

## Notas finales

La limpieza de widgets se aplicó principalmente en los módulos con más crecimiento funcional. En la práctica, esto permitió seguir evolucionando Home, Mapa y Notificaciones sin que cada cambio obligara a tocar pantallas demasiado grandes.
