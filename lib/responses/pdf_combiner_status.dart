/// Represents the status of operations related to PDF and image processing.
///
/// This enum is used generically across four main functions:
/// - Combining multiple files into a single PDF.
/// - Merging multiple PDFs.
/// - Creating an image from a PDF.
/// - Creating a PDF from multiple images.
enum PdfCombinerStatus {
  /// Indicates that the operation completed successfully.
  success,

  /// Indicates that an error occurred during the operation.
  error;

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
    if (string == "success") {
      return PdfCombinerStatus.success;
    } else {
      return PdfCombinerStatus.error;
    }
  }
}
