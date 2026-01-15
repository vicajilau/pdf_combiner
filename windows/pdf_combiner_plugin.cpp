#include "pdf_combiner_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

#include "include/pdfium/fpdf_edit.h"
#include "include/pdfium/fpdf_ppo.h"
#include "include/pdfium/fpdf_save.h"
#include "include/pdfium/fpdfview.h"

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
  const flutter::EncodableValue *dart_arguments = method_call.arguments();
  auto args = std::get_if<flutter::EncodableMap>(dart_arguments);
  if (!args) {
    result->Error("INVALID_ARGUMENTS", "Expected a map of arguments.");
    return;
  }
  if (method_call.method_name() == "mergeMultiplePDF") {
    this->merge_multiple_pdfs(*args, std::move(result));
  } else if (method_call.method_name() == "createPDFFromMultipleImage") {
    this->create_pdf_from_multiple_image(*args, std::move(result));
  } else if (method_call.method_name() == "createImageFromPDF") {
    this->create_image_from_pdf(*args, std::move(result));
  } else {
    result->NotImplemented();
  }
}

void PdfCombinerPlugin::merge_multiple_pdfs(
    const flutter::EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  auto paths_it = args.find(flutter::EncodableValue("paths"));
  auto output_it = args.find(flutter::EncodableValue("outputDirPath"));

  if (paths_it == args.end() || output_it == args.end()) {
    result->Error("invalid_arguments",
                  "Expected a map with sources and outputPath");
    return;
  }

  std::vector<std::string> input_paths;
  if (std::holds_alternative<std::vector<flutter::EncodableValue>>(
          paths_it->second)) {
    for (const auto &path_value :
         std::get<std::vector<flutter::EncodableValue>>(paths_it->second)) {
      if (std::holds_alternative<std::string>(path_value)) {
        input_paths.push_back(std::get<std::string>(path_value));
      } else {
        result->Error("invalid_arguments",
                      "Each item in inputPaths must be a string");
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
    result->Error("document_creation_failed",
                  "Failed to create new PDF document");
    return;
  }

  int total_pages = 0;

  for (const auto &input_path : input_paths) {
    FPDF_DOCUMENT doc = FPDF_LoadDocument(input_path.c_str(), nullptr);
    if (!doc) {
      FPDF_CloseDocument(new_doc);
      result->Error("document_loading_failed",
                    "Failed to load document: " + input_path);
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

  if (!FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE *)&file_write,
                       FPDF_INCREMENTAL)) {
    FPDF_CloseDocument(new_doc);
    result->Error("document_save_failed",
                  "Failed to save the new PDF document");
    return;
  }

  FPDF_CloseDocument(new_doc);

  result->Success(flutter::EncodableValue(output_path));
}

void PdfCombinerPlugin::create_pdf_from_multiple_image(
    const flutter::EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  auto paths_it = args.find(flutter::EncodableValue("paths"));
  auto output_it = args.find(flutter::EncodableValue("outputDirPath"));
  auto width_it = args.find(flutter::EncodableValue("width"));
  auto height_it = args.find(flutter::EncodableValue("height"));
  auto keep_aspect_ratio_it =
      args.find(flutter::EncodableValue("keepAspectRatio"));

  if (paths_it == args.end() || output_it == args.end() ||
      width_it == args.end() || height_it == args.end() ||
      keep_aspect_ratio_it == args.end()) {
    result->Error("invalid_arguments",
                  "Expected a map with paths, outputDirPath, width, height, "
                  "and keepAspectRatio");
    return;
  }

  std::vector<std::string> input_paths;
  if (std::holds_alternative<std::vector<flutter::EncodableValue>>(
          paths_it->second)) {
    for (const auto &path_value :
         std::get<std::vector<flutter::EncodableValue>>(paths_it->second)) {
      if (std::holds_alternative<std::string>(path_value)) {
        input_paths.push_back(std::get<std::string>(path_value));
      } else {
        result->Error("invalid_arguments",
                      "Each item in paths must be a string");
        return;
      }
    }
  } else {
    result->Error("invalid_arguments", "paths must be a list of strings");
    return;
  }

  if (!std::holds_alternative<std::string>(output_it->second)) {
    result->Error("invalid_arguments", "outputDirPath must be a string");
    return;
  }
  std::string output_path = std::get<std::string>(output_it->second);

  int max_width = std::get<int>(width_it->second);
  int max_height = std::get<int>(height_it->second);
  bool keep_aspect_ratio = std::get<bool>(keep_aspect_ratio_it->second);

  // Create an empty document
  FPDF_DOCUMENT new_doc = FPDF_CreateNewDocument();
  if (!new_doc) {
    result->Error("document_creation_failed",
                  "Failed to create new PDF document");
    return;
  }

  // Process each image file in input_paths
  for (const auto &input_path : input_paths) {
    // Load the image and get its dimensions
    int width, height, channels;
    unsigned char *image_data =
        stbi_load(input_path.c_str(), &width, &height, &channels, 4);
    if (!image_data) {
      FPDF_CloseDocument(new_doc);
      result->Error("image_loading_failed",
                    ("Failed to load image: " + input_path).c_str());
      return;
    }

    // Resize the image if necessary
    if (max_width != 0 || max_height != 0) {
      int new_width = width;
      int new_height = height;

      if (max_width != 0) {
        new_width = max_width;
      }

      if (max_height != 0) {
        if (keep_aspect_ratio) {
          double aspectRatio = static_cast<double>(height) / width;
          new_height = static_cast<int>(max_width * aspectRatio);
        } else {
          new_height = max_height;
        }
      }

      unsigned char *resized_image_data =
          new unsigned char[new_width * new_height * 4];

      if (!stbir_resize_uint8_linear(image_data, width, height, 0,
                                     resized_image_data, new_width, new_height,
                                     0, STBIR_RGBA)) {
        stbi_image_free(image_data);
        FPDF_CloseDocument(new_doc);
        result->Error("image_resize_failed", "Failed to resize image");
        return;
      }

      // Free only the original image, not the resized one
      stbi_image_free(image_data);

      // Assigning the new values
      image_data = resized_image_data;
      width = new_width;
      height = new_height;
    }

    FPDF_PAGE new_page =
        FPDFPage_New(new_doc, FPDF_GetPageCount(new_doc), width, height);
    if (!new_page) {
      stbi_image_free(image_data);
      FPDF_CloseDocument(new_doc);
      result->Error("page_creation_failed",
                    ("Failed to create page for image: " + input_path).c_str());
      return;
    }

    // Crate bitmap of the image
    FPDF_BITMAP bitmap = FPDFBitmap_Create(width, height, 0);
    FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xFFFFFFFF);
    unsigned char *bitmap_buffer =
        (unsigned char *)FPDFBitmap_GetBuffer(bitmap);
    int stride = FPDFBitmap_GetStride(bitmap);

    for (int y = 0; y < height; y++) {
      unsigned char *src_row = image_data + y * width * 4;
      unsigned char *dst_row = bitmap_buffer + (height - 1 - y) * stride;

      for (int x = 0; x < width; x++) {
        dst_row[x * 4 + 0] = src_row[x * 4 + 2]; // Blue  <- Red
        dst_row[x * 4 + 1] = src_row[x * 4 + 1]; // Green <- Green
        dst_row[x * 4 + 2] = src_row[x * 4 + 0]; // Red   <- Blue
        dst_row[x * 4 + 3] = src_row[x * 4 + 3]; // Alpha <- Alpha
      }
    }

    FPDF_PAGEOBJECT image_obj = FPDFPageObj_NewImageObj(new_doc);
    if (!image_obj) {
      stbi_image_free(image_data);
      FPDF_CloseDocument(new_doc);
      result->Error(
          "image_object_creation_failed",
          ("Failed to create image object for: " + input_path).c_str());
      return;
    }

    FPDFImageObj_SetBitmap(&new_page, 1, image_obj, bitmap);
    FPDFImageObj_SetMatrix(image_obj, width, 0, 0, -height, 0, height);
    FPDFPage_InsertObject(new_page, image_obj);
    FPDFPage_GenerateContent(new_page);

    stbi_image_free(image_data);
    FPDFBitmap_Destroy(bitmap);
  }

  MyFileWrite file_write;
  file_write.version = 1;
  file_write.WriteBlock = MyWriteBlock;
  file_write.filename = output_path.c_str();

  // Save the new document
  if (!FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE *)&file_write,
                       FPDF_NO_INCREMENTAL)) {
    FPDF_CloseDocument(new_doc);
    result->Error("document_save_failed",
                  "Failed to save the new PDF document");
    return;
  }

  // Close the new document
  FPDF_CloseDocument(new_doc);

  // Return success response with the output path
  result->Success(flutter::EncodableValue(output_path));
}

