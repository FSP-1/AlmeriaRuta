# 5.- Funcionalidades de la aplicación

A continuación, se describen detalladamente cada una de las funcionalidades implementadas, explicando su objetivo y flujo de interacción con el usuario.

## 5.1.- Home (Pantalla principal)

### Objetivo

La pantalla Home actúa como punto de entrada a la aplicación y como menú central de acceso a todos los módulos. Su función es organizar y facilitar el acceso a los diferentes servicios de movilidad urbana.

### Funcionalidad

- Muestra tarjetas visuales de acceso rápido a cada módulo.
- Agrupa servicios principales y servicios informativos.
- Permite navegación directa hacia cada funcionalidad.
- Mantiene coherencia visual con la identidad municipal.

### Flujo de usuario

Ver Anexo I, HU de AlmeriaRuta.

(👉 Aquí iría la captura de la Home y posteriormente fragmentos de código de la View y ViewModel.)

### Fragmentos MVVM relevantes

**ViewModel**: [features/home/viewmodels/home_viewmodel.dart](../V2/almeriarutav02/lib/features/home/viewmodels/home_viewmodel.dart)

```dart
class HomeViewModel extends ChangeNotifier {
	final BusApiService _apiService = BusApiService();

	Future<void> loadLines({bool forceRefresh = false}) async {
		_isLoading = true;
		notifyListeners();
		_lines = await _apiService.getLines(forceRefresh: forceRefresh);
		_isLoading = false;
		notifyListeners();
	}

	List<MobilityServiceModel> get busServices => [
		MobilityServiceModel(id: 'lines', title: 'Líneas de Autobús', icon: Icons.route, color: AppTheme.primaryRed, status: ServiceStatus.active),
		MobilityServiceModel(id: 'tickets', title: 'Comprar Tickets', icon: Icons.credit_card, color: Colors.green, status: ServiceStatus.active),
	];
}
```

Este ViewModel concentra la carga de líneas y la definición de tarjetas de servicios mostradas en Home. De esta forma, la vista solo consume estado ya preparado.

**View**: [features/home/views/home_view.dart](../V2/almeriarutav02/lib/features/home/views/home_view.dart)

```dart
return ChangeNotifierProvider(
	create: (_) => HomeViewModel(),
	child: Consumer<HomeViewModel>(
		builder: (context, viewModel, child) {
			return Column(
				children: viewModel.busServices
						.map((service) => _buildSectionCard(context, service: service, onTap: () => _handleServiceTap(context, service)))
						.toList(),
			);
		},
	),
);
```

Este fragmento muestra que la vista principal consume el estado del `HomeViewModel` mediante `Provider`, generando dinámicamente las tarjetas de servicios sin lógica de negocio en la capa visual.

### HU relacionadas

- HU 0010: Gestión de notificaciones (mensual y llegada).

### Entradas principales

- Selección de módulo desde la pantalla inicial.
- Estado de sesión local y preferencias de usuario.

### Resultado esperado

- Navegación correcta al módulo seleccionado.
- Presentación consistente de servicios principales e informativos.

## 5.2.- Mapa interactivo

### Objetivo

Permitir al usuario localizar paradas y lugares de interés, consultar información relevante en tiempo real y obtener rutas peatonales hasta su destino.

### Funcionalidad

- Visualización de paradas en OpenStreetMap.
- Diferenciación de paradas multimodales.
- Geolocalización del usuario mediante GPS.
- Filtros disponibles: paradas cercanas, todas las paradas, favoritas y filtrado por línea.
- Buscador de líneas/paradas para acotar resultados.
- Cálculo de distancia y tiempo caminando.
- Integración con OSRM para rutas reales.
- Fallback con línea recta cuando falla el cálculo de ruta.
- Modo turístico con puntos de interés por categoría.
- Acción "Cómo llegar" desde el detalle del punto turístico.
- Controles para recalcular y cancelar la ruta activa.
- Vista enfocada en modo navegación.

### Flujo de usuario

