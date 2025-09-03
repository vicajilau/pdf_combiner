import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/pdf_combiner_delegate.dart';
import 'package:pdf_combiner/responses/generate_pdf_from_documents_response.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';
import 'package:pdf_combiner/utils/document_utils.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mock_document_utils.dart';

class PdfCombinerMock with MockPlatformInterfaceMixin implements PdfCombiner {
  static Future<GeneratePdfFromDocumentsResponse> generatePDFFromDocuments({
    required List<String> inputPaths,
    required String outputPath,
    PdfCombinerDelegate? delegate,
  }) async {
    _notifyStartProgress(delegate);
    if (inputPaths.isEmpty) {
      _notifyFinishProgress(delegate);
      delegate?.onError?.call(
          Exception(PdfCombinerMessages.emptyParameterMessage("inputPaths")));
      return GeneratePdfFromDocumentsResponse(
        status: PdfCombinerStatus.error,
        message: PdfCombinerMessages.emptyParameterMessage("inputPaths"),
      );
    } else if (outputPath.trim().isEmpty) {
      _notifyFinishProgress(delegate);
      delegate?.onError?.call(
          Exception(PdfCombinerMessages.emptyParameterMessage("outputPath")));
      return GeneratePdfFromDocumentsResponse(
        status: PdfCombinerStatus.error,
        message: PdfCombinerMessages.emptyParameterMessage("outputPath"),
      );
    } else {
      _notifyCustomProgress(delegate, 0.3);
      final List<String> mutablePaths = List.from(inputPaths);
      for (int i = 0; i < mutablePaths.length; i++) {
        final path = mutablePaths[i];
        final isPDF = await DocumentUtils.isPDF(path);
        final isImage = await DocumentUtils.isImage(path);
        final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);
        if (!outputPathIsPDF) {
          _notifyFinishProgress(delegate);
          delegate?.onError?.call(Exception(
              PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath)));
          return GeneratePdfFromDocumentsResponse(
            status: PdfCombinerStatus.error,
            message:
            PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath),
          );
        } else if (!isPDF && !isImage) {
          _notifyFinishProgress(delegate);
          delegate?.onError
              ?.call(Exception(PdfCombinerMessages.errorMessageMixed(path)));
          return GeneratePdfFromDocumentsResponse(
            status: PdfCombinerStatus.error,
            message: PdfCombinerMessages.errorMessageMixed(path),
          );
        } else {
          _notifyCustomProgress(delegate, 0.5);
          if (isImage) {
            final response = await PdfCombiner.createPDFFromMultipleImages(
              inputPaths: [path],
              outputPath: "${MockDocumentUtils.getTemporalFolderPath()}/result_temp_document.pdf",
            );
            if (response.status == PdfCombinerStatus.success) {
              mutablePaths[i] = response.outputPath;
            } else {
              _notifyFinishProgress(delegate);
              return GeneratePdfFromDocumentsResponse(
                status: PdfCombinerStatus.error,
                message:
                response.message ?? "Error creating PDF from image: $path",
              );
            }
          }
        }
      }
      final response = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: mutablePaths,
        outputPath: outputPath,
        delegate: delegate,
      );
      MockDocumentUtils().removeTemporalFiles(mutablePaths);
      if (response.status == PdfCombinerStatus.success) {
        _notifyFinishProgress(delegate);
        return GeneratePdfFromDocumentsResponse(
          status: PdfCombinerStatus.success,
          message: PdfCombinerMessages.successMessage,
          outputPath: response.outputPath,
        );
      } else {
        _notifyFinishProgress(delegate);
        return GeneratePdfFromDocumentsResponse(
          status: PdfCombinerStatus.error,
          message: response.message,
        );
      }
    }
  }
  static void _notifyCustomProgress(
      PdfCombinerDelegate? delegate, double customProgress) {
    delegate?.onProgress?.call(customProgress);
  }

  static void _notifyStartProgress(PdfCombinerDelegate? delegate) {
    delegate?.onProgress?.call(0.1);
  }

  static void _notifyFinishProgress(PdfCombinerDelegate? delegate) {
    delegate?.onProgress?.call(1.0);
  }
}