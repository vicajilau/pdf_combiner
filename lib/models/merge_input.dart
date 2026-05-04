import 'dart:typed_data' show Uint8List;

/// An enum representing the type of input for merging PDFs.
enum MergeInputType {
  path,
  bytes,
  url,
}

/// An abstract class representing an input for merging PDFs.
///
/// Subclasses must provide the concrete input (path, bytes, url).
abstract class MergeInput {
  final MergeInputType type;

  const MergeInput(this.type);

  /// Factory helpers for convenience and backwards compatibility.
  factory MergeInput.path(String path) => MergeInputPath(path);
  factory MergeInput.bytes(Uint8List bytes) => MergeInputBytes(bytes);
  factory MergeInput.url(String url) => MergeInputUrl(url);

  /// Returns the local path when this input is backed by a file path.
  String? get path => switch (this) {
        MergeInputPath(:final path) => path,
        _ => null,
      };

  /// Returns the in-memory bytes when this input is backed by raw bytes.
  Uint8List? get bytes => switch (this) {
        MergeInputBytes(:final bytes) => bytes,
        _ => null,
      };

  /// Returns the remote URL when this input is backed by a URL.
  String? get url => switch (this) {
        MergeInputUrl(:final url) => url,
        _ => null,
      };

  /// Returns a user-friendly identifier for logging and error messages.
  String get sourceLabel => path ?? url ?? 'File in bytes';

  @override
  String toString();
}

/// A [MergeInput] that references a file system path.
class MergeInputPath extends MergeInput {
  @override
  final String path;

  MergeInputPath(this.path) : super(MergeInputType.path);

  @override
  String toString() => path;
}

/// A [MergeInput] that contains raw bytes.
class MergeInputBytes extends MergeInput {
  @override
  final Uint8List bytes;

  MergeInputBytes(this.bytes) : super(MergeInputType.bytes);

  @override
  String toString() => bytes.toString();
}

/// A [MergeInput] that references a remote URL.
class MergeInputUrl extends MergeInput {
  @override
  final String url;

  MergeInputUrl(this.url) : super(MergeInputType.url);

  @override
  String toString() => url;
}
