import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';

void main() {
  group('PdfCombiner.generatePDFFromDocuments', () {
    test('error cuando inputs está vacío', () async {
      PdfCombiner.isMock = false;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputs: const [],
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
          inputs: [MergeInput.path('any')],
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
  });
}
