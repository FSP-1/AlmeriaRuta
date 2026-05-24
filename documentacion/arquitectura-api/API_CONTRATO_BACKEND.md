# Contrato API Backend - Planeador de Rutas Turísticas

## Endpoints


## API de Bus

### 1. `GET /lines`

**Propósito**: Obtener todas las líneas de autobús con paradas

**Respuesta**:

```json
[
  {
    "id": "L1",
    "name": "L1",
    "fullName": "Rambla, Celia Viñas - Rambla, Celia Viñas",
    "description": "Servicio urbano Almería",
    "totalStops": 15,
    "stops": [
      {
        "id": "478",
        "name": "Rambla, Celia Viñas",
        "lat": 36.8412,
        "lon": -2.4567,
        "zone": "Centro"
      },
      ...
    ]
  },
  ...
]
```

**Usado por**: `BusApiService.getLines()` → `MapViewModel` → `TouristBusRoutePlanner`

---

### 2. `GET /lines/<lineId>/stops`

**Propósito**: Obtener paradas para una línea específica

**Ejemplo**: `GET /lines/L1/stops`

**Respuesta**:

```json
[
  {
    "id": "478",
    "name": "Rambla, Celia Viñas",
    "lat": 36.8412,
    "lon": -2.4567,
    "zone": "Centro"
  },
  ...
]
```

**Usado por**: Detalles de línea en UI, selectores de parada

---

### 3. `GET /lines/<lineId>/arrivals`

**Propósito**: Obtener tiempos de llegada para todas las paradas de una línea

**Ejemplo**: `GET /lines/L2/arrivals`

**Respuesta**:

```json
{
  "arrivals": [
    { "stopId": "100", "minutes": 5 },
    { "stopId": "101", "minutes": 12 },
    { "stopId": "102", "minutes": 18 },
    ...
  ]
}
```

**Comportamiento**:

- Primera llamada para (lineId, stopId): asigna tiempo aleatorio 1–20 minutos, registra timestamp
- Llamadas posteriores: retorna `tiempo_inicial - minutos_transcurridos`
- A 0 minutos: reinicia al tiempo original, nuevo timestamp
- El tiempo **NUNCA cambia** después de asignación inicial para ese (línea, parada)

**Usado por**:

- `ArrivalObserverService` (vigila para disparo de notificación)
- Pantalla de tiempos de llegada en UI

---

### 4. `GET /stops/<stopId>/arrivals`

**Propósito**: Obtener tiempos de llegada para una parada (típicamente para notificación o vista de parada).

**Ejemplo**: `GET /stops/478/arrivals?limit=5`

**Respuesta**:

```json
[
  { "lineId": "L2", "minutes": 5 },
  { "lineId": "L18", "minutes": 12 }
]
```

**Query params**:

- `limit` (opcional): máximo de líneas a devolver (default 3)
- `lineId` (opcional): si se indica, devuelve solo esa línea (si pasa por la parada)

**Usado por**:

- `NotificationsViewModel` (preview/selección)
- `ArrivalObserverService` (optimizado: consulta solo la parada+lÍnea vigilada)

---

### 5. `GET /stops/<stopId>` 

**Propósito**: Obtener detalles para una parada específica

---

## API de Autenticacion

### 6. `POST /auth/register`

**Propósito**: Registrar un usuario nuevo con email, username, password y PIN de recuperacion.

**Usado por**: pantalla de registro y flujo de alta de usuario

### 7. `POST /auth/login`

**Propósito**: Iniciar sesion y devolver token JWT-like firmado junto con los datos de usuario.

**Usado por**: `AuthViewModel`

### 8. `POST /auth/guest`

**Propósito**: Crear una sesion de invitado.

**Usado por**: acceso rapido sin registro

### 9. `GET /auth/me`

**Propósito**: Obtener el perfil autenticado.

### 10. `PATCH /auth/me`

**Propósito**: Actualizar email y username del perfil.

### 11. `POST /auth/me/password`

