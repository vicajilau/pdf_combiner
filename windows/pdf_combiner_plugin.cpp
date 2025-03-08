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
#include "include/pdfium/fpdf_edit.h"
#include "include/pdfium/fpdf_save.h"
#include "include/pdfium/fpdf_ppo.h"

#include "include/pdf_combiner/my_file_write.h"
#include "include/pdf_combiner/save_bitmap_to_png.h"

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
        result->Error("INVALID_ARGUMENTS", "Expected a map of arguments.");
        return;
    }
  if (method_call.method_name() == "mergeMultiplePDF") {
      this->merge_multiple_pdfs(*args, std::move(result));
  } else if (method_call.method_name() == "createPDFFromMultipleImage") {
      this->create_pdf_from_multiple_image(*args, std::move(result));
  } else {
      result->NotImplemented();
  }
}

void PdfCombinerPlugin::merge_multiple_pdfs(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

    auto paths_it = args.find(flutter::EncodableValue("paths"));
    auto output_it = args.find(flutter::EncodableValue("outputDirPath"));

    if (paths_it == args.end() || output_it == args.end()) {
        result->Error("invalid_arguments", "Expected a map with inputPaths and outputPath");
        return;
    }

    std::vector<std::string> input_paths;
    if (std::holds_alternative<std::vector<flutter::EncodableValue>>(paths_it->second)) {
        for (const auto& path_value : std::get<std::vector<flutter::EncodableValue>>(paths_it->second)) {
            if (std::holds_alternative<std::string>(path_value)) {
                input_paths.push_back(std::get<std::string>(path_value));
            } else {
                result->Error("invalid_arguments", "Each item in inputPaths must be a string");
                return;
            }
        }
    } else {
        result->Error("invalid_arguments", "inputPaths must be a list of strings");
        return;
    }

    if (!std::holds_alternative<std::string>(output_it->second)) {
        result->Error("invalid_arguments", "outputPath must be a string");
        return;
    }
    std::string output_path = std::get<std::string>(output_it->second);

    FPDF_DOCUMENT new_doc = FPDF_CreateNewDocument();
    if (!new_doc) {
        result->Error("document_creation_failed", "Failed to create new PDF document");
        return;
    }

    int total_pages = 0;

    for (const auto& input_path : input_paths) {
        FPDF_DOCUMENT doc = FPDF_LoadDocument(input_path.c_str(), nullptr);
        if (!doc) {
            FPDF_CloseDocument(new_doc);
            result->Error("document_loading_failed", "Failed to load document: " + input_path);
            return;
        }

        int page_count = FPDF_GetPageCount(doc);

        if (!FPDF_ImportPages(new_doc, doc, nullptr, total_pages)) {
            FPDF_CloseDocument(doc);
            FPDF_CloseDocument(new_doc);
            result->Error("page_import_failed", "Failed to import pages");
            return;
        }

        total_pages += page_count;
        FPDF_CloseDocument(doc);
    }

    MyFileWrite file_write;
    file_write.version = 1;
    file_write.WriteBlock = MyWriteBlock;
    file_write.filename = output_path.c_str();

    if (!FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE*)&file_write, FPDF_INCREMENTAL)) {
        FPDF_CloseDocument(new_doc);
        result->Error("document_save_failed", "Failed to save the new PDF document");
        return;
    }

    FPDF_CloseDocument(new_doc);

    result->Success(flutter::EncodableValue(output_path));
}

void PdfCombinerPlugin::create_pdf_from_multiple_image(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    result->Success(flutter::EncodableValue("Success"));
}

}  // namespace pdf_combiner
