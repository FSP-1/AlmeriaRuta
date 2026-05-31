import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:almeriarutav02/features/operario/viewmodels/operario_viewmodel.dart';
import 'package:almeriarutav02/shared/services/bus_api_service.dart';
import 'package:almeriarutav02/shared/services/line_models.dart';
import 'package:almeriarutav02/shared/services/notices_api_service.dart';

void main() {
  group('OperarioViewModel', () {
    test('sortedNotices orders by type priority and newest first within type', () async {
      final notices = [
        _notice('1', 'PARADA', DateTime(2026, 5, 1, 10, 0)),
        _notice('2', 'GENERAL', DateTime(2026, 5, 1, 11, 0)),
        _notice('3', 'LINEA', DateTime(2026, 5, 1, 12, 0)),
        _notice('4', 'GENERAL', DateTime(2026, 5, 1, 9, 0)),
      ];
      final vm = OperarioViewModel(
        api: _FakeNoticesApiService(notices: notices),
        busApi: _FakeBusApiService(),
      );

      await vm.loadData();

      final ordered = vm.sortedNotices;

      expect(ordered.map((n) => n.id), ['2', '4', '3', '1']);
    });

    test('filteredStopsForSearch returns first 20 when query is empty', () async {
      final stops = List.generate(
        25,
        (index) => _stop(
          'S$index',
          'Parada $index',
          lat: 36.8 + index / 1000,
          lon: -2.4 - index / 1000,
        ),
      );
      final vm = OperarioViewModel(
        api: _FakeNoticesApiService(),
        busApi: _FakeBusApiService(lines: [_line('L1', 'L1', stops)]),
      );

      await vm.loadData();

      final result = vm.filteredStopsForSearch;

      expect(result, hasLength(20));
      expect(result.first.id, 'S0');
      expect(result.last.id, 'S19');
    });

    test('filteredStopsForDisableSearch matches id, name and coordinates', () async {
      final stops = [
        _stop('100', 'Centro', lat: 36.83850, lon: -2.46300),
        _stop('200', 'Puerto', lat: 36.83990, lon: -2.46000),
      ];
      final vm = OperarioViewModel(
        api: _FakeNoticesApiService(),
        busApi: _FakeBusApiService(lines: [_line('L1', 'L1', stops)]),
      );

      await vm.loadData();

      vm.setDisableStopSearchQuery('centro');
      expect(vm.filteredStopsForDisableSearch, hasLength(1));
      expect(vm.filteredStopsForDisableSearch.first.id, '100');

      vm.setDisableStopSearchQuery('36.83990,-2.46000');
      expect(vm.filteredStopsForDisableSearch, hasLength(1));
      expect(vm.filteredStopsForDisableSearch.first.id, '200');
    });

    test('setNoticeType clears line and stop state when switching away from specific types', () async {
      final vm = OperarioViewModel(
        api: _FakeNoticesApiService(),
        busApi: _FakeBusApiService(lineStopsById: {
          'L1': [_stop('100', 'Centro')],
        }),
      );

      await vm.selectLine('L1');
      vm.selectStopForNotice(_stop('200', 'Puerto'));
      vm.setStopSearchQuery('puerto');

      vm.setNoticeType('GENERAL');

      expect(vm.selectedLineId, isNull);
      expect(vm.lineStops, isEmpty);
      expect(vm.selectedLineStopIds, isEmpty);
      expect(vm.selectedStopForNotice, isNull);
      expect(vm.stopSearchQuery, isEmpty);
    });

    test('validateNoticeForm enforces title, message and type-specific requirements', () async {
      final vm = OperarioViewModel(
        api: _FakeNoticesApiService(),
        busApi: _FakeBusApiService(lineStopsById: {
          'L1': [_stop('100', 'Centro')],
        }),
      );

      expect(vm.validateNoticeForm(), isFalse);
      expect(vm.error, 'El título es requerido');

      vm
        ..setNoticeTitle('Aviso')
        ..setNoticeMessage('Contenido');

      expect(vm.validateNoticeForm(), isTrue);

      vm.setNoticeType('LINEA');
      expect(vm.validateNoticeForm(), isFalse);
      expect(vm.error, 'Selecciona una línea');

      await vm.selectLine('L1');
      expect(vm.validateNoticeForm(), isFalse);
      expect(vm.error, 'Selecciona al menos una parada afectada');

      vm.toggleLineStop('100', true);
      expect(vm.validateNoticeForm(), isTrue);

      vm.setNoticeType('PARADA');
      expect(vm.validateNoticeForm(), isFalse);
      expect(vm.error, 'Selecciona una parada con el buscador');
    });

    test('validateStopForm requires selected stop and reason', () {
      final vm = OperarioViewModel(
        api: _FakeNoticesApiService(),
        busApi: _FakeBusApiService(),
      );

      expect(vm.validateStopForm(), isFalse);
      expect(vm.error, 'Selecciona una parada con el buscador');

      vm
        ..setStopId('100')
        ..setStopName('Centro');
      expect(vm.validateStopForm(), isFalse);
      expect(vm.error, 'La razón es requerida');

      vm.setStopReason('Obras');
      expect(vm.validateStopForm(), isTrue);
    });

    test('createNotice enriches LINEA notices and calls api with selected stops', () async {
      final api = _FakeNoticesApiService();
      final vm = OperarioViewModel(
        api: api,
        busApi: _FakeBusApiService(lineStopsById: {
          'L1': [
            _stop('100', 'Centro'),
            _stop('200', 'Puerto'),
          ],
        }),
      );

      vm
        ..setNoticeTitle('  Corte  ')
        ..setNoticeMessage('  Servicio interrumpido  ')
        ..setNoticeType('LINEA');

      await vm.selectLine('L1');
      vm.toggleLineStop('100', true);
      vm.toggleLineStop('200', true);

      final result = await vm.createNotice();

      expect(result, isTrue);
      expect(api.createCalls, hasLength(1));
      expect(api.createCalls.first.title, 'Corte');
      expect(api.createCalls.first.type, 'LINEA');
      expect(api.createCalls.first.relatedId, 'L1');
      expect(api.createCalls.first.message, contains('Servicio interrumpido'));
      expect(api.createCalls.first.message, contains('Paradas afectadas: Centro, Puerto'));
    });

    test('disableStop sends trimmed payload and user id to api', () async {
      final api = _FakeNoticesApiService();
      final vm = OperarioViewModel(
        api: api,
        busApi: _FakeBusApiService(),
        userId: 99,
      );

      vm
        ..setStopId(' 100 ')
        ..setStopName('  Centro ')
        ..setStopReason('  Obras  ');

      final result = await vm.disableStop();

      expect(result, isTrue);
      expect(api.disableStopCalls, hasLength(1));
      expect(api.disableStopCalls.first.stopId, '100');
      expect(api.disableStopCalls.first.stopName, 'Centro');
      expect(api.disableStopCalls.first.reason, 'Obras');
      expect(api.disableStopCalls.first.userId, 99);
    });
  });
}