Ver Anexo I, HU de AlmeriaRuta.

(👉 Aquí irán capturas del mapa y del modo navegación + código del MapViewModel.)

### Fragmentos MVVM relevantes

**ViewModel**: [features/map/viewmodels/map_viewmodel.dart](../V2/almeriarutav02/lib/features/map/viewmodels/map_viewmodel.dart)

```dart
Future<void> initialize() async {
	if (_initialized) return;
	await loadStops();
	await getCurrentLocation();
	await refreshFavoriteStops();
	_initialized = true;
}

Future<void> loadStops() async {
	final lines = await _apiService.getLines();
	final stopsByLine = await Future.wait(lines.map((line) async => MapEntry(line.id, await _apiService.getLineStops(line.id))));
	_lines = lines;
	_stops = uniqueStops.values.toList();
}

List<StopModel> _getFilteredStops() {
	if (_currentFilter.mode == FilterMode.line) {
		return _stops.where((stop) => stop.lineIds.contains(_currentFilter.lineId)).toList();
	}
	return _stops;
}
```

Este bloque resume la lógica central del mapa: inicialización única, carga de datos y filtrado por modo seleccionado. El cálculo de qué mostrar queda en el ViewModel.

**View**: [features/map/views/optimized_map_view.dart](../V2/almeriarutav02/lib/features/map/views/optimized_map_view.dart)

```dart
return Consumer2<MapViewModel, TourismViewModel>(
	builder: (context, mapViewModel, tourismViewModel, child) {
		return FlutterMap(
			mapController: _mapController,
			children: [
				MapFilterBar(mapViewModel: mapViewModel, onOpenLineSelector: () => _showLineFilterSelector(mapViewModel)),
			],
		);
	},
);
```

La vista del mapa se limita a renderizar capas y controles en función del estado expuesto por los ViewModels. La selección de filtros y modo turístico se resuelve sin mezclar lógica de datos en la UI.

### HU relacionadas

- HU 001: Consultar mapa de buses en tiempo real.
- HU 006: Filtrar lugares turísticos por categoría.
- HU 007: Filtrar paradas por zona geográfica.
- HU 008: Ruta automática a lugar turístico.
- HU 009: Gestión de favoritos (líneas y paradas).
- HU 0010: Gestión de notificaciones (mensual y llegada).

### Entradas principales

- Coordenadas del usuario obtenidas por GPS.
- Datos de líneas, paradas y relaciones desde API.
- Filtro activo seleccionado por el usuario.
- Categoría turística seleccionada (cuando aplica).

### Resultado esperado

- Visualización del mapa con marcadores filtrados.
- Cálculo de ruta y tiempo estimado hasta destino.
- Degradación controlada con ruta en línea recta si falla OSRM.

## 5.3.- Líneas y paradas

### Objetivo

Permitir al usuario consultar de forma clara las líneas urbanas y sus paradas asociadas para planificar el desplazamiento.

### Funcionalidad

- Listado de líneas urbanas disponibles con información resumida.
- Acceso al detalle de cada línea.
- Visualización de paradas asociadas a la línea seleccionada.
- Integración con el mapa para ubicar las paradas.
- Popup de parada con información relevante y acciones de consulta.

### Flujo de usuario

Ver Anexo I, HU de AlmeriaRuta.

### Fragmentos MVVM relevantes

**ViewModel**: [features/lines/viewmodels/lines_viewmodel.dart](../V2/almeriarutav02/lib/features/lines/viewmodels/lines_viewmodel.dart)

