# AlmeriaRuta - Estructura MVVM (V2)

Este documento describe la estructura real del cliente Flutter en `V2/almeriarutav02/`.

## Estructura del Proyecto (Flutter)

```
lib/
├── core/
│   ├── constants/                 # Constantes globales (ej. apiBaseUrl)
│   └── theme/                     # Tema y colores
├── features/
│   ├── home/                      # Home + navegación a módulos
│   ├── lines/                     # Listado/detalle de líneas + favoritos
│   ├── map/                       # Mapa, filtros, favoritos y turismo
│   ├── notifications/             # Notificaciones (caducidad mensual + llegada)
│   ├── recharge/                  # Recargas / tarjetas
│   ├── tickets/                   # Compra de tickets
│   └── validation/                # Validación QR
└── shared/
	└── services/                  # Cliente API + modelos compartidos (LineModel/StopModel/etc.)
```

Cada feature sigue la jerarquía MVVM:

```
features/<feature>/
├── models/        # DTOs / settings / entidades
├── services/      # Integraciones (storage local, notificaciones, etc.)
├── viewmodels/    # ChangeNotifier (estado + lógica de presentación)
└── views/         # Widgets/pantallas
```

## Patrón MVVM

- **Model**: datos puros (p.ej. `NotificationSettings`, `LineModel`, `StopModel`).
- **ViewModel**: estado + acciones, con `ChangeNotifier` y `Provider`.
- **View**: UI; lee estado con `context.watch()` y dispara acciones con `context.read()`.

## Dependencias relevantes

- `provider`: estado MVVM (`ChangeNotifier`).
- `http`: API hacia el backend Flask.
- `shared_preferences`: persistencia local (favoritos y settings de notificaciones).
- `flutter_local_notifications` + `timezone`: scheduling de notificaciones locales.

## Añadir una feature nueva

1. Crear `lib/features/<feature>/{models,services,viewmodels,views}`.
2. Exponer la entrada desde `home/` (card/route).
3. Mantener el ViewModel sin lógica de UI (solo estado/acciones).