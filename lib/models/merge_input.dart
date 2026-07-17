import 'dart:typed_data' show Uint8List;

/// An enum representing the type of input for merging PDFs.
enum MergeInputType {
  path,
  bytes,
  url,
}

/// A class representing an input for merging PDFs.
///
/// It can be created from a file path, a byte array, or a URL.
class MergeInput {
  final String? path;
  final Uint8List? bytes;
  final String? url;
  final MergeInputType type;

  const MergeInput(this.type, {this.path, this.bytes, this.url})
      : assert((type == MergeInputType.path &&
                path != null &&
                bytes == null &&
                url == null) ||
            (type == MergeInputType.bytes &&
                bytes != null &&
                path == null &&
                url == null) ||
            (type == MergeInputType.url &&
                url != null &&
                path == null &&
                bytes == null));

  /// Creates a [MergeInput] from a file path.
  factory MergeInput.path(String path) =>
      MergeInput(MergeInputType.path, path: path);

  /// Creates a [MergeInput] from a byte array.
  factory MergeInput.bytes(Uint8List bytes) =>
      MergeInput(MergeInputType.bytes, bytes: bytes);

  /// Creates a [MergeInput] from a URL.
  factory MergeInput.url(String url) =>
      MergeInput(MergeInputType.url, url: url);

  @override
  String toString() {
    switch (type) {
      case MergeInputType.path:
        return path!;
      case MergeInputType.bytes:
        return bytes!.toString();
      case MergeInputType.url:
        return url!;
    }
  }
}
