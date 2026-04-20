# AlmeriaRuta V2 (Flutter)

Cliente móvil Flutter del proyecto AlmeriaRuta.

## Funcionalidades destacadas

- Mapa interactivo con paradas y filtros (cercanas, todas, favoritas, por línea)
- Modo turístico con categorías (playas, museos, monumentos, parques, compras, puerto, ocio)
- Ruta automática a lugares turísticos con OSRM
- Fallback a línea recta cuando falla el routing
- Distancia y tiempo estimado para rutas
- Sistema de tickets, validación y recarga
- Notificaciones locales:
	- Caducidad de mensual: aviso 3 días antes (configurable) + botón “Aceptar”
	- Llegada: aviso cuando falten X minutos a una parada, seleccionando parada y línea

## Arquitectura

Proyecto basado en MVVM con `Provider` y `ChangeNotifier`.

Rutas clave:

- `lib/features/map/` lógica y UI de mapa
- `lib/features/map/tourism/` módulo turístico
- `lib/features/home/` home y navegación principal
- `lib/features/notifications/` configuración y scheduling de notificaciones (MVVM)

## Ejecución

```bash
flutter pub get
flutter run
```

Notas:
- Emulador Android: el backend se consume desde `http://10.0.2.2:5000`.
- Móvil físico: cambia `apiBaseUrl` en `lib/core/constants/app_constants.dart` a la IP del PC.

## Backend local recomendado

Desde la raíz del repositorio:

```bash
cd backend
python almeria_busmaps_api.py
```

## Icono (launcher)

El icono se genera desde `assets/app_icon/app_icon.png`:

```bash
dart run flutter_launcher_icons
```

## Documentación completa

Consulta el README raíz del repositorio para detalles funcionales y de arquitectura.

Documentación puntual de los cambios recientes:

- [Cambios de turismo, rutas y caché](documentacion/CAMBIOS_TURISMO_RUTAS_Y_CACHE.md)
