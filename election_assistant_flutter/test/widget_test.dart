import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_assistant/app.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ElectionAssistantApp());

    // Verify that the ChatScreen is rendered (it should have a TextField with hint 'Type your election question...')
    expect(find.byType(TextField), findsOneWidget);
  });
}

