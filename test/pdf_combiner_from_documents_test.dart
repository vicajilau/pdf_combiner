import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

void main() {
  group('PdfCombiner.generatePDFFromDocuments', () {


    test('error cuando inputPaths está vacío', () async {
      final res = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: const [],
        outputPath: 'out.pdf',
      );

      expect(res.status, PdfCombinerStatus.error);
      expect(res.message, PdfCombinerMessages.emptyParameterMessage('inputPaths'));
    });

    test('error cuando outputPath está vacío o en blanco', () async {
      final res = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: const ['any'],
        outputPath: '   ',
      );

      expect(res.status, PdfCombinerStatus.error);
      expect(res.message, PdfCombinerMessages.emptyParameterMessage('outputPath'));
    });

    test('error cuando outputPath no tiene extensión .pdf (case-sensitive)', () async {
      var createCalls = 0;
      var mergeCalls = 0;

      final res = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: const ['foo.xyz'],
        outputPath: 'out.PDF',
      );

      expect(res.status, PdfCombinerStatus.error);
      expect(
        res.message,
        PdfCombinerMessages.errorMessageInvalidOutputPath('out.PDF'),
      );
      expect(createCalls, 0);
      expect(mergeCalls, 0);
    });

    test('error mixed cuando el input no es PDF ni imagen', () async {
      final firstPath = '/path/invalido.xyz';

      final res = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: [firstPath],
        outputPath: 'out.pdf',
      );

      expect(res.status, PdfCombinerStatus.error);
      expect(res.message, PdfCombinerMessages.errorMessageMixed(firstPath));
    });
  });
}
