import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('createPdfFromMultipleImages parses HEIC',
      (WidgetTester tester) async {
    // We expect sample.heic to be in the assets directory.
    // In integration tests on Linux, we can access the file system.

    final sampleHeicPath =
        '/home/vicajilau/Developer/Flutter/pdf_combiner/example/assets/sample.heic';
    final File heicFile = File(sampleHeicPath);

    expect(heicFile.existsSync(), true,
        reason: 'sample.heic must exist at $sampleHeicPath');

    final outputDir = await getTemporaryDirectory();
    final outputPath = p.join(outputDir.path, 'output.pdf');
    if (File(outputPath).existsSync()) {
      File(outputPath).deleteSync();
    }

    // Call the plugin
    await PdfCombiner.createPDFFromMultipleImages(
      inputPaths: [sampleHeicPath],
      outputPath: outputPath,
    );

    final outputFile = File(outputPath);
    expect(outputFile.existsSync(), true,
        reason: 'Output PDF should be created');
    expect(outputFile.lengthSync(), greaterThan(0),
        reason: 'Output PDF should not be empty');
  });
}
