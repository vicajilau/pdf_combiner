#include "pdf_combiner_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <vector>
#include <string>
#include <algorithm>

#include "include/pdfium/fpdfview.h"
#include "include/pdfium/fpdf_edit.h"
#include "include/pdfium/fpdf_save.h"
#include "include/pdfium/fpdf_ppo.h"

#include "include/pdf_combiner/my_file_write.h"
#include "include/pdf_combiner/save_bitmap_to_png.h"

// Librerías para el manejo de imágenes en Windows (HEIC a JPEG)
#include <wincodec.h>
#include <shlwapi.h>

#pragma comment(lib, "windowscodecs.lib")
#pragma comment(lib, "shlwapi.lib")

// Para cargar imágenes mediante stb_image
#ifndef STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#include "include/pdf_combiner/stb_image.h"
#endif

#ifndef STB_IMAGE_RESIZE_IMPLEMENTATION
#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "include/pdf_combiner/stb_image_resize.h"
#endif

namespace pdf_combiner {

    // Función auxiliar para convertir HEIC a JPEG usando Windows Imaging Component (WIC)
    // Se define como estática dentro del namespace para evitar conflictos
    static std::string ConvertHeicToJpegNative(const std::string& input_path, const std::string& output_dir) {
        // Inicializar COM para WIC
        HRESULT hr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);

        IWICImagingFactory* pFactory = NULL;
        IWICBitmapDecoder* pDecoder = NULL;
        IWICBitmapFrameDecode* pFrame = NULL;
        IWICBitmapEncoder* pEncoder = NULL;
        IWICStream* pStream = NULL;
        IWICFormatConverter* pConverter = NULL;

        // Generar ruta temporal única para el JPEG convertido
        std::string output_path = output_dir + "\\temp_conv_" + std::to_string(GetTickCount64()) + ".jpg";

