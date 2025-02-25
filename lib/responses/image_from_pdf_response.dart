import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

class ImageFromPDFResponse {
  PdfCombinerStatus status;
  String? message;
  List<String> outputPaths;

  ImageFromPDFResponse({
    required this.status,
    this.outputPaths = const [],
    this.message,
  });

  @override
  String toString() =>
      "ImageFromPDFResponse{outputPaths: $outputPaths, message: $message, status: $status }";
}