```dart
class LinesViewModel extends ChangeNotifier {
	final BusApiService _apiService = BusApiService();

	List<LineModel> _lines = [];
	final Map<String, List<StopModel>> _lineStopsCache = {};
	final Map<String, Map<String, int>> _arrivalsByLine = {};

	Future<void> loadLines({bool forceRefresh = false}) async {
		_ensureClockRunning();
		if (!forceRefresh && (_isLoading || _lines.isNotEmpty)) return;

		_isLoading = true;
		notifyListeners();
		_lines = await _apiService.getLines(forceRefresh: forceRefresh);
		_isLoading = false;
		notifyListeners();
	}

	Future<List<StopModel>> getLineStops(String lineId) async {
		final cached = _lineStopsCache[lineId];
		if (cached != null) return cached;
		final stops = await _apiService.getLineStops(lineId);
		_lineStopsCache[lineId] = stops;
		return stops;
	}

	Future<void> ensureLineArrivals(String lineId, {bool forceRefresh = false}) async {
		final arrivals = await _apiService.getLineArrivals(lineId, forceRefresh: forceRefresh);
		_arrivalsByLine[lineId] = arrivals;
		notifyListeners();
	}
}
```

`LinesViewModel` se encarga de cargar líneas, cachear paradas por línea y actualizar tiempos de llegada. Así se evita repetir llamadas y se mantiene la vista reactiva.

**View**: [features/lines/views/lines_view.dart](../V2/almeriarutav02/lib/features/lines/views/lines_view.dart)

```dart
return ChangeNotifierProvider(
	create: (_) => LinesViewModel()..loadLines(),
	child: Consumer<LinesViewModel>(
		builder: (context, viewModel, _) {
			return ListView.builder(
				itemCount: viewModel.lines.length,
				itemBuilder: (context, index) {
					final line = viewModel.lines[index];
					return LineCard(
						line: line,
						onTap: () => LineStopsBottomSheet.show(context, line, viewModel),
					);
				},
			);
		},
	),
);
```

La pantalla de líneas crea el `LinesViewModel`, dispara la carga inicial y pinta la lista desde `viewModel.lines`. La navegación al detalle se delega al `BottomSheet` de paradas.

**Modelo**: [shared/services/line_models.dart](../V2/almeriarutav02/lib/shared/services/line_models.dart)

```dart
class LineModel {
	final String id;
	final String name;
	final String fullName;
	final String color;
	final String frequency;
	final String firstService;
	final String lastService;
	final int totalStops;
	final List<StopModel> stops;
}

class StopModel {
	final String id;
	final String name;
	final double lat;
	final double lon;
	final String zone;
	final Set<String> lineIds;
}
```

Estos modelos representan el contrato de datos para líneas y paradas. Son la base que comparten API, ViewModels y vistas para mantener coherencia entre módulos.

**Detalle de paradas**: [features/lines/widgets/line_stops_bottom_sheet.dart](../V2/almeriarutav02/lib/features/lines/widgets/line_stops_bottom_sheet.dart)

```dart
final stops = await widget.viewModel.getLineStops(widget.line.id);
await widget.viewModel.ensureLineArrivals(widget.line.id);

final minutes = widget.viewModel.getArrivalMinutes(widget.line.id, stop.id);
final arrivalLabel = widget.viewModel.formatArrivalLabel(minutes);

onPressed: () {
	Navigator.pop(context);
	Navigator.pop(context);
	Navigator.of(context, rootNavigator: true).push(
		MaterialPageRoute(
			builder: (_) => OptimizedMapView(
				initialStop: stop,
				initialLineId: currentLine.id,
			),
		),
	);
}
```

Este bloque resume el flujo de detalle de parada: carga de tiempos de llegada por línea y salto directo al mapa con parada y línea preseleccionadas.

**Tarjeta de línea**: [features/lines/widgets/line_card.dart](../V2/almeriarutav02/lib/features/lines/widgets/line_card.dart)

```dart
return InkWell(
	onTap: onTap,
	child: Container(
		child: Row(
			children: [
				Text(line.name),
				Text('${line.firstService} - ${line.lastService}'),
				Text('Frecuencia: ${line.frequency}'),
			],
		),
	),
);
```

La tarjeta de línea encapsula la representación visual mínima de la línea (identificador, horario y frecuencia), separada de la lógica de obtención de datos.

### HU relacionadas

- HU 001: Consultar mapa de buses en tiempo real.
- HU 007: Filtrar paradas por zona geográfica.
- HU 009: Gestión de favoritos (líneas y paradas).