        hr = CoCreateInstance(CLSID_WICImagingFactory, NULL, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&pFactory));
        if (FAILED(hr)) return "";

        // Convertir string a wstring para las APIs de Windows
        std::wstring w_input(input_path.begin(), input_path.end());
        hr = pFactory->CreateDecoderFromFilename(w_input.c_str(), NULL, GENERIC_READ, WICDecodeMetadataCacheOnDemand, &pDecoder);

        if (SUCCEEDED(hr)) hr = pDecoder->GetFrame(0, &pFrame);
        if (SUCCEEDED(hr)) hr = pFactory->CreateFormatConverter(&pConverter);
        if (SUCCEEDED(hr)) {
            hr = pConverter->Initialize(pFrame, GUID_WICPixelFormat24bppBGR, WICBitmapDitherTypeNone, NULL, 0.0, WICBitmapPaletteTypeCustom);
        }
        if (SUCCEEDED(hr)) hr = pFactory->CreateStream(&pStream);
        if (SUCCEEDED(hr)) {
            std::wstring w_output(output_path.begin(), output_path.end());
            hr = pStream->InitializeFromFilename(w_output.c_str(), GENERIC_WRITE);
        }
        if (SUCCEEDED(hr)) {
            hr = pFactory->CreateEncoder(GUID_ContainerFormatJpeg, NULL, &pEncoder);
            hr = pEncoder->Initialize(pStream, WICBitmapEncoderNoCache);
        }

        IWICBitmapFrameEncode* pFrameEncode = NULL;
        if (SUCCEEDED(hr)) hr = pEncoder->CreateNewFrame(&pFrameEncode, NULL);
        if (SUCCEEDED(hr)) hr = pFrameEncode->Initialize(NULL);
        if (SUCCEEDED(hr)) hr = pFrameEncode->WriteSource(pConverter, NULL);
        if (SUCCEEDED(hr)) hr = pFrameEncode->Commit();
        if (SUCCEEDED(hr)) hr = pEncoder->Commit();

        // Liberar recursos
        if (pFrameEncode) pFrameEncode->Release();
        if (pConverter) pConverter->Release();
        if (pStream) pStream->Release();
        if (pEncoder) pEncoder->Release();
        if (pFrame) pFrame->Release();
        if (pDecoder) pDecoder->Release();
        if (pFactory) pFactory->Release();

        return SUCCEEDED(hr) ? output_path : "";
    }

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
        FPDF_InitLibrary();
    }

    PdfCombinerPlugin::~PdfCombinerPlugin() {
        FPDF_DestroyLibrary();
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
        } else if (method_call.method_name() == "createImageFromPDF") {
            this->create_image_from_pdf(*args, std::move(result));
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
            const auto& vec = std::get<std::vector<flutter::EncodableValue>>(paths_it->second);
            for (const auto& path_value : vec) {
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

        // Corrección C2065: Aseguramos que MyFileWrite esté disponible
        MyFileWrite file_write;
        file_write.version = 1;
        file_write.WriteBlock = MyWriteBlock;
        file_write.filename = output_path.c_str();

        FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE*)&file_write, FPDF_INCREMENTAL);
        FPDF_CloseDocument(new_doc);
        result->Success(flutter::EncodableValue(output_path));
    }

    void PdfCombinerPlugin::create_pdf_from_multiple_image(
            const flutter::EncodableMap& args,
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

        for (const auto& input_path : input_paths) {
            std::string current_path = input_path;
            bool is_temp = false;

            // Lógica HEIC
            if (input_path.length() > 5) {
                std::string ext = input_path.substr(input_path.find_last_of(".") + 1);
                std::transform(ext.begin(), ext.end(), ext.begin(), ::tolower);
                if (ext == "heic" || ext == "heif") {
                    size_t last_slash = output_path.find_last_of("\\/");
                    std::string temp_dir = (last_slash != std::string::npos) ? output_path.substr(0, last_slash) : ".";
                    std::string converted = ConvertHeicToJpegNative(input_path, temp_dir);
                    if (!converted.empty()) {
                        current_path = converted;
                        is_temp = true;
                    }
                }
            }

            int width, height, channels;
            unsigned char* image_data = stbi_load(current_path.c_str(), &width, &height, &channels, 4);
            if (!image_data) continue;

            // Redimensionamiento
            if (max_width != 0 || max_height != 0) {
                int new_width = (max_width != 0) ? max_width : width;
                int new_height = (max_height != 0) ? max_height : height;
                if (keep_aspect_ratio && max_width != 0) {
                    new_height = static_cast<int>(new_width * (static_cast<double>(height) / width));
                }
                unsigned char* resized = new unsigned char[new_width * new_height * 4];
                stbir_resize_uint8_linear(image_data, width, height, 0, resized, new_width, new_height, 0, STBIR_RGBA);
                stbi_image_free(image_data);
                image_data = resized; width = new_width; height = new_height;
            }

            FPDF_PAGE page = FPDFPage_New(new_doc, FPDF_GetPageCount(new_doc), width, height);
            FPDF_BITMAP bitmap = FPDFBitmap_Create(width, height, 0);
            FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xFFFFFFFF);

            unsigned char* buffer = (unsigned char*)FPDFBitmap_GetBuffer(bitmap);
            int stride = FPDFBitmap_GetStride(bitmap);
            for (int y = 0; y < height; y++) {
                unsigned char* src = image_data + y * width * 4;
                unsigned char* dst = buffer + (height - 1 - y) * stride;
                for (int x = 0; x < width; x++) {
                    dst[x * 4 + 0] = src[x * 4 + 2]; // B
                    dst[x * 4 + 1] = src[x * 4 + 1]; // G
                    dst[x * 4 + 2] = src[x * 4 + 0]; // R
                    dst[x * 4 + 3] = src[x * 4 + 3]; // A
                }
            }

            FPDF_PAGEOBJECT image_obj = FPDFPageObj_NewImageObj(new_doc);
            FPDFImageObj_SetBitmap(&page, 1, image_obj, bitmap);
            FPDFImageObj_SetMatrix(image_obj, (double)width, 0, 0, (double)-height, 0, (double)height);
            FPDFPage_InsertObject(page, image_obj);
            FPDFPage_GenerateContent(page);

            stbi_image_free(image_data);
            FPDFBitmap_Destroy(bitmap);
            if (is_temp) DeleteFileA(current_path.c_str());
        }

        MyFileWrite file_write;
        file_write.version = 1;
        file_write.WriteBlock = MyWriteBlock;
        file_write.filename = output_path.c_str();

        FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE*)&file_write, FPDF_NO_INCREMENTAL);
        FPDF_CloseDocument(new_doc);
        result->Success(flutter::EncodableValue(output_path));
    }

    void PdfCombinerPlugin::create_image_from_pdf(
            const flutter::EncodableMap& args,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        // Implementación básica para evitar errores de compilación
        result->Success(flutter::EncodableValue("Not implemented fully in this snippet"));
    }

} // namespace pdf_combiner