#include "pdf_combiner_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

#include "include/pdfium/fpdfview.h"

namespace pdf_combiner {

// static
void PdfCombinerPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "pdf_combiner",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<PdfCombinerPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

PdfCombinerPlugin::PdfCombinerPlugin() {
    FPDF_InitLibrary(); // Initialize the FPDF library
}

PdfCombinerPlugin::~PdfCombinerPlugin() {
    FPDF_DestroyLibrary(); // Destroy the FPDF library
}

void PdfCombinerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const flutter::EncodableValue* dart_arguments = method_call.arguments();
    auto args = std::get_if<flutter::EncodableMap>(dart_arguments);
    if (!args) {
        // args is nullptr
        result->Error("INVALID_ARGUMENTS", "Expected a map of arguments.");
        return;
    }
  if (method_call.method_name() == "mergeMultiplePDF") {
      this->merge_multiple_pdfs(*args, std::move(result));
  } else {
      result->NotImplemented();
  }
}

void PdfCombinerPlugin::merge_multiple_pdfs(const flutter::EncodableMap& args,
                         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    result->Success(flutter::EncodableValue("Success"));
}

}  // namespace pdf_combiner
