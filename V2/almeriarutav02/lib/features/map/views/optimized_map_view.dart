import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../viewmodels/map_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/bus_api_service.dart';

class OptimizedMapView extends StatefulWidget {
  const OptimizedMapView({super.key});

  @override
  State<OptimizedMapView> createState() => _OptimizedMapViewState();
}

class _OptimizedMapViewState extends State<OptimizedMapView> {
  final MapController _mapController = MapController();
  double _currentZoom = 13.0;
  List<StopModel> _stops = [];
  List<LineModel> _lines = [];
  String? _selectedLineId;
  String _selectedZone = 'Todas';
  bool _isLoadingStops = false;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadStops();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        
        print('GPS Location: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadStops() async {
    setState(() => _isLoadingStops = true);
    try {
      final apiService = BusApiService();
      final lines = await apiService.getLines();
      final uniqueStops = <String, StopModel>{};
      
      for (final line in lines) {
        final stops = await apiService.getLineStops(line.id);
        
        for (final stop in stops) {
          if (uniqueStops.containsKey(stop.id)) {
            uniqueStops[stop.id] = uniqueStops[stop.id]!.copyWith(
              lineIds: {...uniqueStops[stop.id]!.lineIds, line.id},
            );
          } else {
            uniqueStops[stop.id] = stop.copyWith(
              lineIds: {line.id},
            );
          }
        }
      }
      
      setState(() {
        _lines = lines;
        _stops = uniqueStops.values.toList();
        _isLoadingStops = false;
      });
    } catch (e) {
      setState(() => _isLoadingStops = false);
    }
  }

  List<StopModel> get _filteredStops {
    var stops = _stops;
    
    // Filtro de desarrollo: solo L11 y L18
    const devLines = {'L11', 'L18'};
    stops = stops.where((stop) => 
      stop.lineIds.any((lineId) => devLines.contains(lineId))
    ).toList();
    
    return stops.where((stop) {
      final matchesZone = _selectedZone == 'Todas' || stop.zone == _selectedZone;
      final matchesLine = _selectedLineId == null || stop.lineIds.contains(_selectedLineId);
      return matchesZone && matchesLine;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mapa de Almería'),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedLineId,
                      hint: const Text('Todas las líneas'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas')),
                        // Solo mostrar L11 y L18 en desarrollo
                        ..._lines.where((line) => ['L11', 'L18'].contains(line.id))
                            .map((line) => DropdownMenuItem(
                              value: line.id,
                              child: Text(line.name),
                            )),
                      ],
                      onChanged: (value) => setState(() => _selectedLineId = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedZone,
                      isExpanded: true,
                      items: ['Todas', 'Centro', 'Norte', 'Este', 'Oeste', 'A']
                          .map((zone) => DropdownMenuItem(
                                value: zone,
                                child: Text('Zona $zone'),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedZone = value!),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(36.8381, -2.4597),
                  initialZoom: 13.0,
                  minZoom: 10.0,
                  maxZoom: 18.0,
                  onPositionChanged: (position, hasGesture) {
                    setState(() {
                      _currentZoom = position.zoom;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.almeriarutav02',
                  ),
                  if (_currentZoom >= 14 && !_isLoadingStops)
                    MarkerLayer(
                      markers: [
                        ..._filteredStops.map((stop) => Marker(
                          point: LatLng(stop.lat, stop.lon),
                          width: 30,
                          height: 30,
                          child: GestureDetector(
                            onTap: () => _showStopInfo(stop),
                            child: Container(
                              decoration: BoxDecoration(
                                color: stop.lineIds.length > 1
                                    ? Colors.purple
                                    : AppTheme.primaryRed,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.directions_bus,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        )),
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        '© OpenStreetMap contributors',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_userLocation != null) {
              _mapController.move(_userLocation!, 15.0);
            } else {
              _mapController.move(const LatLng(36.8381, -2.4597), 13.0);
            }
          },
          backgroundColor: AppTheme.primaryRed,
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
    );
  }

  void _showStopInfo(StopModel stop) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stop.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Zona: ${stop.zone}'),
            Text('Líneas: ${stop.lineIds.join(", ")}'),
            Text('Coordenadas: ${stop.lat.toStringAsFixed(4)}, ${stop.lon.toStringAsFixed(4)}'),
            if (_userLocation != null) ...[
              const SizedBox(height: 8),
              Text('Distancia: ${_calculateDistance(stop)} m'),
            ],
          ],
        ),
      ),
    );
  }

  String _calculateDistance(StopModel stop) {
    if (_userLocation == null) return '---';
    
    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      stop.lat,
      stop.lon,
    );
    
    return distance.round().toString();
  }
}