### Entradas principales

- Datos GTFS/API de líneas y paradas.
- Línea seleccionada por el usuario.
- Estado de filtros activos.

### Resultado esperado

- Consulta fluida de líneas y sus paradas.
- Acceso rápido desde línea a parada y viceversa.

## 5.4.- Comprar de tickets

### Objetivo

Permitir la adquisición digital de billetes sin necesidad de puntos físicos de venta.

### Funcionalidad

- Compra de ticket individual.
- Compra de múltiples viajes.
- Tarjeta virtual.
- Cálculo automático del precio.
- Simulación de métodos de pago: Apple Pay, Google Pay y Visa.
- Confirmación de compra.
- Generación de ticket digital.

### Flujo de usuario

Ver Anexo I, HU de AlmeriaRuta.

(👉 Aquí irán capturas y código del TicketViewModel.)

### Fragmentos MVVM relevantes

**ViewModel**: [features/tickets/viewmodels/ticket_viewmodel.dart](../V2/almeriarutav02/lib/features/tickets/viewmodels/ticket_viewmodel.dart)

```dart
class TicketViewModel extends ChangeNotifier {
	String _selectedType = 'Individual';
	int _quantity = 1;

	double get totalPrice => _selectedType == 'Individual' ? 1.05 : 1.05 * _quantity;

	Future<bool> buyTicket() async {
		_isLoading = true;
		notifyListeners();
		final ticket = TicketModel(id: _generateId(), type: _selectedType, quantity: _quantity, purchaseDate: DateTime.now(), amount: totalPrice, status: 'Activo');
		_tickets.add(ticket);
		_isLoading = false;
		notifyListeners();
		return true;
	}
}
```

Este ViewModel centraliza la selección de tipo, cantidad y cálculo de importe, además de la creación del ticket tras la compra.

**View**: [features/tickets/views/buy_ticket_view.dart](../V2/almeriarutav02/lib/features/tickets/views/buy_ticket_view.dart)

```dart
return ChangeNotifierProvider(
	create: (_) => TicketViewModel(),
	child: Consumer<TicketViewModel>(
		builder: (context, vm, child) {
			return ElevatedButton(
				onPressed: vm.isLoading ? null : () => _handlePurchase(context, vm),
				child: const Text('Comprar'),
			);
		},
	),
);
```

La vista de compra solo reacciona al estado de carga y delega la operación de compra al `TicketViewModel`, respetando la separación MVVM.

### HU relacionadas

- HU 002: Comprar ticket o tarjeta bus.

### Entradas principales

- Tipo de ticket seleccionado (individual o múltiple).
- Cantidad de viajes (si aplica).
- Método de pago seleccionado.

### Resultado esperado

- Compra confirmada con ticket digital generado.
- Actualización de estado para continuar con validación.

## 5.5.- Validación de viajes

### Objetivo

Permitir la validación digital del viaje mediante código QR, garantizando control y trazabilidad.

### Funcionalidad

- Generación de QR dinámico.
- Escaneo para validación.
- Control de viajes restantes.
- Registro de validaciones.
- Prevención de usos duplicados.
- Historial de viajes.

### Flujo de usuario

Ver Anexo I, HU de AlmeriaRuta.

(👉 Aquí irán capturas y código de validación.)

### Fragmentos MVVM relevantes

**ViewModel**: [features/validation/viewmodels/validation_viewmodel.dart](../V2/almeriarutav02/lib/features/validation/viewmodels/validation_viewmodel.dart)

```dart
class ValidationViewModel extends ChangeNotifier {
	Future<void> validate({required String ticketId, required String type}) async {
		_loading = true;
		notifyListeners();
		_result = await _service.validateTitle(ticketId: ticketId, type: type, remainingUses: _currentTicket!.remainingUses);
		if (_result!.isValid && _currentTicket!.remainingUses > 0) {
			_currentTicket!.remainingUses--;
		}
		_loading = false;
		notifyListeners();
	}
}
```

