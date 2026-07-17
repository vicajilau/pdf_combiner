import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

void main() {
  group('DocumentUtils URL Support', () {
    late HttpServer server;
    late String baseUrl;
    final pdfBytes = Uint8List.fromList(
        [0x25, 0x50, 0x44, 0x46, 0x00, 0x01, 0x02]); // PDF magic number
    final pngBytes = Uint8List.fromList(
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]); // PNG magic number
    int requestCount = 0;

    setUpAll(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUrl = 'http://localhost:${server.port}';
      server.listen((HttpRequest request) {
        requestCount++;
        final path = request.uri.path;
        if (path == '/test.pdf') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType('application', 'pdf')
            ..add(pdfBytes)
            ..close();
        } else if (path == '/test.png') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType('image', 'png')
            ..add(pngBytes)
            ..close();
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });
    });

    tearDownAll(() async {
      await server.close(force: true);
    });

    setUp(() {
      requestCount = 0;
    });

    test('prepareInput downloads PDF from URL and caches the result', () async {
      final tempDir = await Directory.systemTemp.createTemp('prep_url_test_');
      DocumentUtils.setTemporalFolderPath(tempDir.path);

      final url = '$baseUrl/test.pdf';
      final input = MergeInput.url(url);

      // Check isPDF (will trigger download)
      final isPDF = await DocumentUtils.isPDF(input);
      expect(isPDF, isTrue);
      expect(requestCount, 1);

      // Check prepareInput (should reuse cache, no additional download)
      final resultPath = await DocumentUtils.prepareInput(input);
      expect(resultPath.startsWith(tempDir.path), isTrue);
      expect(File(resultPath).existsSync(), isTrue);
      expect(p.extension(resultPath), '.pdf');
      expect(requestCount, 1); // Should still be 1 download

      await tempDir.delete(recursive: true);
    });

    test('prepareInput downloads PNG from URL and caches the result', () async {
      final tempDir = await Directory.systemTemp.createTemp('prep_url_test_');
      DocumentUtils.setTemporalFolderPath(tempDir.path);

      final url = '$baseUrl/test.png';
      final input = MergeInput.url(url);

      // Check isImage (will trigger download)
      final isImage = await DocumentUtils.isImage(input);
      expect(isImage, isTrue);
      expect(requestCount, 1);

      // Check prepareInput (should reuse cache)
      final resultPath = await DocumentUtils.prepareInput(input);
      expect(resultPath.startsWith(tempDir.path), isTrue);
      expect(File(resultPath).existsSync(), isTrue);
      expect(p.extension(resultPath), '.png');
      expect(requestCount, 1);

      await tempDir.delete(recursive: true);
    });

    test('getUrlBytes propagates HTTP error', () async {
      final url = '$baseUrl/notfound.pdf';
      final input = MergeInput.url(url);

      expect(DocumentUtils.isPDF(input), throwsA(isA<Exception>()));
    });

    test('createImageFromPDF throws error for URL input that is not PDF',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('create_img_test_');
      final url = '$baseUrl/test.png'; // PNG, not a PDF
      final input = MergeInput.url(url);

      expect(
        () => PdfCombiner.createImageFromPDF(
          input: input,
          outputDirPath: tempDir.path,
        ),
        throwsA(
          predicate(
            (e) => e is PdfCombinerException && e.message.contains(url),
          ),
        ),
      );

      await tempDir.delete(recursive: true);
    });
  });
}