**Propósito**: Cambiar la contraseña del usuario autenticado.

### 12. `POST /auth/recover/password`

**Propósito**: Recuperar la cuenta con email y PIN de recuperacion.

### 13. `GET /auth/notifications`

**Propósito**: Listar notificaciones del usuario, con filtro opcional `unreadOnly`.

### 14. `POST /auth/notifications/<notification_id>/read`

**Propósito**: Marcar una notificacion como leida.

### 15. `DELETE /auth/notifications/<notification_id>`

**Propósito**: Eliminar una notificacion.

### 16. `GET /auth/me/transport-profile`

**Propósito**: Obtener el perfil de tarjeta/transporte.

### 17. `PUT /auth/me/transport-profile`

**Propósito**: Actualizar el perfil de tarjeta/transporte.

### 18. `POST /auth/me/card-requests`

**Propósito**: Crear una solicitud de tarjeta.

### 19. `GET /auth/me/card-requests`

**Propósito**: Listar las solicitudes propias del usuario.

### 20. `GET /operario/notices`

**Propósito**: Listar avisos operativos visibles para el panel de operario.

### 21. `POST /operario/notices`

**Propósito**: Crear un aviso operario.

### 22. `POST /operario/notices/<notice_id>/deactivate`

**Propósito**: Desactivar un aviso.

### 23. `GET /operario/stops/disabled`

**Propósito**: Listar paradas deshabilitadas.

### 24. `POST /operario/stops/<stop_id>/disable`

**Propósito**: Deshabilitar una parada.

### 25. `POST /operario/stops/<stop_id>/enable`

**Propósito**: Habilitar una parada.

### 26. `GET /operario/card-requests`

**Propósito**: Listar solicitudes de tarjeta para operario.

### 27. `POST /operario/card-requests/<request_id>/decision`

**Propósito**: Aprobar o denegar una solicitud de tarjeta.

**Usado por**: `AuthViewModel`, `NoticesViewModel`, `OperarioViewModel` y las pantallas asociadas

**Implementacion**: [backend/almeria_auth_api.py](../../backend/almeria_auth_api.py), que arranca la API Flask en `0.0.0.0:5001`.

---

## Variantes de Ruta JSON 

### Archivo: `todas_las_lineas.json`

**Ubicación**: Carpeta backend

**Propósito**: Proporcionar secuencias reales de ruta de autobús (ida + vuelta)

**Estructura**:

```json
{
  "generado_en": "2026-05-02T07:53:51.916Z",
  "total_lineas": 16,
  "lineas": [
    {
      "linea": "L1",
      "rutas": [
        {
          "ruta": "RAMBLA, CELIA VIÑAS - RAMBLA, CELIA VIÑAS",
          "paradas": [
            { "id": "478", "nombre": "Rambla, Celia Viñas" },
            { "id": "420", "nombre": "Federico García Lorca, 9" },
            { "id": "406", "nombre": "Puerta del Mar" },
            ...
          ]
        },
        {
          "ruta": "VUELTA",
          "paradas": [
            ...
          ]
        }
      ]
    },
    ...
  ]
}
```

**Integración**:

- Convertido a: `Map<String, List<List<String>>>` (lineId → lista de secuencias de ruta)
- Usado por: `TouristBusRoutePlanner.selectLineSequence()`
- Fallback: Si no disponible, planeador usa `line.stops` de endpoint `/lines`

---

## Flujo de Carga de Datos

