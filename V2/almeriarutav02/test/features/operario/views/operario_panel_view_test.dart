import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:almeriarutav02/features/operario/views/operario_panel_view.dart';
import 'package:almeriarutav02/features/operario/viewmodels/operario_viewmodel.dart';
import 'package:almeriarutav02/shared/services/bus_api_service.dart';
import 'package:almeriarutav02/shared/services/notices_api_service.dart';

void main() {
  testWidgets('renders the operario panel tabs and triggers initial load', (tester) async {
    final vm = _FakeOperarioViewModel();

    await tester.pumpWidget(
      ChangeNotifierProvider<OperarioViewModel>.value(
        value: vm,
        child: const MaterialApp(
          home: OperarioPanelView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Panel de Operario'), findsOneWidget);
    expect(find.text('Avisos'), findsOneWidget);
    expect(find.text('Paradas'), findsOneWidget);
    expect(find.text('Solicitudes'), findsOneWidget);
    expect(vm.loadCalls, 1);
  });
}

class _FakeOperarioViewModel extends OperarioViewModel {
  int loadCalls = 0;

  _FakeOperarioViewModel()
      : super(
          api: _FakeNoticesApiService(),
          busApi: _FakeBusApiService(),
        );

  @override
  Future<void> loadData() async {
    loadCalls++;
  }
}

class _FakeNoticesApiService extends NoticesApiService {
  _FakeNoticesApiService() : super(client: http.Client());
}

class _FakeBusApiService extends BusApiService {
  _FakeBusApiService();
}
