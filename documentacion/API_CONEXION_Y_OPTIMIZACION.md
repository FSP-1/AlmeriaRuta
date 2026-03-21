# API Conexion App y Optimizacion

## Objetivo
Este documento explica como se conecta la app Flutter con la API local y que optimizaciones se aplicaron para mejorar estabilidad, rendimiento y evitar llamadas repetidas.

## 1. Conexion entre App y API

### Backend
- API Flask local (por defecto): `http://localhost:5000`
- Endpoints principales:
  - `GET /lines`
  - `GET /lines/{id}/stops`

### App Flutter
- Punto central de conexion: `lib/shared/services/bus_api_service.dart`
- La app usa `http` para consumir la API y transformar JSON a modelos:
  - `LineModel`
  - `StopModel`

### Flujo base de datos
1. La vista pide datos al ViewModel.
2. El ViewModel llama a `BusApiService`.
3. `BusApiService` consulta endpoint y parsea JSON.
4. Se actualiza estado con `notifyListeners()`.
5. La UI se reconstruye con datos nuevos.

## 2. Que se optimizo globalmente

## 2.1 Capa API central
Archivo: `lib/shared/services/bus_api_service.dart`

Se aplicaron estas mejoras:
- Cache en memoria de lineas y paradas.
- Deduplicacion de requests en vuelo (`_inFlight...`):
  - Si dos pantallas piden lo mismo al mismo tiempo, se reutiliza la misma `Future`.
- Timeout de red para evitar esperas indefinidas.
- Retry corto para fallos transitorios de conexion.

Impacto:
- Menos tormenta de conexiones.
- Menos errores intermitentes tipo "Connection closed while receiving data".
- Menor latencia percibida en segundas aperturas.

## 2.2 Inicializacion del mapa (ciclo de vida)
Archivo: `lib/features/map/viewmodels/map_viewmodel.dart`

Se aplicaron guardas de ciclo de vida:
- No reinicializar todo el mapa cada vez que se entra.
- No volver a pedir GPS si ya existe `userLocation`.
- No relanzar `loadStops()` si ya hay datos o si ya esta cargando.

Impacto:
- Menos llamadas repetidas al backend.
- Menos reconstrucciones innecesarias.
- Entrada al mapa mas estable.

## 2.3 Carga de paradas mas eficiente
Archivo: `lib/features/map/viewmodels/map_viewmodel.dart`

Antes:
- Carga secuencial por linea (mas lenta).

Ahora:
- Carga batched en paralelo con `Future.wait(...)` para paradas por linea.
- Agregacion de paradas unicas con union de `lineIds`.

Impacto:
- Menor tiempo total de carga inicial de mapa.
- Menor sensacion de bloqueo al entrar.

## 2.4 Popup de parada en Lineas
Archivo: `lib/features/lines/views/lines_view.dart`

Mejora aplicada:
- El `Future` del popup se calcula una sola vez por apertura.
- Ya no se recomputa en cada rebuild del bottom sheet.

Impacto:
- Menos trabajo redundante de UI.
- Popup mas fluido y consistente.

## 2.5 Estado de lineas en Home y modulo Lineas
Archivos:
- `lib/features/home/viewmodels/home_viewmodel.dart`
- `lib/features/lines/viewmodels/lines_viewmodel.dart`

Mejora aplicada:
- Guardas para no recargar lineas si ya existen en memoria.
- `forceRefresh: true` solo en acciones explicitas de reintento.

Impacto:
- Se evita mostrar cargas innecesarias.
- Menos peticiones duplicadas a `GET /lines`.

## 3. Problemas reales que se mitigaron

- Multiples `GET /lines` seguidos por navegacion entre vistas.
- Error intermitente: `ClientException: Connection closed while receiving data`.
- Estado de filtros que se sobreescribia por cargas tardias.

## 4. Buenas practicas para mantener esta mejora

- Mantener `BusApiService` como unica puerta de acceso HTTP.
- No hacer llamadas HTTP directas desde vistas.
- Reusar cache y `inFlight` para recursos compartidos.
- Forzar refresh solo por accion de usuario (boton Reintentar/actualizar).
- Evitar `initialize()` repetidos sin guardas.

## 5. Checklist rapido de verificacion

- Home muestra lineas sin multiples `GET /lines` repetidos.
- Pantalla de Lineas no recarga en cada apertura inmediata.
- Mapa no vuelve a pedir todo si ya esta inicializado.
- Paradas se cargan en paralelo y aparecen con menor demora.
- Reintentar hace refresh explicito cuando se necesita.

---
Documento generado para dejar trazabilidad tecnica de la conexion API-app y la optimizacion aplicada en AlmeriaRuta.
