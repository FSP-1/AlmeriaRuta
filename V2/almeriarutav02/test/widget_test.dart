import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test renders a simple app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('AlmeriaRuta')),
        ),
      ),
    );

    expect(find.text('AlmeriaRuta'), findsOneWidget);
  });
}
