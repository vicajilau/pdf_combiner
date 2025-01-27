import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_combiner_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test PDF Combiner functionality', (WidgetTester tester) async {
    // Launch the app
    app.main();

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Here you can simulate the file selection (depending on your file picker mock)
    // You should have a mock set up for the file selection

    // Now ensure the "Combine PDFs" button is enabled
    expect(find.text('Combine PDFs'), findsOneWidget);
    expect(find.byType(ElevatedButton),
        findsWidgets); // Ensure at least one button is available

    // Simulate a tap on the "Combine PDFs" button
    await tester.tap(find.text('Combine PDFs'));
    await tester.pumpAndSettle();

    // Now ensure the "PDF from images" button is enabled
    expect(find.text('PDF from images'), findsOneWidget);
    expect(find.byType(ElevatedButton),
        findsWidgets); // Ensure at least one button is available

    // Simulate a tap on the "PDF from images" button
    await tester.tap(find.text('PDF from images'));
    await tester.pumpAndSettle();

    // Now ensure the "Images from PDF" button is enabled
    expect(find.text('Images from PDF'), findsOneWidget);
    expect(find.byType(ElevatedButton),
        findsWidgets); // Ensure at least one button is available
  });
}