La validación del título y la actualización de usos restantes se gestionan aquí, manteniendo la lógica transaccional fuera de la vista.

**View**: [features/validation/views/validate_trip_view.dart](../V2/almeriarutav02/lib/features/validation/views/validate_trip_view.dart)

```dart
return ChangeNotifierProvider(
	create: (_) => ValidationViewModel()..setTicket(ticket),
	child: Consumer<ValidationViewModel>(
		builder: (_, vm, __) {
			return ElevatedButton.icon(
				onPressed: vm.loading ? null : () => vm.validate(ticketId: ticket.id, type: ticket.type),
				icon: const Icon(Icons.qr_code_scanner),
				label: const Text('Validar ahora'),
			);
		},
	),
);
```

La pantalla de validación inicializa el ticket activo en el ViewModel y dispara la validación desde la UI, sin acoplarse al servicio de validación.

### HU relacionadas

- HU 003: Validar ticket o tarjeta bus mediante NFC/QR.

### Entradas principales

- Ticket digital vigente.
- Acción de validación iniciada por el usuario.

### Resultado esperado

- Registro de validación con fecha y estado.
- Actualización de usos restantes del ticket.

## 5.6.- Recargas de tarjetas

### Objetivo

Gestionar y recargar títulos de transporte digitales cumpliendo la normativa oficial.

### Funcionalidad

- Visualización de tarjetas activas.
- Recarga de saldo libre.
- Renovación de títulos mensuales.
- Control de restricciones temporales.
- Historial de recargas.
- Avisos de caducidad.
- Estados visuales diferenciados.

### Flujo de usuario

Ver Anexo I, HU de AlmeriaRuta.

(👉 Aquí irán capturas y código del RechargeViewModel.)

### Fragmentos MVVM relevantes

**ViewModel**: [features/recharge/viewmodels/recharge_viewmodel.dart](../V2/almeriarutav02/lib/features/recharge/viewmodels/recharge_viewmodel.dart)

```dart
class RechargeViewModel extends ChangeNotifier {
	List<TransportCardModel> get myCards => _myCards;

	void rechargeCard(TransportCardModel card, double amount) {
		if (card.type == CardType.single) {
			card.balance += amount;
		} else {
			card.balance = getRechargeAmount(card);
		}
		card.history.add(RechargeHistory(date: DateTime.now(), amount: amount));
		notifyListeners();
	}
}
```

Este ViewModel aplica reglas de recarga por tipo de tarjeta y registra el historial de operaciones para su posterior visualización.

**View**: [features/recharge/views/recharge_view.dart](../V2/almeriarutav02/lib/features/recharge/views/recharge_view.dart)

```dart
return ChangeNotifierProvider(
	create: (_) => RechargeViewModel(),
	child: Consumer<RechargeViewModel>(
		builder: (_, vm, __) {
			return ListView.builder(
				itemCount: vm.myCards.length,
				itemBuilder: (_, i) => ListTile(
					title: Text(vm.myCards[i].name),
					trailing: ElevatedButton(
						onPressed: vm.canRecharge(vm.myCards[i]) ? () => _showRechargeDialog(context, vm, vm.myCards[i]) : null,
						child: const Text('Recargar'),
					),
				),
			);
		},
	),
);
```

La vista de recargas consume el listado de tarjetas y habilita acciones según reglas del ViewModel (`canRecharge`), manteniendo centralizada la lógica de negocio.

### HU relacionadas

- HU 002: Comprar ticket o tarjeta bus.
- HU 004: Consulta/Registro de tarjetas.
- HU 005: Recargar tarjeta bus.
- HU 0010: Gestión de notificaciones (mensual y llegada).

### Entradas principales

- Tarjeta seleccionada por el usuario.
- Importe o tipo de título a renovar.

### Resultado esperado

- Recarga aplicada según reglas vigentes.
- Historial y estado de tarjeta actualizados.

## 5.7.- Trazabilidad global de funcionalidades y HU

