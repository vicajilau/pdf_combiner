/// Represents the status of operations related to PDF and image processing.
///
/// This enum is used generically across three main functions:
/// - Merging multiple PDFs.
/// - Creating an image from a PDF.
/// - Creating a PDF from multiple images.
enum PdfCombinerStatus {
  /// Indicates that no operation has started or there is no input.
  empty,

  /// Indicates that the operation completed successfully.
  success,

  /// Indicates that an error occurred during the operation.
  error,

  /// Indicates that the operation is currently in progress.
  processing,

  /// Represents an undefined or unrecognized status.
  unknown;

  /// Converts a [string] into a corresponding [PdfCombinerStatus] value.
  ///
  /// If the string matches one of the predefined statuses (`empty`, `success`,
  /// `error`, `processing`), the corresponding enum value is returned.
  /// Otherwise, it returns [PdfCombinerStatus.unknown].
  ///
  /// This method allows for easy mapping of string-based statuses to
  /// the [PdfCombinerStatus] enum.
  ///
  /// Example:
  /// ```dart
  /// var status = PdfCombinerStatus.from("success");
  /// // status == PdfCombinerStatus.success
  /// ```
  static PdfCombinerStatus from(String string) {
    switch (string) {
      case "empty":
        return PdfCombinerStatus.empty;
      case "success":
        return PdfCombinerStatus.success;
      case "error":
        return PdfCombinerStatus.error;
      case "processing":
        return PdfCombinerStatus.processing;
      default:
        return PdfCombinerStatus.unknown;
    }
  }
}
