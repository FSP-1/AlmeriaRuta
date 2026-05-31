import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:almeriarutav02/features/operario/viewmodels/operario_viewmodel.dart';
import 'package:almeriarutav02/features/operario/views/widgets/operario_notice_card.dart';
import 'package:almeriarutav02/shared/services/bus_api_service.dart';
import 'package:almeriarutav02/shared/services/line_models.dart';
import 'package:almeriarutav02/shared/services/notices_api_service.dart';

void main() {
  testWidgets('deactivate button calls the viewmodel and shows success snackbar', (tester) async {
    final vm = _FakeOperarioViewModel();
    final notice = NoticeModel(
      id: 'n1',
      title: 'Aviso de prueba',
      message: 'Mensaje de prueba',
      type: 'GENERAL',
      createdAt: DateTime(2026, 5, 1, 12, 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OperarioNoticeCard(vm: vm, notice: notice),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Desactivar aviso'));
    await tester.pumpAndSettle();

    expect(vm.deactivateCalls, 1);
    expect(vm.lastNoticeId, 'n1');
    expect(find.text('Aviso desactivado exitosamente'), findsOneWidget);
  });
}

class _FakeOperarioViewModel extends OperarioViewModel {
  int deactivateCalls = 0;
  String? lastNoticeId;
  bool _loading = false;
  String? _error;
  String? _successMessage;

  _FakeOperarioViewModel()
      : super(
          api: _FakeNoticesApiService(),
          busApi: _FakeBusApiService(),
        );

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  String? get successMessage => _successMessage;

  @override
  Future<void> deactivateNotice(String noticeId) async {
    deactivateCalls++;
    lastNoticeId = noticeId;
    _error = null;
    _successMessage = 'Aviso desactivado exitosamente';
    notifyListeners();
  }
}

class _FakeNoticesApiService extends NoticesApiService {
  _FakeNoticesApiService() : super(client: http.Client());
}

class _FakeBusApiService extends BusApiService {
  _FakeBusApiService();
}