| Funcionalidad | HU vinculadas |
|---|---|
| 5.1 Home | HU 0010 |
| 5.2 Mapa interactivo | HU 001, HU 006, HU 007, HU 008, HU 009, HU 0010 |
| 5.3 Líneas y paradas | HU 001, HU 007, HU 009 |
| 5.4 Comprar de tickets | HU 002 |
| 5.5 Validación de viajes | HU 003 |
| 5.6 Recargas de tarjetas | HU 002, HU 004, HU 005, HU 0010 |
| 5.8 Búsqueda y favoritos compartidos | HU 001, HU 006, HU 007, HU 009 |
| 5.9 Servicios de movilidad urbana y notificaciones | HU 0010 |
| 5.10 Conexión API y optimización | HU 001, HU 007, HU 008, HU 0010 |

## 5.8.- Búsqueda y favoritos compartidos

### Objetivo

Centralizar la lógica reutilizable de búsqueda y persistencia de favoritos para que pueda ser consumida por distintas pantallas sin duplicar código.

### Funcionalidad

- Normalización de texto para búsquedas sin distinción de tildes.
- Filtrado de líneas por nombre, descripción y coincidencia con paradas.
- Campo de búsqueda reutilizable en múltiples vistas.
- Panel de favoritos con separación por tipo: paradas y líneas.
- Persistencia local de favoritos mediante `SharedPreferences`.
- Eliminación directa de favoritos desde el panel compartido.

### Flujo de uso

Ver Anexo I, HU de AlmeriaRuta.

### Fragmentos compartidos relevantes

**Utilidad de búsqueda**: [shared/services/line_search_utils.dart](../V2/almeriarutav02/lib/shared/services/line_search_utils.dart)

```dart
class LineSearchUtils {
	static String normalizeText(String text) {
		return text
				.toLowerCase()
				.replaceAll('á', 'a')
				.replaceAll('é', 'e')
				.replaceAll('í', 'i')
				.replaceAll('ó', 'o')
				.replaceAll('ú', 'u');
	}

	static List<LineModel> filterLines(List<LineModel> lines, String query, {StopMatcher? stopMatcher}) {
		final normalizedQuery = normalizeText(query.trim());
		if (normalizedQuery.isEmpty) return lines;
		return lines.where((line) {
			return normalizeText(line.name).contains(normalizedQuery) ||
					normalizeText(line.fullName).contains(normalizedQuery) ||
					normalizeText(line.description).contains(normalizedQuery) ||
					stopMatcher?.call(line.id, normalizedQuery) == true;
		}).toList();
	}
}
```

Esta utilidad centraliza la normalización del texto y evita duplicar lógica de búsqueda en distintas pantallas. El parámetro `stopMatcher` permite ampliar el filtro para que también coincida con paradas asociadas.

**Campo de búsqueda reutilizable**: [shared/widgets/app_search_field.dart](../V2/almeriarutav02/lib/shared/widgets/app_search_field.dart)

```dart
return TextField(
	controller: controller,
	decoration: InputDecoration(
		hintText: hintText,
		prefixIcon: const Icon(Icons.search),
		suffixIcon: query.isEmpty ? null : IconButton(
			icon: const Icon(Icons.clear),
			onPressed: () {
				controller.clear();
				onQueryChanged('');
			},
		),
	),
	onChanged: onQueryChanged,
	onSubmitted: onQuerySubmitted ?? onQueryChanged,
);
```

Este campo encapsula el patrón común de búsqueda con icono, limpieza rápida y callbacks reutilizables. Así, varias vistas comparten el mismo comportamiento visual y funcional.

**Panel de favoritos**: [shared/widgets/favorites_panel.dart](../V2/almeriarutav02/lib/shared/widgets/favorites_panel.dart)

```dart
return ChangeNotifierProvider(
	create: (_) => FavoritesViewModel()..load(),
	child: Consumer<FavoritesViewModel>(
		builder: (context, vm, _) {
			return TabBarView(
				children: [
					_buildList(context, vm.stops),
					_buildList(context, vm.lines),
				],
			);
		},
	),
);
```