class _FakeNoticesApiService extends NoticesApiService {
  final List<_CreateNoticeCall> createCalls = [];
  final List<_DisableStopCall> disableStopCalls = [];
  final List<NoticeModel> notices;
  final List<DisabledStopModel> disabledStops;

  _FakeNoticesApiService({
    this.notices = const [],
    this.disabledStops = const [],
  }) : super(client: http.Client());

  @override
  Future<List<NoticeModel>> listNotices({String? token}) async => notices;

  @override
  Future<List<DisabledStopModel>> listDisabledStops({String? token}) async => disabledStops;

  @override
  Future<void> createNotice({
    String? token,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    createCalls.add(
      _CreateNoticeCall(
        token: token,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
      ),
    );
  }

  @override
  Future<void> disableStop({
    String? token,
    required String stopId,
    required String stopName,
    String? reason,
    int? userId,
  }) async {
    disableStopCalls.add(
      _DisableStopCall(
        token: token,
        stopId: stopId,
        stopName: stopName,
        reason: reason,
        userId: userId,
      ),
    );
  }

  @override
  Future<void> enableStop({String? token, required String stopId}) async {}

  @override
  Future<void> deactivateNotice({String? token, required String noticeId}) async {}
}

class _FakeBusApiService extends BusApiService {
  final List<LineModel> lines;
  final Map<String, List<StopModel>> lineStopsById;

  _FakeBusApiService({
    this.lines = const [],
    this.lineStopsById = const {},
  });

  @override
  Future<List<LineModel>> getLines({bool forceRefresh = false}) async => lines;

  @override
  Future<List<StopModel>> getLineStops(String lineId, {bool forceRefresh = false}) async {
    return lineStopsById[lineId] ?? const [];
  }
}

class _CreateNoticeCall {
  final String? token;
  final String title;
  final String message;
  final String type;
  final String? relatedId;

  _CreateNoticeCall({
    required this.token,
    required this.title,
    required this.message,
    required this.type,
    required this.relatedId,
  });
}

class _DisableStopCall {
  final String? token;
  final String stopId;
  final String stopName;
  final String? reason;
  final int? userId;

  _DisableStopCall({
    required this.token,
    required this.stopId,
    required this.stopName,
    required this.reason,
    required this.userId,
  });
}

NoticeModel _notice(String id, String type, DateTime createdAt) {
  return NoticeModel(
    id: id,
    title: 'Aviso $id',
    message: 'Mensaje $id',
    type: type,
    createdAt: createdAt,
  );
}

StopModel _stop(
  String id,
  String name, {
  double lat = 36.8385,
  double lon = -2.463,
}) {
  return StopModel(
    id: id,
    name: name,
    lat: lat,
    lon: lon,
    zone: 'A',
  );
}

LineModel _line(String id, String name, List<StopModel> stops) {
  return LineModel(
    id: id,
    name: name,
    fullName: name,
    description: 'Linea $name',
    frequency: '15 min',
    firstService: '06:30',
    lastService: '22:30',
    totalStops: stops.length,
    stops: stops,
  );
}
