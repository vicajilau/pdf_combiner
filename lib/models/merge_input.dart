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
sealed class MergeInput {
  const MergeInput();

  /// Creates a [MergeInput] from a file path.
  factory MergeInput.path(String path) = PathMergeInput;

  /// Creates a [MergeInput] from a byte array.
  factory MergeInput.bytes(Uint8List bytes) = BytesMergeInput;

  /// Creates a [MergeInput] from a URL.
  factory MergeInput.url(String url) = UrlMergeInput;

  /// Gets the type of input.
  MergeInputType get type;

  /// The file path, if this input is created from a path.
  String? get path => null;

  /// The byte array, if this input is created from bytes.
  Uint8List? get bytes => null;

  /// The URL, if this input is created from a URL.
  String? get url => null;
}

/// A [MergeInput] representing a file path.
class PathMergeInput extends MergeInput {
  @override
  final String path;

  const PathMergeInput(this.path);

  @override
  MergeInputType get type => MergeInputType.path;

  @override
  String toString() => path;
}

/// A [MergeInput] representing a byte array.
class BytesMergeInput extends MergeInput {
  @override
  final Uint8List bytes;

  const BytesMergeInput(this.bytes);

  @override
  MergeInputType get type => MergeInputType.bytes;

  @override
  String toString() => bytes.toString();
}

/// A [MergeInput] representing a URL.
class UrlMergeInput extends MergeInput {
  @override
  final String url;

  const UrlMergeInput(this.url);

  @override
  MergeInputType get type => MergeInputType.url;

  @override
  String toString() => url;
}