Este panel muestra favoritos separados por tipo para reutilizar la misma UI en mapa, líneas y notificaciones. También delega la carga y eliminación al `FavoritesViewModel`.

**Persistencia de favoritos**: [features/map/viewmodels/favorites_viewmodel.dart](../V2/almeriarutav02/lib/features/map/viewmodels/favorites_viewmodel.dart)

```dart
Future<void> load() async {
	final prefs = await SharedPreferences.getInstance();
	final data = prefs.getStringList(_key) ?? [];
	_favorites.clear();
	for (final item in data) {
		_favorites.add(FavoriteModel.fromJson(json.decode(item)));
	}
	notifyListeners();
}

Future<void> add(FavoriteModel fav) async {
	if (isFavorite(fav.id, fav.type)) return;
	_favorites.add(fav);
	await _save();
	notifyListeners();
}
```

Este ViewModel mantiene la lista persistida en local y evita duplicados al añadir elementos. La persistencia con `SharedPreferences` permite recuperar favoritos al reiniciar la app.

### HU relacionadas

- HU 001: Consultar mapa de buses en tiempo real.
- HU 006: Filtrar lugares turísticos por categoría.
- HU 007: Filtrar paradas por zona geográfica.
- HU 009: Gestión de favoritos (líneas y paradas).

### Resultado esperado

- Búsqueda homogénea en distintas pantallas.
- Favoritos persistentes y reutilizables en mapa, líneas y notificaciones.

## 5.9.- Servicios de movilidad urbana y notificaciones locales

### Objetivo

Reunir los servicios informativos de movilidad urbana y la configuración de notificaciones locales que completan la experiencia principal de la aplicación.

### Funcionalidad

- Presentación de servicios informativos: Zona Azul, parkings, bicicletas y patinetes.
- Tarjeta informativa de accesibilidad para paradas PRM.
- Definición de estados visuales para servicios activos, informativos y próximos.
- Configuración de avisos locales de mensual y de llegada a parada.
- Persistencia de ajustes de notificación en almacenamiento local.

### Flujo de uso

Ver Anexo I, HU de AlmeriaRuta.

### Fragmentos compartidos relevantes

**Modelo de servicio**: [features/home/models/mobility_service_model.dart](../V2/almeriarutav02/lib/features/home/models/mobility_service_model.dart)

```dart
enum ServiceStatus {
	active,
	comingSoon,
	information,
}

class MobilityServiceModel {
	final String id;
	final String title;
	final String? subtitle;
	final String description;
	final IconData icon;
	final Color color;
	final ServiceStatus status;
}
```

Este modelo unifica la información de cada tarjeta de servicio en la pantalla principal. El `status` permite diferenciar entre funciones activas, informativas o aún no disponibles.

**HomeViewModel - servicios informativos**: [features/home/viewmodels/home_viewmodel.dart](../V2/almeriarutav02/lib/features/home/viewmodels/home_viewmodel.dart)

```dart
List<MobilityServiceModel> get urbanMobilityServices => const [
	MobilityServiceModel(id: 'zona_azul', title: 'Zona Azul', description: 'Información sobre zonas de estacionamiento regulado', icon: Icons.local_parking, color: Colors.blueAccent, status: ServiceStatus.comingSoon),
	MobilityServiceModel(id: 'parkings', title: 'Parkings', description: 'Localiza parkings públicos y plazas disponibles', icon: Icons.garage, color: Colors.purple, status: ServiceStatus.comingSoon),
	MobilityServiceModel(id: 'bikes', title: 'Bicicletas', description: 'Servicios de bicicletas públicas y carriles bici', icon: Icons.pedal_bike, color: Colors.teal, status: ServiceStatus.comingSoon),
	MobilityServiceModel(id: 'scooters', title: 'Patinetes', description: 'Patinetes eléctricos compartidos disponibles', icon: Icons.electric_scooter, color: Colors.indigo, status: ServiceStatus.comingSoon),
];

MobilityServiceModel get accessibilityService => const MobilityServiceModel(
	id: 'accessibility',
	title: 'Notificaciones Accesibilidad',
	description: 'Información sobre paradas accesibles (PRM) y zonas de estacionamiento',
	icon: Icons.accessible,
	color: Colors.amber,
	status: ServiceStatus.information,
);
```

