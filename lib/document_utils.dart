import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web/helpers.dart';

class DocumentUtils {
  /// Checks if string is an pdf file.
  static bool isPDF(String filePath) {
    return kIsWeb || filePath.toLowerCase().endsWith(".pdf");
  }

  /// get a blob object from url
  Future<Blob?> fetchBlobFromUrl(String blobUrl) async {
    try {
      final response = await HttpRequest.request(
        blobUrl,
        responseType: 'blob',
      );
      return response.response as Blob?;
    } catch (e) {
      return null;
    }
  }

  /// Convert a `Blob` into `Uint8List`
  Future<Uint8List> blobToBytes(Blob blob) async {
    final reader = FileReader();
    final completer = Completer<Uint8List>();

    reader.onLoadEnd.listen((_) {
      completer.complete(Uint8List.view((reader.result as ByteBuffer)));
    });

    reader.readAsArrayBuffer(blob);
    return completer.future;
  }

  /// Detect if a blob its an image for the "magic numbers" method
  bool isImageBlob(Uint8List bytes) {
    if (bytes.length < 4) return false;

    final List<List<int>> imageSignatures = [
      [0x89, 0x50, 0x4E, 0x47], // PNG
      [0xFF, 0xD8, 0xFF],       // JPEG
      [0x47, 0x49, 0x46, 0x38], // GIF
      [0x52, 0x49, 0x46, 0x46], // WEBP
    ];

    for (var signature in imageSignatures) {
      if (bytes.length >= signature.length &&
          List.generate(signature.length, (i) => bytes[i])
              .every((b) => signature.contains(b))) {
        return true;
      }
    }

    return false;
  }

  /// Detect if a blob its an image
  Future<bool> detectIfBlobUrlIsImage(String blobUrl) async {
    Blob? blob = await fetchBlobFromUrl(blobUrl);
    if (blob == null) {
      return false;
    }

    try {
      Uint8List bytes = await blobToBytes(blob);
      bool isImg = isImageBlob(bytes);
      return isImg;
    } catch (e) {
      return false;
    }
  }
  /// Checks if string is an image file.
  Future<bool> isImage(String filePath) async {
    if(kIsWeb) return await detectIfBlobUrlIsImage(filePath);

    final ext = filePath.toLowerCase();

    // If the file has no extension, it is assumed to be a possible image.
    if (!ext.contains(".")) {
      return true;
    }

    return ext.endsWith(".jpg") ||
        ext.endsWith(".jpeg") ||
        ext.endsWith(".png") ||
        ext.endsWith(".gif") ||
        ext.endsWith(".bmp");
  }

  /// Checks if string is an existing file.
  static bool fileExist(String filePath) => kIsWeb || io.File(filePath).existsSync();
}
