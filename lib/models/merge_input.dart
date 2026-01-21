import 'dart:typed_data' show Uint8List;

import 'package:pdf_combiner/models/merge_input_type.dart';

/// A class representing an input for merging PDFs.
///
/// It can be created from a file path or a byte array.
class MergeInput {
  final String? path;
  final Uint8List? bytes;
  final MergeInputType type;

  const MergeInput(this.type, {this.path, this.bytes})
      : assert((path != null) != (bytes != null));

  /// Creates a [MergeInput] from a file path.
  factory MergeInput.path(String path) =>
      MergeInput(MergeInputType.path, path: path);

  /// Creates a [MergeInput] from a byte array.
  factory MergeInput.bytes(Uint8List bytes) =>
      MergeInput(MergeInputType.bytes, bytes: bytes);

  @override
  String toString() {
    switch (type) {
      case MergeInputType.path:
        return path!;
      case MergeInputType.bytes:
        return bytes!.toString();
    }
  }
}
