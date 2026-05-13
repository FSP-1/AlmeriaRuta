# AlmeriaRuta

AlmeriaRuta es un proyecto de movilidad urbana para Almería compuesto por una aplicación móvil Flutter y un backend Flask. La app reúne mapa interactivo, líneas de autobús, turismo, tickets, recargas, validación y notificaciones locales; el backend aporta los datos de líneas, paradas y autenticación de usuarios.

## Resumen del proyecto

El repositorio está organizado en dos capas principales:

- `V2/almeriarutav02/`: cliente móvil Flutter.
- `backend/`: APIs Flask para transporte y autenticación.

La experiencia de usuario gira alrededor de un mapa principal con filtros de paradas, una capa turística, compra y validación de tickets, gestión de tarjeta de transporte y un sistema de notificaciones sin Firebase.

## Qué incluye

### Mapa y transporte

- Mapa interactivo centrado en Almería.
- Filtros de paradas por cercanía, favoritas, todas y por línea.
- Consulta de detalles de paradas y líneas.
- Ruta caminando con OSRM cuando está disponible.
- Fallback visual cuando el cálculo de ruta falla.
- Información de llegadas por línea y parada.

### Turismo

- Modo turístico integrado en el mapa.
- Categorías de puntos de interés como playas, museos, monumentos, parques, compras, puerto y ocio.
- Fichas de punto turístico con acceso a indicaciones.
- Planificador de rutas turísticas en bus con lógica propia.

### Tickets, recarga y validación

- Compra de tickets individuales y múltiples.
- Flujo de compra adaptado al tipo de usuario.
- Gestión de tarjeta de transporte y recargas.
- Validación de viajes con código QR.
- Historial y consumo de usos restantes.

### Notificaciones

- Avisos locales de llegada a parada.
- Avisos locales de caducidad de mensual.
- Bandeja de notificaciones remota para usuarios registrados.
- Rehidratación automática de programación al iniciar la app.

### Autenticación y perfil

- Registro e inicio de sesión contra backend propio.
- Gestión de sesión, perfil y cierre de sesión.
- Flujo de usuario registrado y no registrado con permisos distintos.

### Servicios compartidos

- Servicios comunes de la app en `V2/almeriarutav02/lib/shared/services/`.
- Utilidades reutilizables para modelos de líneas, búsqueda de líneas, onboarding y flujo de validación de tickets.
- Widgets compartidos en `V2/almeriarutav02/lib/shared/widgets/` para búsqueda y paneles reutilizables.

## Arquitectura

La app está implementada con MVVM y `Provider`/`ChangeNotifier`.

### Estructura de Flutter

```text
lib/
├── core/                     # Tema, constantes y configuración global
├── features/
│   ├── auth/                 # Login, registro, perfil y recuperación
│   ├── home/                 # Home de servicios de movilidad
│   ├── lines/                # Líneas, paradas y llegadas
│   ├── map/                  # Mapa, filtros, turismo y rutas
│   ├── notifications/        # Notificaciones locales y bandeja remota
│   ├── recharge/             # Tarjeta de transporte y recargas
│   ├── tickets/              # Compra y gestión de tickets
│   ├── validation/           # Validación de viajes
└── shared/                   # Servicios y widgets reutilizables
```

### Entrada principal

- [V2/almeriarutav02/lib/main.dart](V2/almeriarutav02/lib/main.dart) inicializa `Provider`, carga notificaciones restauradas y abre el mapa como pantalla principal.
- [V2/almeriarutav02/lib/features/map/views/optimized_map_view.dart](V2/almeriarutav02/lib/features/map/views/optimized_map_view.dart) es la vista principal del mapa.

### Piezas relevantes del mapa

- [V2/almeriarutav02/lib/features/map/views/map_widget.dart](V2/almeriarutav02/lib/features/map/views/map_widget.dart) encapsula el `FlutterMap`.
- [V2/almeriarutav02/lib/features/map/views/map_overlays_builder.dart](V2/almeriarutav02/lib/features/map/views/map_overlays_builder.dart) construye overlays y banners.
- [V2/almeriarutav02/lib/features/map/widgets/map_floating_buttons.dart](V2/almeriarutav02/lib/features/map/widgets/map_floating_buttons.dart) agrupa los botones flotantes.
- [V2/almeriarutav02/lib/features/map/widgets/map_simple_menu_overlay.dart](V2/almeriarutav02/lib/features/map/widgets/map_simple_menu_overlay.dart) contiene el menú lateral integrado.
- [V2/almeriarutav02/lib/features/map/filters/map_filter_menu_sheet.dart](V2/almeriarutav02/lib/features/map/filters/map_filter_menu_sheet.dart) concentra el menú de filtros.

