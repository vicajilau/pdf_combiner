import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';

void main() {
  group('PdfCombinerMessages', () {
    test('successMessage returns correct message', () {
      expect(PdfCombinerMessages.successMessage, 'Processed successfully');
    });

    test('errorMessage returns correct message', () {
      expect(PdfCombinerMessages.errorMessage, 'Error in processing');
    });

    test('processingMessage returns correct message', () {
      expect(PdfCombinerMessages.processingMessage, 'Processing start');
    });

    test('emptyParameterMessage returns correct message', () {
      expect(
        PdfCombinerMessages.emptyParameterMessage('inputPaths'),
        'The parameter (inputPaths) cannot be empty',
      );
    });

    test('errorMessagePDF returns correct message with path', () {
      expect(
        PdfCombinerMessages.errorMessagePDF('/path/to/file.txt'),
        'File is not of PDF type or does not exist: /path/to/file.txt',
      );
    });

    test('errorMessagePDF returns correct message with null path', () {
      expect(
        PdfCombinerMessages.errorMessagePDF(null),
        'File is not of PDF type or does not exist: File in bytes',
      );
    });

    test('errorMessageImage returns correct message', () {
      expect(
        PdfCombinerMessages.errorMessageImage('/path/to/file.txt'),
        'File is not an image or does not exist: /path/to/file.txt',
      );
    });

    test('errorMessageInvalidOutputPath returns correct message', () {
      expect(
        PdfCombinerMessages.errorMessageInvalidOutputPath('/path/to/file.txt'),
        'The outputPath must have a .pdf format: /path/to/file.txt',
      );
    });

    test('errorMessageMixed returns correct message', () {
      expect(
        PdfCombinerMessages.errorMessageMixed('/path/to/file.xyz'),
        'The file is neither a PDF document nor an image or does not exist: /path/to/file.xyz',
      );
    });
  });
}
