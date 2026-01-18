import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';

void main() {
  group('PdfCombiner.generatePDFFromDocuments', () {
    test('error cuando inputPaths está vacío', () async {
      PdfCombiner.isMock = false;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputs: [],
          outputPath: 'out.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message.contains(
                  PdfCombinerMessages.emptyParameterMessage('inputs'),
                ),
          ),
        ),
      );
    });

    test('error cuando outputPath está vacío o en blanco', () async {
      PdfCombiner.isMock = false;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputs: const [MergeInputPath('any')],
          outputPath: '   ',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message.contains(
                  PdfCombinerMessages.emptyParameterMessage('outputPath'),
                ),
          ),
        ),
      );
    });

    test('error cuando outputPath no tiene extensión .pdf (case-sensitive)',
        () async {
      PdfCombiner.isMock = false;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputs: const [MergeInputPath('foo.xyz')],
          outputPath: 'out.PDF',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message.contains(
                  PdfCombinerMessages.errorMessageInvalidOutputPath('out.PDF'),
                ),
          ),
        ),
      );
    });

    test('error mixed cuando el input no es PDF ni imagen', () async {
      PdfCombiner.isMock = false;
      final firstPath = '/path/invalido.xyz';

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputs: [MergeInputPath(firstPath)],
          outputPath: 'out.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message.contains(
                  PdfCombinerMessages.errorMessageMixed(firstPath),
                ),
          ),
        ),
      );
    });
  });
}