```
┌─────────────────────────────────────────────────────────┐
│ Inicio de App                                           │
└─────────────────────────────────────────────────────────┘
                    ↓
        ┌───────────────────────────┐
        │ MapViewModel.initialize()  │
        └───────────────────────────┘
                    ↓
        ┌───────────────────────────┐
        │ GET /lines                │
        └───────────────────────────┘
                    ↓
        ┌───────────────────────────────────────────┐
        │ _loadLineRouteVariants() [Actualmente: None] │
        └───────────────────────────────────────────┘
                    ↓
        ┌───────────────────────────┐
        │ Construye índice stopById  │
        │ Cachea líneas & paradas    │
        └───────────────────────────┘


┌─────────────────────────────────────────────────────────┐
│ Usuario Selecciona Lugar Turístico                      │
└─────────────────────────────────────────────────────────┘
                    ↓
        ┌───────────────────────────┐
        │ TouristBusRoutePlanner    │
        │  .buildPlan()             │
        └───────────────────────────┘
                    ↓
        ┌───────────────────────────┐
        │ selectLineSequence()       │
        │ (usa variantes JSON o     │
        │  fallback a line.stops)   │
        └───────────────────────────┘
                    ↓
        ┌───────────────────────────┐
        │ Dijkstra expansion        │
        └───────────────────────────┘
                    ↓
        ┌───────────────────────────┐
        │ TouristBusRoutePlan       │
        └───────────────────────────┘


┌─────────────────────────────────────────────────────────┐
│ Hoja de Ruta Mostrada                                   │
└─────────────────────────────────────────────────────────┘
                    ↓
        ┌───────────────────────────┐
        │ GET /lines/<L#>/arrivals  │
        │ (para notificaciones)     │
        └───────────────────────────┘
                    ↓
        ┌───────────────────────────┐
        │ ArrivalObserverService    │
        │ polling cada 120s         │
        └───────────────────────────┘
```

---

## Manejo de Errores

### 200 OK con Vacío

```json
{ "arrivals": [] }  // Sin llegadas (línea no circulando)
```

### 404 No Encontrado

```json
{ "error": "Parada no encontrada" }  // ID de parada no existe
```

### Error de Red

Capturador en `BusApiService` → muestra snackbar en UI → usuario reintentar manualmente

---

## Supuestos & Restricciones

1. **IDs de parada son consistentes** entre CSV (`Paradas.csv`) y JSON (`todas_las_lineas.json`)

   - Limpiados vía `_clean_id()`: convierte `404.0` → `"404"`
   - Si hay mismatch: imprime warning, parada saltada
2. **Precisión de coordenadas**: WGS84 (latitud/longitud), precisión ~metro
3. **IDs de línea** son únicos, no-vacíos (ej: `"L1"`, `"L18"`)
4. **Tiempos de llegada** son simulados:

   - Persiste por (línea, parada) en memoria del servidor
   - Se reinicia cuando app reinicia (no respaldado en BD)
   - Bueno para testing; reemplazar con GTFS real para producción
5. **Sin autenticación**: API es pública (asume red privada o capa auth upstream)

## Implementación Backend

**Archivos**:

- [backend/almeria_busmaps_api.py](../../backend/almeria_busmaps_api.py): API de rutas, lineas y llegadas, expuesta en `0.0.0.0:5000`.
- [backend/almeria_auth_api.py](../../backend/almeria_auth_api.py): API de autenticacion, perfil, notificaciones y operario, expuesta en `0.0.0.0:5001`.

**Clases Clave**:

- `PerfectBusClient`: Carga CSV + JSON, fusiona datos, maneja peticiones
- `_arrival_times_cache`: Dict global almacenando (línea, parada) → estado de tiempo

**Dependencias**:

- Flask, CORS
- pandas (carga de CSV)
- json (parsing de JSON)

**Iniciar Servidor**:

```bash
python almeria_busmaps_api.py
# Corre en http://0.0.0.0:5000

python almeria_auth_api.py
# Corre en http://0.0.0.0:5001
```

---

## Testear API

```bash
# Listar todas las líneas
curl http://localhost:5000/lines | jq '.[] | {id: .id, totalStops: .totalStops}'

# Obtener paradas para L1
curl http://localhost:5000/lines/L1/stops | jq '.[0:3]'

# Obtener llegadas para L2
curl http://localhost:5000/lines/L2/arrivals | jq '.arrivals[0:3]'
```

---

**Última Actualización**: 2026-05-04
