import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:almeriarutav02/features/operario/viewmodels/operario_viewmodel.dart';
import 'package:almeriarutav02/features/operario/views/widgets/operario_stops_tab.dart';
import 'package:almeriarutav02/shared/services/bus_api_service.dart';
import 'package:almeriarutav02/shared/services/line_models.dart';
import 'package:almeriarutav02/shared/services/notices_api_service.dart';

void main() {
  testWidgets('renders stop search, selection and disabled stop list', (tester) async {
    final vm = _FakeOperarioViewModel(
      filteredStopsForDisableSearch: [
        _stop('100', 'Centro'),
        _stop('200', 'Puerto'),
      ],
      disabledStops: [
        DisabledStopModel(
          stopId: '300',
          stopName: 'Plaza Nueva',
          reason: 'Obras',
          disabledAt: DateTime(2026, 5, 1, 10, 0),
        ),
      ],
      error: 'Selecciona una parada con el buscador',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<OperarioViewModel>.value(
        value: vm,
        child: const MaterialApp(
          home: Scaffold(body: OperarioStopsTab()),
        ),
      ),
    );

    expect(find.text('Buscar parada por nombre o posición'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('Paradas deshabilitadas'), findsOneWidget);
    expect(find.text('Plaza Nueva'), findsOneWidget);
    expect(find.text('Ya está deshabilitada'), findsNothing);
    expect(find.text('Selecciona una parada con el buscador'), findsNWidgets(2));

    await tester.tap(find.text('Puerto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Seleccionada: Puerto (200)'), findsOneWidget);
  });
}

class _FakeOperarioViewModel extends OperarioViewModel {
  final List<StopModel> _filteredStopsForDisableSearch;
  final List<DisabledStopModel> _disabledStops;
  final String? _error;
  StopModel? _selectedStopForDisable;

  _FakeOperarioViewModel({
    List<StopModel> filteredStopsForDisableSearch = const [],
    List<DisabledStopModel> disabledStops = const [],
    String? error,
  })  : _filteredStopsForDisableSearch = filteredStopsForDisableSearch,
        _disabledStops = disabledStops,
        _error = error,
        super(
          api: _FakeNoticesApiService(),
          busApi: _FakeBusApiService(),
        );

  @override
  bool get loading => false;

  @override
  String? get error => _error;

  @override
  String? get successMessage => null;

  @override
  List<StopModel> get filteredStopsForDisableSearch => _filteredStopsForDisableSearch;

  @override
  List<DisabledStopModel> get disabledStops => _disabledStops;

  @override
  StopModel? get selectedStopForDisable => _selectedStopForDisable;

  @override
  bool get isSelectedStopAlreadyDisabled =>
      _selectedStopForDisable != null &&
      _disabledStops.any((stop) => stop.stopId == _selectedStopForDisable!.id);

  @override
  void selectStopForDisable(StopModel stop) {
    _selectedStopForDisable = stop;
    notifyListeners();
  }

  @override
  void clearDisableStopSelection() {
    _selectedStopForDisable = null;
    notifyListeners();
  }

  @override
  Future<bool> disableStop() async => true;

  @override
  Future<void> enableStop(String stopId) async {}
}

class _FakeNoticesApiService extends NoticesApiService {
  _FakeNoticesApiService() : super(client: http.Client());
}

class _FakeBusApiService extends BusApiService {
  _FakeBusApiService();
}

StopModel _stop(String id, String name) {
  return StopModel(
    id: id,
    name: name,
    lat: 36.8385,
    lon: -2.463,
    zone: 'A',
  );
}
