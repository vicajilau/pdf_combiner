import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pdf_combiner_method_channel.dart';

abstract class PdfCombinerPlatform extends PlatformInterface {
  /// Constructs a PdfCombinerPlatform.
  PdfCombinerPlatform() : super(token: _token);

  static final Object _token = Object();

  static PdfCombinerPlatform _instance = MethodChannelPdfCombiner();

  /// The default instance of [PdfCombinerPlatform] to use.
  ///
  /// Defaults to [MethodChannelPdfCombiner].
  static PdfCombinerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PdfCombinerPlatform] when
  /// they register themselves.
  static set instance(PdfCombinerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
