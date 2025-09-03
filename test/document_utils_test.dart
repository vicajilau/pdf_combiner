
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/utils/document_utils.dart';


void main() {
  late bool originalIsMock;

  setUp(() {
    // Guardamos el valor original para restaurarlo en tearDown
    originalIsMock = PdfCombiner.isMock;
  });

  tearDown(() {
    // Restauramos el valor original aunque la prueba cambie el flag
    PdfCombiner.isMock = originalIsMock;
  });

  /// Helpers

  Future<File> createFileWithBytes(String path, List<int> bytes) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // Firmas mínimas por "magic number"
  // PDF: "%PDF-1.4" + ... + "%%EOF"
  final pdfBytes = <int>[
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, // %PDF-1.4
    0x0A,
    // cuerpo mínimo ficticio
    0x25, 0x25, 0x45, 0x4F, 0x46, // %%EOF
  ];

  // PNG: firma de 8 bytes + algo de relleno
  final pngBytes = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // firma PNG
    // Relleno para evitar falsos negativos
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  ];

  // JPEG: FF D8 FF + relleno
  final jpgBytes = <int>[
    0xFF, 0xD8, 0xFF, // firma JPEG
    0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, // JFIF...
  ];

  group('getTemporalFolderPath', () {
    test('devuelve ruta mock cuando PdfCombiner.isMock = true', () {
      PdfCombiner.isMock = true;

      final path = DocumentUtils.getTemporalFolderPath();

      expect(path, './example/assets/temp');
    });

    test('devuelve Directory.systemTemp.path cuando PdfCombiner.isMock = false', () {
      PdfCombiner.isMock = false;

      final path = DocumentUtils.getTemporalFolderPath();

      expect(path, Directory.systemTemp.path);
    });
  });

  group('removeTemporalFiles', () {
    test('no elimina nada cuando isMock = true (se salta el bucle)', () async {
      PdfCombiner.isMock = true;
      final mockTemp = DocumentUtils.getTemporalFolderPath();
      final fileInMockTemp = p.join(mockTemp, 'will_not_be_deleted.tmp');

      final file = await createFileWithBytes(fileInMockTemp, [1, 2, 3]);

      // Aun cuando el path está dentro de la carpeta temporal mock, no debe borrarlo
      DocumentUtils().removeTemporalFiles([fileInMockTemp]);

      expect(File(fileInMockTemp).existsSync(), isTrue);

      // Limpieza
      await file.delete();
    });

    test('elimina solo archivos dentro de systemTemp cuando isMock = false', () async {
      PdfCombiner.isMock = false;

      // Dentro de /tmp (o la ruta equivalente en el SO)
      final tempDir = await Directory.systemTemp.createTemp('doc_utils_test_');
      final insidePath = p.join(tempDir.path, 'to_delete.tmp');

      // Fuera de system temp: usamos el directorio actual del proyecto
      final outsidePath = p.join(Directory.current.path, 'should_not_be_deleted.tmp');
      final outsideFile = await createFileWithBytes(outsidePath, [9, 9, 9]);

      // También probamos una ruta inexistente que SÍ comienza por systemTemp
      final nonExistentInside = p.join(tempDir.path, 'non_existent.tmp');

      DocumentUtils().removeTemporalFiles([insidePath, outsidePath, nonExistentInside]);

      // Debe haberse eliminado el de dentro del systemTemp
      expect(File(insidePath).existsSync(), isFalse);

      // No debe eliminar el de fuera
      expect(File(outsidePath).existsSync(), isTrue);

      // La inexistente no debe lanzar error
      expect(File(nonExistentInside).existsSync(), isFalse);

      // Limpieza
      await outsideFile.delete();
      await tempDir.delete(recursive: true);
    });
  });

  group('hasPDFExtension', () {
    test('true para ".pdf"', () {
      expect(DocumentUtils.hasPDFExtension('foo.pdf'), isTrue);
    });

    test('false para ".PDF" (comparación sensible a mayúsculas)', () {
      expect(DocumentUtils.hasPDFExtension('bar.PDF'), isFalse);
    });
  });

  group('isPDF', () {
    test('true para un archivo con magic number de PDF', () async {
      final tempDir = await Directory.systemTemp.createTemp('doc_utils_pdf_');
      final pdfPath = p.join(tempDir.path, 'test.pdf');
      await createFileWithBytes(pdfPath, pdfBytes);

      final result = await DocumentUtils.isPDF(pdfPath);
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false para un archivo que no es PDF (ej. PNG)', () async {
      final tempDir = await Directory.systemTemp.createTemp('doc_utils_pdf2_');
      final pngPath = p.join(tempDir.path, 'image.png');
      await createFileWithBytes(pngPath, pngBytes);

      final result = await DocumentUtils.isPDF(pngPath);
      expect(result, isFalse);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false cuando hay excepción (ruta inexistente)', () async {
      final nonExistent = p.join(Directory.systemTemp.path, 'no_such_file.pdf');
      final result = await DocumentUtils.isPDF(nonExistent);
      expect(result, isFalse);
    });
  });

  group('isImage', () {
    test('true para PNG', () async {
      final tempDir = await Directory.systemTemp.createTemp('doc_utils_img_png_');
      final pngPath = p.join(tempDir.path, 'img.png');
      await createFileWithBytes(pngPath, pngBytes);

      final result = await DocumentUtils.isImage(pngPath);
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('true para JPG/JPEG', () async {
      final tempDir = await Directory.systemTemp.createTemp('doc_utils_img_jpg_');
      final jpgPath = p.join(tempDir.path, 'img.jpg');
      await createFileWithBytes(jpgPath, jpgBytes);

      final result = await DocumentUtils.isImage(jpgPath);
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false para PDF', () async {
      final tempDir = await Directory.systemTemp.createTemp('doc_utils_img_pdf_');
      final pdfPath = p.join(tempDir.path, 'doc.pdf');
      await createFileWithBytes(pdfPath, pdfBytes);

      final result = await DocumentUtils.isImage(pdfPath);
      expect(result, isFalse);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false cuando hay excepción (ruta inexistente)', () async {
      final nonExistent = p.join(Directory.systemTemp.path, 'no_such_image.png');
      final result = await DocumentUtils.isImage(nonExistent);
      expect(result, isFalse);
    });
  });
}
