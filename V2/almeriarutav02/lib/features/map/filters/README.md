# Map Filters Structure

Esta carpeta agrupa todo el sistema de filtros del mapa.

## Estructura

- `map_filter_menu_sheet.dart`: menú principal unificado de filtros.
- `shared/`: piezas reutilizables para opciones, encabezados o estados visuales.
- `bus/`: filtros de paradas y líneas de autobús.
- `tourism/`: filtros de puntos turísticos y categorías.
- `zones/`: filtros geográficos y zonas activas.

## Regla práctica

Cuando se añada una nueva capa al mapa, crea primero su carpeta dentro de `filters/` y luego agrega su sección al menú principal.

Ejemplos de futuras capas:
- `pedestrian/`
- `scooters/`
- `bike_lanes/`
