#include "pdf_combiner_plugin.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <windows.h>
#include <shlwapi.h>
#include <iostream>
#include <vector>
#include <string>
#include <algorithm>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include "include/pdfium/fpdfview.h"
#include "include/pdfium/fpdf_edit.h"
#include "include/pdfium/fpdf_save.h"
#include "include/pdfium/fpdf_ppo.h"

#include "include/pdf_combiner/my_file_write.h"
#include "include/pdf_combiner/save_bitmap_to_png.h"

#define STB_IMAGE_IMPLEMENTATION
#include "include/pdf_combiner/stb_image.h"
#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "include/pdf_combiner/stb_image_resize2.h"

#pragma comment(lib, "shlwapi.lib")

namespace pdf_combiner {

    std::wstring Utf8ToWide(const std::string& utf8) {
        if (utf8.empty()) return L"";
        int size_needed = MultiByteToWideChar(CP_UTF8, 0, &utf8[0], (int)utf8.size(), NULL, 0);
        std::wstring wstrTo(size_needed, 0);
        MultiByteToWideChar(CP_UTF8, 0, &utf8[0], (int)utf8.size(), &wstrTo[0], size_needed);
        return wstrTo;
    }

    std::string WideToUtf8(const std::wstring& wstr) {
        if (wstr.empty()) return "";
        int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
        std::string strTo(size_needed, 0);
        WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);
        return strTo;
    }

    // Nueva función que utiliza ImageMagick para convertir HEIC a PNG
    std::string ConvertHeicToPng(const std::string& heic_path, const std::string& temp_dir_hint) {
        std::wstring w_temp_dir;
        if (temp_dir_hint == "." || temp_dir_hint.empty()) {
            wchar_t system_temp[MAX_PATH];
            GetTempPathW(MAX_PATH, system_temp);
            w_temp_dir = system_temp;
        } else {
            w_temp_dir = Utf8ToWide(temp_dir_hint);
        }

        wchar_t temp_file_path[MAX_PATH];
        if (!GetTempFileNameW(w_temp_dir.c_str(), L"PDFC", 0, temp_file_path)) {
            return "";
        }
        
        std::wstring w_output_png = temp_file_path;
        DeleteFileW(temp_file_path); // Liberar el nombre para el nuevo archivo
        
        size_t dot = w_output_png.find_last_of(L'.');
        if (dot != std::wstring::npos) w_output_png.replace(dot, std::wstring::npos, L".png");
        else w_output_png += L".png";
        
        std::string output_png = WideToUtf8(w_output_png);

        // Construir comando: magick "input.heic" "output.png"
        // Usamos CreateProcess para que sea silencioso (sin ventana de consola)
        std::wstring command = L"magick \"" + Utf8ToWide(heic_path) + L"\" \"" + w_output_png + L"\"";
        
        STARTUPINFOW si = { sizeof(STARTUPINFOW) };
        si.dwFlags = STARTF_USESHOWWINDOW;
        si.wShowWindow = SW_HIDE;
        PROCESS_INFORMATION pi = { 0 };

        if (CreateProcessW(NULL, &command[0], NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) {
            WaitForSingleObject(pi.hProcess, INFINITE);
            DWORD exitCode = 0;
            GetExitCodeProcess(pi.hProcess, &exitCode);
            CloseHandle(pi.hProcess);
            CloseHandle(pi.hThread);
            
            if (exitCode == 0) {
                return output_png;
            }
        }

        return "";
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

        if (paths_it == args.end() || output_it == args.end()) {
            result->Error("invalid_arguments", "Expected a map with inputPaths and outputPath");
            return;
        }

        std::vector<std::string> input_paths;
        if (std::holds_alternative<std::vector<flutter::EncodableValue>>(paths_it->second)) {
            for (const auto& path_value : std::get<std::vector<flutter::EncodableValue>>(paths_it->second)) {
                if (std::holds_alternative<std::string>(path_value)) {
                    input_paths.push_back(std::get<std::string>(path_value));
                }
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
        FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE*)&file_write, FPDF_INCREMENTAL);
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
        for (const auto& path_value : path_list) {
            input_paths.push_back(std::get<std::string>(path_value));
        }

        std::string output_path = std::get<std::string>(output_it->second);
        int max_width = std::get<int>(width_it->second);
        int max_height = std::get<int>(height_it->second);
        bool keep_aspect_ratio = std::get<bool>(keep_aspect_ratio_it->second);

        FPDF_DOCUMENT new_doc = FPDF_CreateNewDocument();

        for (const auto& path : input_paths) {
            std::string current_path = path;
            bool is_heic = false;

            if (path.length() >= 5) {
                std::string ext = path.substr(path.length() - 5);
                for (auto& c : ext) c = static_cast<char>(tolower(static_cast<unsigned char>(c)));
                if (ext.find(".heic") != std::string::npos || ext.find(".heif") != std::string::npos) is_heic = true;
            }

            if (is_heic) {
                size_t last_slash = output_path.find_last_of("\\/");
                std::string temp_dir = (last_slash != std::string::npos) ? output_path.substr(0, last_slash) : "";

                // Usar ImageMagick para convertir a PNG
                std::string converted = ConvertHeicToPng(path, temp_dir);
                if (converted.empty()) {
                    FPDF_CloseDocument(new_doc);
                    result->Error("heic_conversion_failed", ("Fallo al convertir HEIC. Asegúrate de tener instalado ImageMagick y que esté en el PATH del sistema: " + path).c_str());
                    return;
                }
                current_path = converted;
            }

            int width, height, channels;
            unsigned char* image_data = stbi_load(current_path.c_str(), &width, &height, &channels, 4);

            if (!image_data) {
                if (is_heic && current_path != path) DeleteFileA(current_path.c_str());
                continue;
            }

            if (max_width != 0 || max_height != 0) {
                int new_width = (max_width != 0) ? max_width : width;
                int new_height = (max_height != 0) ? (keep_aspect_ratio ? static_cast<int>(max_width * (static_cast<double>(height) / width)) : max_height) : height;

                unsigned char* resized_data = new unsigned char[new_width * new_height * 4];
                if (stbir_resize_uint8_linear(image_data, width, height, 0, resized_data, new_width, new_height, 0, STBIR_RGBA)) {
                    stbi_image_free(image_data);
                    image_data = resized_data;
                    width = new_width;
                    height = new_height;
                }
            }

            FPDF_PAGE new_page = FPDFPage_New(new_doc, FPDF_GetPageCount(new_doc), width, height);
            FPDF_BITMAP bitmap = FPDFBitmap_Create(width, height, 0);
            FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xFFFFFFFF);
            unsigned char* buffer = (unsigned char*)FPDFBitmap_GetBuffer(bitmap);
            int stride = FPDFBitmap_GetStride(bitmap);

            for (int y = 0; y < height; y++) {
                unsigned char* src = image_data + y * width * 4;
                unsigned char* dst = buffer + (height - 1 - y) * stride;
                for (int x = 0; x < width; x++) {
                    dst[x * 4 + 0] = src[x * 4 + 2];
                    dst[x * 4 + 1] = src[x * 4 + 1];
                    dst[x * 4 + 2] = src[x * 4 + 0];
                    dst[x * 4 + 3] = src[x * 4 + 3];
                }
            }

            FPDF_PAGEOBJECT image_obj = FPDFPageObj_NewImageObj(new_doc);
            FPDFImageObj_SetBitmap(&new_page, 1, image_obj, bitmap);
            FPDFImageObj_SetMatrix(image_obj, width, 0, 0, -height, 0, height);
            FPDFPage_InsertObject(new_page, image_obj);
            FPDFPage_GenerateContent(new_page);

            stbi_image_free(image_data);
            FPDFBitmap_Destroy(bitmap);
            if (is_heic && current_path != path) DeleteFileA(current_path.c_str());
        }

        MyFileWrite file_write;
        file_write.version = 1;
        file_write.WriteBlock = MyWriteBlock;
        file_write.filename = output_path.c_str();
        FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE*)&file_write, FPDF_NO_INCREMENTAL);
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
        int page_count = FPDF_GetPageCount(doc);
        std::vector<flutter::EncodableValue> image_paths;

        if (create_one_image) {
            int total_width = 0, total_height = 0;
            std::vector<FPDF_PAGE> pages(page_count);
            std::vector<double> p_widths(page_count), p_heights(page_count);

            for (int i = 0; i < page_count; ++i) {
                pages[i] = FPDF_LoadPage(doc, i);
                double w = (max_width != 0) ? max_width : FPDF_GetPageWidth(pages[i]);
                double h = (max_height != 0) ? max_height : FPDF_GetPageHeight(pages[i]);
                p_widths[i] = w; p_heights[i] = h;
                total_width = (int)(std::max)((double)total_width, w);
                total_height += (int)h;
            }

            FPDF_BITMAP combined = FPDFBitmap_Create(total_width, total_height, 0xFFFFFFFF);
            int current_y = 0;
            for (int i = 0; i < page_count; ++i) {
                FPDF_RenderPageBitmap(combined, pages[i], 0, current_y, (int)p_widths[i], (int)p_heights[i], 0, FPDF_ANNOT);
                current_y += (int)p_heights[i];
            }

            std::string out_img = output_path + "/image.png";
            save_bitmap_to_png(combined, out_img, compression);
            image_paths.push_back(flutter::EncodableValue(out_img));
            FPDFBitmap_Destroy(combined);
            for (auto p : pages) FPDF_ClosePage(p);
        } else {
            for (int i = 0; i < page_count; ++i) {
                FPDF_PAGE page = FPDF_LoadPage(doc, i);
                int w = (max_width != 0) ? max_width : (int)FPDF_GetPageWidth(page);
                int h = (max_height != 0) ? max_height : (int)FPDF_GetPageHeight(page);
                FPDF_BITMAP bitmap = FPDFBitmap_Create(w, h, 0xFFFFFFFF);
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
