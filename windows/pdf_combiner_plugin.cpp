#include "pdf_combiner_plugin.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <windows.h>
#include <shlwapi.h>
#include <objbase.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <algorithm>
#include <vector>
#include <iomanip>
#include <fstream>

#include "include/pdfium/fpdfview.h"
#include "include/pdfium/fpdf_edit.h"
#include "include/pdfium/fpdf_save.h"
#include "include/pdfium/fpdf_ppo.h"

#include "include/pdf_combiner/my_file_write.h"
#include "include/pdf_combiner/save_bitmap_to_png.h"

#include "include/pdf_combiner/stb_image.h"
#include "include/pdf_combiner/stb_image_resize2.h"
#include "include/pdf_combiner/stb_image_write.h"

#ifdef HAS_HEIF
#include <libheif/heif.h>
#endif

#pragma comment(lib, "shlwapi.lib")

namespace pdf_combiner {

    int MyWriteBlock(struct FPDF_FILEWRITE_* pThis, const void* pData, unsigned long size) {
        MyFileWrite* pMe = (MyFileWrite*)pThis;
        if (!pMe || !pData) return 0;
        if (!pMe->file) {
            if (fopen_s(&pMe->file, pMe->filename, "wb") != 0 || !pMe->file) return 0;
        }
        size_t written = fwrite(pData, 1, size, pMe->file);
        return (written == size) ? 1 : 0;
    }

    std::string ProcessHeic(const std::string& path) {
        heif_context* ctx = heif_context_alloc();
        heif_error err = heif_context_read_from_file(ctx, path.c_str(), nullptr);
        if (err.code != heif_error_Ok) { heif_context_free(ctx); return ""; }

        heif_image_handle* handle = nullptr;
        err = heif_context_get_primary_image_handle(ctx, &handle);
        if (err.code != heif_error_Ok) { heif_context_free(ctx); return ""; }

        heif_image* img = nullptr;
        err = heif_decode_image(handle, &img, heif_colorspace_RGB, heif_chroma_interleaved_RGB, nullptr);
        if (err.code != heif_error_Ok) {
            heif_image_handle_release(handle);
            heif_context_free(ctx);
            return "";
        }

        int width = heif_image_get_width(img, heif_channel_interleaved);
        int height = heif_image_get_height(img, heif_channel_interleaved);
        int stride;
        const uint8_t* data = heif_image_get_plane_readonly(img, heif_channel_interleaved, &stride);

        std::string out_jpg = path + ".tmp.jpg";
        int success = stbi_write_jpg(out_jpg.c_str(), width, height, 3, data, 85);

        heif_image_release(img);
        heif_image_handle_release(handle);
        heif_context_free(ctx);
        return success ? out_jpg : "";
    }

