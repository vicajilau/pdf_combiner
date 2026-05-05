import 'dart:typed_data' show Uint8List;

/// An abstract class representing an input for merging PDFs.
///
/// Subclasses must provide the concrete input (path, bytes, url).
abstract class MergeInput {
  const MergeInput();

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

  /// (Removed) Remote URL support was previously provided by `MergeInputUrl`.
  /// This getter is no longer available after the refactor that removed URL inputs.

  /// Returns a user-friendly identifier for logging and error messages.
  /// Without URL inputs, this falls back to the path or a bytes label.
  String get sourceLabel => path ?? 'File in bytes';

  /// Indicates whether this input must be materialized as a temporary resource.
  bool get requiresTemporaryResource => this is! MergeInputPath;

  /// Prefix used when a temporary file must be created for this input.
  String get temporaryFilePrefix => switch (this) {
        MergeInputPath() => 'path_input',
        MergeInputBytes() => 'bytes_input',
        _ => throw StateError('Unsupported MergeInput subtype: $runtimeType'),
      };

  @override
  String toString();
}

/// A [MergeInput] that references a file system path.
class MergeInputPath extends MergeInput {
  @override
  final String path;

  const MergeInputPath(this.path);

  @override
  String toString() => path;
}

/// A [MergeInput] that contains raw bytes.
class MergeInputBytes extends MergeInput {
  @override
  final Uint8List bytes;

  const MergeInputBytes(this.bytes);

  @override
  String toString() => bytes.toString();
}

/// A [MergeInput] that references a remote URL.
// MergeInputUrl removed in refactor: URL-backed inputs are no longer supported.
