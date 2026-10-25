import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalpkrut_mahaticket/core/theme/app_theme.dart';

void main() {
  testWidgets('MahaTicket App Theme and Widget Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: Text('MahaTicket (महातिकिट)'),
          ),
        ),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('MahaTicket (महातिकिट)'), findsOneWidget);
  });
}
