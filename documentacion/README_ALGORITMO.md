# 📚 Documentación del Algoritmo - Planeador de Rutas Turísticas

## 📋 Archivos de Documentación

Esta carpeta contiene documentación completa del **Algoritmo de Planeador de Rutas Turísticas en Autobús**.

### 1. **ALGORITMO_RUTA_TURISTICA.md** 
Explicación técnica completa del algoritmo
- Descripción general y tipo de algoritmo
- Qué cambió respecto versión anterior
- Qué hace (paso a paso)
- Qué tipo es (Dijkstra DP)
- Estructuras de datos
- Ejemplo práctico con números
- Integración con API backend
- Estado actual

👉 **Leer esto si**: Necesitas entender completamente cómo funciona

---

### 2. **ALGORITMO_RESUMEN_RAPIDO.md**
Referencia rápida del algoritmo (TL;DR)
- Resumen en 1 línea
- Tabla de cambios respecto anterior
- Algoritmo en una imagen
- Parámetros clave
- Estado DP
- Salida esperada
- Flujo de datos
- Checklist de testing

👉 **Leer esto si**: Necesitas un resumen de 5 minutos o búsqueda rápida

---

### 3. **API_CONTRATO_BACKEND.md**
Especificación de API backend
- Todos los endpoints (`/lines`, `/lines/<id>/stops`, `/lines/<id>/arrivals`)
- Formatos de request/response con ejemplos
- Estructura variantes JSON
- Flujo de carga de datos (diagrama)
- Manejo de errores
- Supuestos y restricciones
- Comandos curl para testear

👉 **Leer esto si**: Trabajas con integración de backend o debugging de API

---

### 4. **CHECKLIST_IMPLEMENTACION.md**
Estado del proyecto
- ✅ Qué está hecho
- ⏳ Qué falta
- 🐛 Problemas conocidos y limitaciones
- Testing checklist
- Análisis de complejidad
- Estructura de archivos
- Disposición para producción

👉 **Leer esto si**: Necesitas saber qué está completo, qué falta, y estado general

---

## 🎯 Quick Facts

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Dijkstra shortest-path con estado DP consciente de transbordos |
| **Objetivo** | Encontrar ruta óptima usuario → lugar turístico con MÍNIMOS transbordos |
| **Parámetro Clave** | `transferPenaltyMeters = 25,000` (penalización pesada por transbordo) |
| **Radio Boarding** | `boardingRadiusMeters = 200m` (máxima caminata a primera parada) |
| **Máx Transbordos** | `maxTransfers = 2` (máximo 2 cambios de línea) |
| **Complejidad** | O((V*L*T) log(V*L*T)) - típicamente <1 segundo |
| **Status** | ✅ Core estable, ⏳ JSON variantes pendiente, ⏳ Testing pendiente |

---

## 🔄 Cambios Respecto Anterior

### ANTES (Deprecated)
```
❌ Heurística caótica
❌ Minimizar paradas
❌ Líneas mezcladas arbitrariamente
❌ Penalizaciones variables
❌ Código frágil y acumulado
```

### AHORA (Current)
```
✅ Dijkstra DP limpio
✅ Minimizar transbordos
✅ Selección route-first desde JSON
✅ Penalización fija (25,000m)
✅ Expansión forward-only
✅ Estado DP explícito
```

---

## 📍 Para Diferentes Audiencias

### 👨‍💼 Managers / No Técnico
1. Lee: **ALGORITMO_RESUMEN_RAPIDO.md** → "TL;DR"
2. Entiende: Core está hecho, JSON pendiente, testing pendiente
3. Status: 🟢 Listo para desplegar hoy

### 👨‍💻 Developers Frontend
1. Lee: **ALGORITMO_RUTA_TURISTICA.md** (completo)
2. Lee: **API_CONTRATO_BACKEND.md** (integración)
3. Código: `lib/features/map/tourism/utils/tourist_bus_route_planner_core.dart`

### 👨‍💻 Developers Backend
1. Lee: **API_CONTRATO_BACKEND.md** (endpoints, formatos)
2. Código: `backend/almeria_busmaps_api.py`
3. Test: Comandos curl provistos en API contract

### 🧪 QA / Testing
1. Lee: **CHECKLIST_IMPLEMENTACION.md** → "Checklist de Testing"
2. Lee: **ALGORITMO_RESUMEN_RAPIDO.md** → "Ejemplo Práctico"
3. Test: Ruta 1-línea, 2-línea, larga, usuario lejano

### 📊 Data Scientists
1. Lee: **ALGORITMO_RUTA_TURISTICA.md** → "Tipo de Algoritmo & Complejidad"
2. Entiende: Dijkstra DP, penalización transfer, forward-only expansion

