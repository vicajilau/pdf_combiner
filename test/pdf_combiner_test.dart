import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/pdf_combiner_method_channel.dart';
import 'package:pdf_combiner/pdf_combiner_platform_interface.dart';

import 'mocks/mock_pdf_combiner_platform.dart';

// Mock de la plataforma que simula un error en mergeMultiplePDF
class MockPdfCombinerPlatformWithError extends MockPdfCombinerPlatform {
  @override
  Future<String?> mergeMultiplePDF({
    required List<String> paths,
    required String outputDirPath,
  }) {
    return Future.error('Simulated Error');
  }
}

void main() {
  group('PdfCombiner', () {
    final PdfCombinerPlatform initialPlatform = PdfCombinerPlatform.instance;

    // Test para comprobar la instancia predeterminada
    test('$MethodChannelPdfCombiner es la instancia predeterminada', () {
      expect(initialPlatform, isInstanceOf<MethodChannelPdfCombiner>());
    });

    // Test para combinar PDFs
    test('combine (PdfCombiner)', () async {
      PdfCombiner pdfCombinerPlugin = PdfCombiner();
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      final result =
          await pdfCombinerPlugin.combine(['path1', 'path2'], 'output/path');

      expect(result, 'Merged PDF');
    });

    // Test de manejo de errores en combine (simulando un error en el mock)
    test('combine - Error handling (PdfCombiner)', () async {
      PdfCombiner pdfCombinerPlugin = PdfCombiner();

      // Creamos un Mock que simula un error en el método mergeMultiplePDF
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatformWithError;

      final result =
          await pdfCombinerPlugin.combine(['path1', 'path2'], 'output/path');

      expect(result, 'Error combining the PDFs: Simulated Error');
    });
  });
}