    void PdfCombinerPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar) {
        auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
                registrar->messenger(), "pdf_combiner", &flutter::StandardMethodCodec::GetInstance());
        auto plugin = std::make_unique<PdfCombinerPlugin>();
        channel->SetMethodCallHandler([plugin_pointer = plugin.get()](const auto &call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });
        registrar->AddPlugin(std::move(plugin));
    }

    PdfCombinerPlugin::PdfCombinerPlugin() { FPDF_InitLibrary(); }
    PdfCombinerPlugin::~PdfCombinerPlugin() { FPDF_DestroyLibrary(); }

    void PdfCombinerPlugin::HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue> &method_call,
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
        } else if (method_call.method_name() == "createImageFromPDF") {
            this->create_image_from_pdf(*args, std::move(result));
        } else {
            result->NotImplemented();
        }
    }

    void PdfCombinerPlugin::merge_multiple_pdfs(const flutter::EncodableMap& args,
                                                std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        auto paths_it = args.find(flutter::EncodableValue("paths"));
        auto output_it = args.find(flutter::EncodableValue("outputDirPath"));
        std::vector<std::string> input_paths;
        if (paths_it != args.end() && std::holds_alternative<std::vector<flutter::EncodableValue>>(paths_it->second)) {
            for (const auto& path_value : std::get<std::vector<flutter::EncodableValue>>(paths_it->second)) {
                if (std::holds_alternative<std::string>(path_value)) input_paths.push_back(std::get<std::string>(path_value));
            }
        }
        std::string output_path = std::get<std::string>(output_it->second);
        FPDF_DOCUMENT new_doc = FPDF_CreateNewDocument();
        int total_pages = 0;
        for (const auto& input_path : input_paths) {
            FPDF_DOCUMENT doc = FPDF_LoadDocument(input_path.c_str(), nullptr);
            if (!doc) continue;
            int page_count = FPDF_GetPageCount(doc);
            FPDF_ImportPages(new_doc, doc, nullptr, total_pages);
            total_pages += page_count;
            FPDF_CloseDocument(doc);
        }
        MyFileWrite file_write;
        file_write.version = 1;
        file_write.WriteBlock = MyWriteBlock;
        file_write.filename = output_path.c_str();
        file_write.file = nullptr;
        FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE*)&file_write, FPDF_NO_INCREMENTAL);
        if (file_write.file) fclose(file_write.file);
        FPDF_CloseDocument(new_doc);
        result->Success(flutter::EncodableValue(output_path));
    }

    void PdfCombinerPlugin::create_pdf_from_multiple_image(const flutter::EncodableMap& args,
                                                           std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        auto paths_it = args.find(flutter::EncodableValue("paths"));
        auto output_it = args.find(flutter::EncodableValue("outputDirPath"));
        auto width_it = args.find(flutter::EncodableValue("width"));
        auto height_it = args.find(flutter::EncodableValue("height"));
        auto keep_aspect_ratio_it = args.find(flutter::EncodableValue("keepAspectRatio"));
        
        std::vector<std::string> input_paths;
        const auto& path_list = std::get<std::vector<flutter::EncodableValue>>(paths_it->second);
        for (const auto& path_value : path_list) input_paths.push_back(std::get<std::string>(path_value));
        
        std::string output_path = std::get<std::string>(output_it->second);
        int max_width = std::get<int>(width_it->second);
        int max_height = std::get<int>(height_it->second);
        bool keep_aspect_ratio = std::get<bool>(keep_aspect_ratio_it->second);
        
        FPDF_DOCUMENT new_doc = FPDF_CreateNewDocument();

        for (const auto& path : input_paths) {
            std::string current_path = path;
            bool is_temp = false;
            
            // Determine if it's an image that needs conversion or resizing
            bool is_heic = (path.find(".heic") != std::string::npos || path.find(".HEIC") != std::string::npos ||
                           path.find(".heif") != std::string::npos || path.find(".HEIF") != std::string::npos);
            
            bool is_jpg = (path.find(".jpg") != std::string::npos || path.find(".JPG") != std::string::npos ||
                           path.find(".jpeg") != std::string::npos || path.find(".JPEG") != std::string::npos);

            if (is_heic) {
                current_path = ProcessHeic(path);
                if (current_path.empty()) continue;
                is_temp = true;
                is_jpg = true; // ProcessHeic result is now a temporary JPG
            }

            int w, h, c;
            // If we need to resize, load the image, process it and save a temporary JPG
            if (max_width != 0 || max_height != 0) {
                unsigned char* pixels = stbi_load(current_path.c_str(), &w, &h, &c, 3);
                if (pixels) {
                    int new_width = (max_width != 0) ? max_width : w;
                    int new_height = (max_height != 0) ? (keep_aspect_ratio ? static_cast<int>(max_width * (static_cast<double>(h) / w)) : max_height) : h;
                    unsigned char* resized_data = (unsigned char*)malloc(new_width * new_height * 3);
                    if (resized_data && stbir_resize_uint8_linear(pixels, w, h, 0, resized_data, new_width, new_height, 0, STBIR_RGB)) {
                        std::string resized_path = path + ".resized.jpg";
                        if (stbi_write_jpg(resized_path.c_str(), new_width, new_height, 3, resized_data, 80)) {
                            if (is_temp) DeleteFileA(current_path.c_str());
                            current_path = resized_path;
                            is_temp = true;
                            is_jpg = true;
                            w = new_width; h = new_height;
                        }
                        free(resized_data);
                    }
                    stbi_image_free(pixels);
                }
            } else if (!is_jpg) {
                // If it's not JPG (e.g. PNG), convert it to JPG to save space in the PDF
                unsigned char* pixels = stbi_load(current_path.c_str(), &w, &h, &c, 3);
                if (pixels) {
                    std::string converted_path = path + ".conv.jpg";
                    if (stbi_write_jpg(converted_path.c_str(), w, h, 3, pixels, 80)) {
                        if (is_temp) DeleteFileA(current_path.c_str());
                        current_path = converted_path;
                        is_temp = true;
                        is_jpg = true;
                    }
                    stbi_image_free(pixels);
                }
            } else {
                // It's a JPG and no resizing is needed, we just need its dimensions
                stbi_info(current_path.c_str(), &w, &h, &c);
            }

            if (is_jpg && !current_path.empty()) {
                FPDF_PAGE new_page = FPDFPage_New(new_doc, FPDF_GetPageCount(new_doc), (double)w, (double)h);
                FPDF_PAGEOBJECT image_obj = FPDFPageObj_NewImageObj(new_doc);
                
                // Load the JPG file directly into the PDF image object (Native compression)
                std::ifstream file(current_path, std::ios::binary | std::ios::ate);
                std::streamsize size = file.tellg();
                file.seekg(0, std::ios::beg);
                std::vector<char> buffer(size);
                if (file.read(buffer.data(), size)) {
                    FPDF_FILEACCESS access;
                    access.m_FileLen = (unsigned long)size;
                    access.m_Param = buffer.data();
                    access.m_GetBlock = [](void* param, unsigned long pos, unsigned char* buf, unsigned long sz) -> int {
                        memcpy(buf, (char*)param + pos, sz);
                        return 1;
                    };
                    FPDFImageObj_LoadJpegFileInline(nullptr, 0, image_obj, &access);
                    FPDFPageObj_Transform(image_obj, (double)w, 0, 0, (double)h, 0, 0);
                    FPDFPage_InsertObject(new_page, image_obj);
                    FPDFPage_GenerateContent(new_page);
                }
                FPDF_ClosePage(new_page);
            }

            if (is_temp) DeleteFileA(current_path.c_str());
        }

        MyFileWrite fw;
        fw.version = 1; fw.WriteBlock = MyWriteBlock; fw.filename = output_path.c_str(); fw.file = nullptr;
        FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE*)&fw, FPDF_NO_INCREMENTAL);
        if (fw.file) fclose(fw.file);
        FPDF_CloseDocument(new_doc);
        result->Success(flutter::EncodableValue(output_path));
    }

    void PdfCombinerPlugin::create_image_from_pdf(const flutter::EncodableMap& args,
                                                  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        std::string input_path = std::get<std::string>(args.at(flutter::EncodableValue("path")));
        std::string output_path = std::get<std::string>(args.at(flutter::EncodableValue("outputDirPath")));
        int max_width = std::get<int>(args.at(flutter::EncodableValue("width")));
        int max_height = std::get<int>(args.at(flutter::EncodableValue("height")));
        int compression = std::get<int>(args.at(flutter::EncodableValue("compression")));
        bool create_one_image = std::get<bool>(args.at(flutter::EncodableValue("createOneImage")));
        
        FPDF_DOCUMENT doc = FPDF_LoadDocument(input_path.c_str(), nullptr);
        if (!doc) {
            result->Error("PDF_ERROR", "Could not load PDF document");
            return;
        }
        
        int page_count = FPDF_GetPageCount(doc);
        std::vector<flutter::EncodableValue> image_paths;
        
        if (create_one_image) {
            int total_width = 0, total_height = 0;
            std::vector<FPDF_PAGE> pages(page_count);
            std::vector<double> p_widths(page_count), p_heights(page_count);
            for (int i = 0; i < page_count; ++i) {
                pages[i] = FPDF_LoadPage(doc, i);
                double w = (max_width != 0) ? (double)max_width : FPDF_GetPageWidth(pages[i]);
                double h = (max_height != 0) ? (double)max_height : FPDF_GetPageHeight(pages[i]);
                p_widths[i] = w; p_heights[i] = h;
                total_width = (total_width > (int)w) ? total_width : (int)w;
                total_height += (int)h;
            }
            FPDF_BITMAP combined = FPDFBitmap_Create(total_width, total_height, 1);
            FPDFBitmap_FillRect(combined, 0, 0, total_width, total_height, 0xFFFFFFFF);
            
            int current_y = 0;
            for (int i = 0; i < page_count; ++i) {
                FPDF_RenderPageBitmap(combined, pages[i], 0, current_y, (int)p_widths[i], (int)p_heights[i], 0, FPDF_ANNOT);
                current_y += (int)p_heights[i];
                FPDF_ClosePage(pages[i]);
            }
            std::string out_img = output_path + "/image.png";
            save_bitmap_to_png(combined, out_img, compression);
            image_paths.push_back(flutter::EncodableValue(out_img));
            FPDFBitmap_Destroy(combined);
        } else {
            for (int i = 0; i < page_count; ++i) {
                FPDF_PAGE page = FPDF_LoadPage(doc, i);
                int w = (max_width != 0) ? max_width : (int)FPDF_GetPageWidth(page);
                int h = (max_height != 0) ? max_height : (int)FPDF_GetPageHeight(page);
                FPDF_BITMAP bitmap = FPDFBitmap_Create(w, h, 1);
                FPDFBitmap_FillRect(bitmap, 0, 0, w, h, 0xFFFFFFFF);
                FPDF_RenderPageBitmap(bitmap, page, 0, 0, w, h, 0, FPDF_ANNOT);
                std::string out_img = output_path + "/image_" + std::to_string(i+1) + ".png";
                save_bitmap_to_png(bitmap, out_img, compression);
                image_paths.push_back(flutter::EncodableValue(out_img));
                FPDFBitmap_Destroy(bitmap);
                FPDF_ClosePage(page);
            }
        }
        FPDF_CloseDocument(doc);
        result->Success(flutter::EncodableValue(image_paths));
    }
}
