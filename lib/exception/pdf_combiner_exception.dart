/// Exception class used throughout the PdfCombiner plugin to represent
/// errors that occur during PDF or image processing operations.
///
/// This exception is thrown when:
/// - Input parameters are missing or invalid.
/// - A file does not exist or is of an unsupported type.
/// - A processing error occurs inside platform-specific implementations.
///
/// The [message] property provides a human‑readable description of the error.
class PdfCombinerException implements Exception {
  final String message;

  PdfCombinerException(this.message);
}
