#ifndef FLUTTER_PLUGIN_PDF_COMBINER_PLUGIN_H_
#define FLUTTER_PLUGIN_PDF_COMBINER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

namespace pdf_combiner {

class PdfCombinerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  PdfCombinerPlugin();

  virtual ~PdfCombinerPlugin();

  // Disallow copy and assign.
  PdfCombinerPlugin(const PdfCombinerPlugin&) = delete;
  PdfCombinerPlugin& operator=(const PdfCombinerPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void merge_multiple_pdfs(const flutter::EncodableMap& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

};

}  // namespace pdf_combiner

#endif  // FLUTTER_PLUGIN_PDF_COMBINER_PLUGIN_H_
