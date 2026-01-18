import 'dart:typed_data';

/// A unified model representing an input for PDF operations.
///
/// This abstract base class serves as a polymorphic wrapper for different types
/// of inputs that can be processed by the [PdfCombiner], such as file paths
/// or raw byte data.
///
/// By using [MergeInput], the API provides a consistent interface regardless
/// of the underlying data source, allowing for greater flexibility and type safety.
///
/// See also:
/// * [MergeInputPath] for inputs based on file system paths.
/// * [MergeInputBytes] for inputs based on in-memory byte arrays.
abstract class MergeInput {
  /// Constant constructor to allow subclass constructors to be constant.
  const MergeInput();
}

/// A generic input type representing a file path.
///
/// This class is used when the source document (PDF or image) exists as a file
/// on the local device's storage. It wraps the absolute path to the file.
///
/// Example:
/// ```dart
/// final input = MergeInputPath('/storage/emulated/0/Download/document.pdf');
/// ```
///
/// **Note:** Ensure that the path is valid and accessible by the application.
class MergeInputPath extends MergeInput {
  /// The absolute file path to the input document.
  final String path;

  /// Creates a new [MergeInputPath] instance with the specified [path].
  const MergeInputPath(this.path);
}

/// A generic input type representing raw byte data.
///
/// This class is useful when the document data is available in memory, for example,
/// downloaded from a network request, generated dynamically, or selected from
/// a platform picker that returns bytes instead of a path (e.g., on Web).
///
/// The [bytes] are expected to be the raw content of a valid PDF or image file
/// (e.g., PNG, JPEG).
///
/// Example:
/// ```dart
/// final Uint8List data = ...; // Bytes from API or file picker
/// final input = MergeInputBytes(data);
/// ```
class MergeInputBytes extends MergeInput {
  /// The raw byte data of the document (PDF or Image).
  final Uint8List bytes;

  /// Creates a new [MergeInputBytes] instance with the specified [bytes].
  const MergeInputBytes(this.bytes);
}
