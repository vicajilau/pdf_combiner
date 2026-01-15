import 'dart:typed_data';

/// Represents a source for a PDF document.
/// It can be either a file path or raw bytes.
class PdfSource {
  /// The file path of the PDF.
  final String? path;

  /// The raw bytes of the PDF.
  final Uint8List? bytes;

  const PdfSource._({this.path, this.bytes});

  /// Creates a [PdfSource] from a file path.
  factory PdfSource.fromPath(String path) => PdfSource._(path: path);

  /// Creates a [PdfSource] from raw bytes.
  factory PdfSource.fromBytes(Uint8List bytes) => PdfSource._(bytes: bytes);

  /// Returns true if this source is a file path.
  bool get isPath => path != null;

  /// Returns true if this source is raw bytes.
  bool get isBytes => bytes != null;

  /// Converts this [PdfSource] to a [Map<String, dynamic>] for platform channel communication.
  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'bytes': bytes,
    };
  }

  @override
  String toString() {
    if (isPath) return 'PdfSource(path: $path)';
    if (isBytes) return 'PdfSource(bytes: ${bytes!.length} bytes)';
    return 'PdfSource(empty)';
  }
}
