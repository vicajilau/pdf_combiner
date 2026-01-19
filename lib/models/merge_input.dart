import 'dart:typed_data' show Uint8List;

/// A PDF source that can be a file path, bytes, or a File object.
class MergeInput {
  final String? path;
  final Uint8List? bytes;

  const MergeInput._({this.path, this.bytes})
      : assert(path != null || bytes != null,
            'Exactly one of `path`, `bytes` must be provided');

  /// Creates a [MergeInput] from a file path.
  const MergeInput.path(String path) : this._(path: path);

  /// Creates a [MergeInput] from raw bytes.
  const MergeInput.bytes(Uint8List bytes) : this._(bytes: bytes);
}
