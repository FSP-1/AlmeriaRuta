# AlmeriaRuta V2 (Flutter)

Cliente móvil Flutter del proyecto AlmeriaRuta.

## Funcionalidades destacadas

- Mapa interactivo con paradas y filtros (cercanas, todas, favoritas, por línea)
- Modo turístico con categorías (playas, museos, monumentos, parques, compras, puerto, ocio)
- Ruta automática a lugares turísticos con OSRM
- Fallback a línea recta cuando falla el routing
- Distancia y tiempo estimado para rutas
- Sistema de tickets, validación y recarga

## Arquitectura

Proyecto basado en MVVM con `Provider` y `ChangeNotifier`.

Rutas clave:

- `lib/features/map/` lógica y UI de mapa
- `lib/features/map/tourism/` módulo turístico
- `lib/features/home/` home y navegación principal

## Ejecución

```bash
flutter pub get
flutter run
```

## Backend local recomendado

Desde la raíz del repositorio:

```bash
cd backend
python almeria_busmaps_api.py
```

## Documentación completa

Consulta el README raíz del repositorio para detalles funcionales y de arquitectura.
