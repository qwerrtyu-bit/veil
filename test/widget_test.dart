// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/app.dart';

void main() {
  testWidgets('Veil app smoke test', (WidgetTester tester) async {
    // Строим наше приложение
    await tester.pumpWidget(const VeilApp());

    // Проверяем, что приложение запустилось
    expect(find.byType(VeilApp), findsOneWidget);
  });
}