## Backend

El backend vive en `backend/` y se compone de dos servicios Flask independientes:

### API de líneas y paradas

- Archivo: [backend/almeria_busmaps_api.py](backend/almeria_busmaps_api.py)
- Puerto por defecto: `5000`
- Función: expone líneas, paradas, llegadas y detalle de parada.
- Datos locales: `Paradas.csv`, `Paradas_de_Linea.csv` y `todas_las_lineas.json`.

Endpoints principales:

- `GET /lines`
- `GET /lines/<line_id>/stops`
- `GET /lines/<line_id>/arrivals`
- `GET /stops/<stop_id>`

### API de autenticación

- Archivo: [backend/almeria_auth_api.py](backend/almeria_auth_api.py)
- Puerto por defecto: `5001`
- Función: login, registro y sesión de usuarios con persistencia en MySQL.
- Usa `auth_mvc/` como capa de controlador, servicio y repositorio.

## Configuración de red

La app Flutter usa estas URLs base por defecto:

- API de buses: `http://10.0.2.2:5000`
- API de autenticación: `http://10.0.2.2:5001`

Estas direcciones funcionan desde el emulador Android. En dispositivo físico debes apuntar a la IP local de tu equipo.

## Requisitos

- Flutter 3.x o superior.
- Python 3.10+ para los backends.
- Dependencias de Flutter instaladas con `flutter pub get`.
- MySQL disponible para el backend de autenticación.

## Instalación y ejecución

### 1. Clonar y preparar el frontend

```bash
cd V2/almeriarutav02
flutter pub get
```

### 2. Arrancar el backend de buses

```bash
cd backend
pip install -r requirements.txt
python almeria_busmaps_api.py
```

### 3. Arrancar el backend de autenticación

```bash
cd backend
python almeria_auth_api.py
```

Si es la primera vez que lo ejecutas, el backend de autenticación inicializa el esquema de MySQL al arrancar.

### 4. Ejecutar la app Flutter

```bash
cd V2/almeriarutav02
flutter run
```

## Iconos de la app

El launcher icon se genera a partir de:

- `V2/almeriarutav02/assets/app_icon/app_icon.png`

Comando:

```bash
cd V2/almeriarutav02
dart run flutter_launcher_icons
```

## Documentación del repositorio

El índice principal de documentación está en:

- [documentacion/README.md](documentacion/README.md)

Documentos técnicos recomendados:

- [Funcionalidades y MVVM](documentacion/producto/5-Funcionalidades-de-la-aplicacion-y-mvvm.md)
- [Integración API y dependencias](documentacion/arquitectura-api/6-Integracion-API-y-Dependencias.md)
- [Estrategia y cobertura de tests](documentacion/calidad/8-Estrategia-y-cobertura-de-tests.md)
- [Contrato del backend](documentacion/arquitectura-api/API_CONTRATO_BACKEND.md)
- [OSRM, geocodificación y dependencias](documentacion/arquitectura-api/API_EXTRA_OSRM_GEOCODIFICACION_Y_DEPENDENCIAS.md)
- [Algoritmo de ruta turística](documentacion/mapa-turismo/ALGORITMO_RUTA_TURISTICA.md)

## Notas de desarrollo

- La app usa `Provider` y `ChangeNotifier` como base de estado.
- El mapa principal ya está modularizado en widgets, overlays, filtros y servicios.
- El backend de buses trabaja con ficheros locales para construir el catálogo de líneas y paradas.
- El backend de autenticación depende de `MySQL` y se inicia por separado.

## Estado actual

El proyecto está orientado a una versión funcional de movilidad urbana para Almería, con mapa, turismo, tickets, recargas, validación, auth y notificaciones ya integradas en la misma experiencia móvil. La suite Flutter actual se valida con `flutter test` desde `V2/almeriarutav02`.