Estas propiedades alimentan las tarjetas informativas de la Home. El primer bloque agrupa servicios de movilidad urbana y el segundo expone el servicio de accesibilidad como información complementaria.

**Modelo de notificaciones**: [features/notifications/models/notification_settings.dart](../V2/almeriarutav02/lib/features/notifications/models/notification_settings.dart)

```dart
class NotificationSettings {
	final RechargeReminderSettings recharge;
	final ArrivalAlertSettings arrival;

	const NotificationSettings.defaults()
			: recharge = const RechargeReminderSettings.defaults(),
				arrival = const ArrivalAlertSettings.defaults();
}
```

Este modelo agrupa la configuración de avisos de mensual y llegada en una sola estructura. Separar `recharge` y `arrival` hace más simple guardar, restaurar y sincronizar cada tipo de notificación.

**Pantalla de notificaciones**: [features/notifications/views/notifications_view.dart](../V2/almeriarutav02/lib/features/notifications/views/notifications_view.dart)

```dart
return ChangeNotifierProvider(
	create: (_) => NotificationsViewModel(
		favoritesViewModel: FavoritesViewModel(),
	)..load(),
	child: const _NotificationsViewBody(),
);
```

La vista solo crea el proveedor y delega toda la lógica de configuración al ViewModel. Esto mantiene la UI simple y deja la persistencia, validación y programación de avisos fuera de la capa visual.

**NotificationsViewModel**: [features/notifications/viewmodels/notifications_viewmodel.dart](../V2/almeriarutav02/lib/features/notifications/viewmodels/notifications_viewmodel.dart)

```dart
Future<void> load() async {
	_loading = true;
	notifyListeners();
	await _favoritesViewModel.load();
	_settings = await _storage.load();
	_draft = _settings;
	await _applySchedules(_settings);
	_loading = false;
	notifyListeners();
}
```

Este método sincroniza favoritos, carga la configuración guardada y reaplica las programaciones locales. Así, la pantalla recupera el estado anterior y mantiene consistencia al abrirse.

### HU relacionadas

- HU 0010: Gestión de notificaciones (mensual y llegada).

### Resultado esperado

- Servicios informativos visibles desde la Home.
- Configuración de notificaciones persistente y aplicable sin reiniciar la app.

## 5.10.- Conexión API y optimización

### Objetivo

Remitir el detalle técnico de integración API, configuración y optimizaciones a un capítulo específico de arquitectura técnica.

### Funcionalidad

- Este apartado resume la existencia de la capa de integración API-app.
- El detalle completo se documenta en el Capítulo 6.

### Flujo de conexión app-backend

- Flujo general: `View -> ViewModel -> BusApiService -> Backend API -> Models -> notifyListeners()`.
- Para endpoints, caché, retries y dependencias, ver Capítulo 6.

### Referencia técnica

Ver el documento [documentacion/6-Integracion-API-y-Dependencias.md](6-Integracion-API-y-Dependencias.md), donde se detallan:

- Endpoints y flujo de datos completo.
- Configuración de conexión y entorno.
- Optimización de caché, deduplicación, timeout y retry.
- Dependencias/plugins utilizados (Flutter y backend), incluyendo OSRM.

### HU relacionadas

- HU 001: Consultar mapa de buses en tiempo real.
- HU 007: Filtrar paradas por zona geográfica.
- HU 008: Ruta automática a lugar turístico.
- HU 0010: Gestión de notificaciones (mensual y llegada).

### Resultado esperado

- Conexión estable entre app y backend para líneas, paradas y llegadas.
- Menos peticiones repetidas y menor tiempo de carga en navegación entre vistas.
- Mayor robustez ante errores transitorios de red.
