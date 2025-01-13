import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pdf_combiner_platform_interface.dart';

/// An implementation of [PdfCombinerPlatform] that uses method channels.
class MethodChannelPdfCombiner extends PdfCombinerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pdf_combiner');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