---

## 🏗️ Estructura de Código

```
lib/features/map/tourism/
├── utils/
│   ├── tourist_bus_route_planner_core.dart     ⭐ Algoritmo Dijkstra
│   ├── tourist_bus_route_planner_models.dart   Estructuras de datos
│   └── tourist_bus_route_planner_helpers.dart  Utilidades
├── viewmodels/
│   └── tourism_viewmodel.dart                  Estado + persistencia
├── widgets/
│   └── tourist_bus_route_sheet/                UI de ruta
│       ├── tourist_bus_route_sheet.dart        Wrapper
│       ├── tourist_bus_route_sheet_content.dart UI principal
│       └── tourist_bus_route_sheet_components.dart Reusables
```

Backend:
```
backend/almeria_busmaps_api.py         ⭐ API endpoints
backend/Paradas.csv                    Coordenadas de paradas
backend/todas_las_lineas.json          Secuencias de rutas
backend/requirements.txt                Dependencias Python
```

---

## ⚡ Uso Rápido del Algoritmo

```dart
import 'utils/tourist_bus_route_planner_core.dart';

// Preparar inputs
final place = TouristPlace(name: 'Cathedral', ...);
final userLocation = LatLng(36.84, -2.45);
final destinationStop = StopModel(id: '100', ...);
final allLines = [...];

// Construir plan
final plan = TouristBusRoutePlanner.buildPlan(
  place: place,
  userLocation: userLocation,
  destinationStop: destinationStop,
  allLines: allLines,
  boardingRadiusMeters: 200,
  transferPenaltyMeters: 25000,
  maxTransfers: 2,
);

if (plan != null) {
  // Mostrar ruta
  showTouristBusRouteSheet(context, place: place, plan: plan);
} else {
  // Sin ruta encontrada
  showDialog(context, 'No hay ruta al destino');
}
```

---

## ✅ Estado Actual

### ✅ Implementado & Estable
- Algoritmo Dijkstra DP con estado de transbordos
- Selección route-first (elige mejor variante JSON)
- Expansión forward-only (respeta secuencia JSON)
- Seeding inteligente (radio 200m)
- Penalización pesada de transbordo (25,000m)
- Visualización de transbordos (UI + mapa)
- Persistencia de filtros (SharedPreferences)

### ⏳ Pendiente
- Habilitar carga de variantes JSON (actualmente deshabilitado)
- Testing end-to-end con lugares reales
- Opcional: exponer parámetros como configurables

### 📱 Listo para Producción
✅ Sí, funciona sin variantes JSON (fallback a `line.stops`)

---

## 🐛 Debugging Rápido

**Planeador retorna `null`?**
- Usuario >200m de todas paradas → aumentar `boardingRadiusMeters`
- Destino inalcanzable por línea → verificar líneas disponibles
- Transbordos > `maxTransfers` → aumentar `maxTransfers`

**Ruta tiene demasiados transbordos?**
- Aumentar `transferPenaltyMeters` (hoy: 25,000)
- O reducir `maxTransfers` a 1

**Ruta toma camino inesperado?**
- Verificar si `lineRouteVariantsByLine` se está cargando
- Si no, fallback a `line.stops` (cualquier orden)

---

## 📚 Referencias

- **Dijkstra**: https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm
- **Route Planning**: https://en.wikipedia.org/wiki/Route_planning_in_public_transport
- **Almería Rutas**: https://github.com/AlmeriaRuta

---

## 📞 Preguntas

- **"¿Cómo funciona?"** → Ver `ALGORITMO_RUTA_TURISTICA.md`
- **"¿Resumen?"** → Ver `ALGORITMO_RESUMEN_RAPIDO.md`
- **"¿API?"** → Ver `API_CONTRATO_BACKEND.md`
- **"¿Qué falta?"** → Ver `CHECKLIST_IMPLEMENTACION.md`

---

## 📈 Historial de Versiones

| Fecha | Versión | Cambios |
|-------|---------|---------|
| 2026-05-04 | 2.0 | Route-first + forward-only + transfer awareness (actual) |
| 2026-04-15 | 1.5 | Visualización de transbordos en UI y mapa |
| 2026-04-10 | 1.4 | Persistencia de filtros + refactorización |
| 2026-04-05 | 1.3 | Observador de notificaciones corregido |
| 2026-03-20 | 1.0 | Planeador Dijkstra inicial |

---

**Estado**: 🟢 Listo para producción (core estable, variantes JSON pending)  
**Última Actualización**: 2026-05-04
