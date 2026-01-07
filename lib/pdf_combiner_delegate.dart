/// A delegate class for handling progress, success, and error callbacks
/// during the PDF combination process.
class PdfCombinerDelegate {
  /// Callback triggered when the PDF combination process completes successfully.
  ///
  /// The [outputPaths] list contains the paths of the generated PDF files.
  Function(List<String>)? onSuccess;

  /// Callback triggered when an error occurs during the PDF combination process.
  ///
  /// The [error] parameter provides details about the encountered exception.
  Function(Exception)? onError;

  /// Creates an instance of [PdfCombinerDelegate].
  ///
  /// - [onSuccess] is called upon successful completion.
  /// - [onError] is called when an error occurs.
  PdfCombinerDelegate({this.onSuccess, this.onError});
}
