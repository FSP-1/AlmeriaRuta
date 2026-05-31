import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:almeriarutav02/features/operario/viewmodels/operario_viewmodel.dart';
import 'package:almeriarutav02/features/operario/views/widgets/operario_notice_tab.dart';
import 'package:almeriarutav02/shared/services/bus_api_service.dart';
import 'package:almeriarutav02/shared/services/line_models.dart';
import 'package:almeriarutav02/shared/services/notices_api_service.dart';

void main() {
  testWidgets('renders line notice flow and collapses affected stops', (tester) async {
    final vm = _FakeOperarioViewModel(
      noticeType: 'LINEA',
      notices: [
        NoticeModel(
          id: 'n1',
          title: 'Aviso 1',
          message: 'Mensaje 1',
          type: 'GENERAL',
          createdAt: DateTime(2026, 5, 1, 12, 0),
        ),
      ],
      lines: [
        LineModel(
          id: 'L1',
          name: 'L1',
          fullName: 'L1 Completa',
          description: 'Linea L1',
          frequency: '15 min',
          firstService: '06:30',
          lastService: '22:30',
          totalStops: 2,
          stops: const [],
        ),
      ],
      selectedLineId: 'L1',
      lineStops: [
        _stop('100', 'Centro'),
        _stop('200', 'Puerto'),
      ],
      selectedLineStopIds: {'100'},
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<OperarioViewModel>.value(
        value: vm,
        child: const MaterialApp(
          home: Scaffold(body: OperarioNoticeTab()),
        ),
      ),
    );

    expect(find.text('Crear aviso'), findsOneWidget);
    expect(find.text('Línea afectada'), findsOneWidget);
    expect(find.text('Paradas de la línea (marca las afectadas)'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('ID: 100'), findsOneWidget);
    expect(find.text('Avisos activos'), findsOneWidget);
    expect(find.text('Aviso 1'), findsOneWidget);
  });

  testWidgets('renders parada flow with filtered stops and selection', (tester) async {
    final vm = _FakeOperarioViewModel(
      noticeType: 'PARADA',
      filteredStopsForSearch: [
        _stop('100', 'Centro'),
        _stop('200', 'Puerto'),
      ],
      selectedStopForNotice: _stop('200', 'Puerto'),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<OperarioViewModel>.value(
        value: vm,
        child: const MaterialApp(
          home: Scaffold(body: OperarioNoticeTab()),
        ),
      ),
    );

    expect(find.text('Buscar parada por nombre o posición'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('Puerto'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  });
}

class _FakeOperarioViewModel extends OperarioViewModel {
  @override
  bool get loading => false;

  @override
  String? get error => null;

  @override
  String? get successMessage => null;

  @override
  String get noticeTitle => '';

  @override
  String get noticeMessage => '';

  @override
  String get noticeType => _noticeType;
  final String _noticeType;

  @override
  String? get selectedLineId => _selectedLineId;
  final String? _selectedLineId;

  @override
  Set<String> get selectedLineStopIds => _selectedLineStopIds;
  final Set<String> _selectedLineStopIds;

  @override
  List<LineModel> get lines => _lines;
  final List<LineModel> _lines;

  @override
  List<StopModel> get lineStops => _lineStops;
  final List<StopModel> _lineStops;

  @override
  List<StopModel> get filteredStopsForSearch => _filteredStopsForSearch;
  final List<StopModel> _filteredStopsForSearch;

  @override
  StopModel? get selectedStopForNotice => _selectedStopForNotice;
  final StopModel? _selectedStopForNotice;

  @override
  List<NoticeModel> get sortedNotices => _sortedNotices;
  final List<NoticeModel> _sortedNotices;

  _FakeOperarioViewModel({
    String noticeType = 'GENERAL',
    List<NoticeModel> notices = const [],
    List<LineModel> lines = const [],
    String? selectedLineId,
    List<StopModel> lineStops = const [],
    Set<String> selectedLineStopIds = const {},
    List<StopModel> filteredStopsForSearch = const [],
    StopModel? selectedStopForNotice,
  })  : _noticeType = noticeType,
        _sortedNotices = notices,
        _lines = lines,
        _selectedLineId = selectedLineId,
        _lineStops = lineStops,
        _selectedLineStopIds = selectedLineStopIds,
        _filteredStopsForSearch = filteredStopsForSearch,
        _selectedStopForNotice = selectedStopForNotice,
        super(
          api: _FakeNoticesApiService(),
          busApi: _FakeBusApiService(),
        );
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
