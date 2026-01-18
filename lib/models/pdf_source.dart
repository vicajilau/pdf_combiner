import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

/// A PDF source that can be a file path, bytes, or a File object.
class PdfSource {
  final String? path;
  final Uint8List? bytes;
  final File? file;

  const PdfSource._({this.path, this.bytes, this.file})
      : assert(path != null || bytes != null || file != null,
            'Exactly one of `path`, `bytes` of `file` must be provided');

  /// Creates a [PdfSource] from a file path.
  const PdfSource.path(String path) : this._(path: path);

  /// Creates a [PdfSource] from raw bytes.
  const PdfSource.bytes(Uint8List bytes) : this._(bytes: bytes);

  /// Creates a [PdfSource] from a [File] object.
  const PdfSource.file(File file) : this._(file: file);
}