void PdfCombinerPlugin::create_image_from_pdf(
    const flutter::EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  // Verify arguments
  if (args.find(flutter::EncodableValue("path")) == args.end() ||
      args.find(flutter::EncodableValue("outputDirPath")) == args.end() ||
      args.find(flutter::EncodableValue("width")) == args.end() ||
      args.find(flutter::EncodableValue("height")) == args.end() ||
      args.find(flutter::EncodableValue("compression")) == args.end() ||
      args.find(flutter::EncodableValue("createOneImage")) == args.end()) {
    result->Error("invalid_arguments",
                  "Expected a map with inputPath, outputDirPath, width, "
                  "height, compression and createOneImage keys");
    return;
  }

  // Get params from the map
  std::string input_path =
      std::get<std::string>(args.at(flutter::EncodableValue("path")));
  std::string output_path =
      std::get<std::string>(args.at(flutter::EncodableValue("outputDirPath")));

  // Get width (String)
  int max_width = std::get<int>(args.at(flutter::EncodableValue("width")));

  // Get height (String)
  int max_height = std::get<int>(args.at(flutter::EncodableValue("height")));

  // Get compression (String)
  int compression =
      std::get<int>(args.at(flutter::EncodableValue("compression")));

  // Get createOneImage (Bool)
  bool create_one_image =
      std::get<bool>(args.at(flutter::EncodableValue("createOneImage")));

  // Load PDF Document
  FPDF_DOCUMENT doc = FPDF_LoadDocument(input_path.c_str(), nullptr);
  if (!doc) {
    result->Error("document_loading_failed", "Failed to load PDF document");
    return;
  }

  int page_count = FPDF_GetPageCount(doc);
  if (page_count < 1) {
    FPDF_CloseDocument(doc);
    result->Error("empty_pdf", "The PDF document is empty");
    return;
  }

  std::vector<flutter::EncodableValue> image_paths;

  if (create_one_image) {
    int total_width = 0;
    int total_height = 0;

    // First, calculate the total width and height for the combined image
    std::vector<FPDF_PAGE> pages(page_count);
    std::vector<double> page_widths(page_count);
    std::vector<double> page_heights(page_count);

    for (int i = 0; i < page_count; ++i) {
      FPDF_PAGE page = FPDF_LoadPage(doc, i);
      if (!page)
        continue;

      // Get the size of the page
      double width = FPDF_GetPageWidth(page);
      double height = FPDF_GetPageHeight(page);

      if (max_width != 0 || max_height != 0) {
        width = (double)max_width;
        height = (double)max_height;
      }

      pages[i] = page;
      page_widths[i] = width;
      page_heights[i] = height;

      total_width = total_width; // Use the max width
      if ((int)width > total_width) {
        total_width = (int)width;
      }
      total_height += (int)height; // Sum the heights for vertical layout
    }

    // Create a bitmap large enough to hold all pages vertically
    FPDF_BITMAP combined_bitmap =
        FPDFBitmap_Create(total_width, total_height, 0xFFFFFFFF);
    if (!combined_bitmap) {
      FPDF_CloseDocument(doc);
      result->Error("bitmap_creation_failed",
                    "Failed to create combined bitmap");
      return;
    }

    int current_y = 0;

    // Render each page into the large combined image
    for (int i = 0; i < page_count; ++i) {
      FPDF_PAGE page = pages[i];

      // Render the page into the combined bitmap at the correct position
      FPDF_RenderPageBitmap(combined_bitmap, page, 0, current_y,
                            (int)page_widths[i], (int)page_heights[i], 0,
                            FPDF_ANNOT);
      current_y +=
          (int)page_heights[i]; // Move the y position down for the next page
    }

    // Save the combined bitmap to a PNG file
    std::string output_image_path = std::string(output_path) + "/image.png";
    if (!save_bitmap_to_png(combined_bitmap, output_image_path, compression)) {
      FPDFBitmap_Destroy(combined_bitmap);
      FPDF_CloseDocument(doc);
      result->Error("image_save_failed", "Failed to save combined image");
      return;
    }

    // Add the combined image path to the result list
    image_paths.push_back(flutter::EncodableValue(output_image_path));

    // Clean up resources
    FPDFBitmap_Destroy(combined_bitmap);
    for (int i = 0; i < page_count; ++i) {
      FPDF_ClosePage(pages[i]);
    }
  } else {
    for (int i = 0; i < page_count; ++i) {
      FPDF_PAGE page = FPDF_LoadPage(doc, i);
      if (!page)
        continue;

      int width, height;
      if (max_width != 0 || max_height != 0) {
        width = max_width;
        height = max_height;
      } else {
        // Get the size of the page
        width = (int)FPDF_GetPageWidth(page);
        height = (int)FPDF_GetPageHeight(page);
      }

      // Create a bitmap of the appropriate size
      FPDF_BITMAP bitmap = FPDFBitmap_Create(width, height, 0xFFFFFFFF);
      if (!bitmap) {
        FPDF_ClosePage(page);
        FPDF_CloseDocument(doc);
        result->Error("bitmap_creation_failed", "Failed to create bitmap");
        return;
      }

      // Render the page into the bitmap
      FPDF_RenderPageBitmap(bitmap, page, 0, 0, (int)width, (int)height, 0,
                            FPDF_ANNOT);

      // Save the bitmap to a PNG file
      std::string output_image_path =
          std::string(output_path) + "/image_" + std::to_string(i + 1) + ".png";
      if (!save_bitmap_to_png(bitmap, output_image_path, compression)) {
        FPDF_ClosePage(page);
        FPDF_CloseDocument(doc);
        result->Error("image_save_failed", "Failed to save image");
        return;
      }

      // Add the image path to the result list
      image_paths.push_back(flutter::EncodableValue(output_image_path));

      // Clean resources
      FPDFBitmap_Destroy(bitmap);
      FPDF_ClosePage(page);
    }
  }

  FPDF_CloseDocument(doc);

  result->Success(flutter::EncodableValue(image_paths));
}

} // namespace pdf_combiner
