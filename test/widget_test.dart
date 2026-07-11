import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_app/main.dart';

void main() {
  testWidgets('App renders empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('Add Task'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
