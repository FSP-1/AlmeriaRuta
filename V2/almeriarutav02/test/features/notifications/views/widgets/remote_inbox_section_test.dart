import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/notifications/models/user_notification.dart';
import 'package:almeriarutav02/features/notifications/views/widgets/remote_inbox_section.dart';

void main() {
  testWidgets('shows delete action and calls delete callback', (tester) async {
    final deletes = <int>[];
    final opens = <int>[];
    final notification = UserNotification(
      id: 7,
      title: 'Nuevo aviso',
      body: 'Mensaje',
      isRead: false,
      createdAt: DateTime(2026, 5, 1, 12, 0),
      payloadJson: null,
      ticket: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemoteInboxSection(
            notifications: [notification],
            onOpenNotification: (item) async {
              opens.add(item.id);
            },
            onDeleteNotification: (item) async {
              deletes.add(item.id);
            },
          ),
        ),
      ),
    );

    expect(find.text('Bandeja personal'), findsOneWidget);
    expect(find.text('Nuevo aviso'), findsOneWidget);
    expect(find.byTooltip('Eliminar notificación'), findsOneWidget);
    expect(find.text('Abrir'), findsOneWidget);

    await tester.tap(find.byTooltip('Eliminar notificación'));
    await tester.pumpAndSettle();

    expect(deletes, [7]);
    expect(opens, isEmpty);
  });

  testWidgets('hides open button for read notifications but keeps delete action', (tester) async {
    final notification = UserNotification(
      id: 8,
      title: 'Leida',
      body: 'Ya vista',
      isRead: true,
      createdAt: DateTime(2026, 5, 1, 12, 0),
      payloadJson: null,
      ticket: null,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemoteInboxSection(
            notifications: [notification],
            onOpenNotification: _noop,
            onDeleteNotification: _noop,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Eliminar notificación'), findsOneWidget);
    expect(find.text('Abrir'), findsNothing);
  });
}

Future<void> _noop(UserNotification notification) async {}
