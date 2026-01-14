#pragma once
#include "include/pdf_combiner/pdf_combiner_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>

#include <vector>
#include <string>
#include <memory>
#include <wincodec.h>
#include <wrl/client.h>
#include <cstdlib>

#include "include/pdfium/fpdfview.h"
#include "include/pdfium/fpdf_edit.h"
#include "include/pdfium/fpdf_save.h"
#include "include/pdf_combiner/my_file_write.h"

#pragma comment(lib, "windowscodecs.lib")

namespace pdf_combiner {

    class PdfCombinerPlugin : public flutter::Plugin {
    public:
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
            auto channel = std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
                    registrar->messenger(),
                            "pdf_combiner",
                            &flutter::StandardMethodCodec::GetInstance());

            auto plugin = std::make_unique<PdfCombinerPlugin>();

            channel->SetMethodCallHandler(
                    [plugin_pointer = plugin.get()](const flutter::MethodCall<flutter::EncodableValue>& call,
                                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
                        plugin_pointer->HandleMethodCall(call, std::move(result));
                    });

            registrar->AddPlugin(std::move(plugin));
        }

        PdfCombinerPlugin() { FPDF_InitLibrary(); }
        ~PdfCombinerPlugin() override { FPDF_DestroyLibrary(); }

    public:
        void HandleMethodCall(
                const flutter::MethodCall<flutter::EncodableValue>& call,
                std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

            const std::string& method = call.method_name();

            if (method == "createPDFFromMultipleImage") {
                auto args = std::get<flutter::EncodableMap>(*call.arguments());

                // Obtener paths
                auto paths_it = args.find(flutter::EncodableValue("paths"));
                if (paths_it == args.end()) {
                    result->Error("invalid_arguments", "Missing 'paths'");
                    return;
                }
                auto paths_list = std::get<flutter::EncodableList>(paths_it->second);

                std::vector<std::string> input_paths;
                for (auto& p : paths_list) {
                    input_paths.push_back(std::get<std::string>(p));
                }

                // Obtener outputDirPath
                auto output_it = args.find(flutter::EncodableValue("outputDirPath"));
                if (output_it == args.end()) {
                    result->Error("invalid_arguments", "Missing 'outputDirPath'");
                    return;
                }
                std::string output_path = std::get<std::string>(output_it->second);

                // Crear PDF desde imágenes
                if (create_pdf_from_images_windows(input_paths, output_path)) {
                    result->Success(flutter::EncodableValue(output_path));
                } else {
                    result->Error("failed", "Failed to create PDF");
                }

            } else {
                result->NotImplemented();
            }
        }

    private:
        // Carga cualquier imagen soportada por WIC (HEIC, JPG, PNG, BMP, GIF...)
        static unsigned char* load_image_via_wic(const char* filename, int* width, int* height) {
            HRESULT hr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
            if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) return nullptr;

            Microsoft::WRL::ComPtr<IWICImagingFactory> factory;
            hr = CoCreateInstance(CLSID_WICImagingFactory, NULL, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory));
            if (FAILED(hr)) return nullptr;

            wchar_t w_filename[MAX_PATH];
            MultiByteToWideChar(CP_UTF8, 0, filename, -1, w_filename, MAX_PATH);

            Microsoft::WRL::ComPtr<IWICBitmapDecoder> decoder;
            hr = factory->CreateDecoderFromFilename(w_filename, NULL, GENERIC_READ, WICDecodeMetadataCacheOnDemand, &decoder);
            if (FAILED(hr)) return nullptr;

            Microsoft::WRL::ComPtr<IWICBitmapFrameDecode> frame;
            hr = decoder->GetFrame(0, &frame);
            if (FAILED(hr)) return nullptr;

            UINT w, h;
            frame->GetSize(&w, &h);
            *width = w;
            *height = h;

            Microsoft::WRL::ComPtr<IWICFormatConverter> converter;
            factory->CreateFormatConverter(&converter);
            hr = converter->Initialize(frame.Get(), GUID_WICPixelFormat32bppRGBA, WICBitmapDitherTypeNone, NULL, 0.0, WICBitmapPaletteTypeCustom);
            if (FAILED(hr)) return nullptr;

            unsigned char* buffer = (unsigned char*)malloc(w * h * 4);
            hr = converter->CopyPixels(NULL, w * 4, w * h * 4, buffer);
            if (FAILED(hr)) {
                free(buffer);
                return nullptr;
            }

            return buffer;
        }

        // Función principal que crea el PDF desde imágenes
        static bool create_pdf_from_images_windows(const std::vector<std::string>& input_paths, const std::string& output_path) {
            FPDF_DOCUMENT new_doc = FPDF_CreateNewDocument();
            if (!new_doc) return false;

            for (const auto& input_path : input_paths) {
                int width, height;
                unsigned char* image_data = load_image_via_wic(input_path.c_str(), &width, &height);

                if (!image_data) {
                    FPDF_CloseDocument(new_doc);
                    return false;
                }

                FPDF_PAGE new_page = FPDFPage_New(new_doc, FPDF_GetPageCount(new_doc), width, height);
                if (!new_page) {
                    free(image_data);
                    FPDF_CloseDocument(new_doc);
                    return false;
                }

                FPDF_BITMAP bitmap = FPDFBitmap_Create(width, height, 0);
                FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xFFFFFFFF);
                unsigned char* bitmap_buffer = (unsigned char*)FPDFBitmap_GetBuffer(bitmap);
                int stride = FPDFBitmap_GetStride(bitmap);

                for (int y = 0; y < height; y++) {
                    unsigned char* src_row = image_data + y * width * 4;
                    unsigned char* dst_row = bitmap_buffer + (height - 1 - y) * stride;

                    for (int x = 0; x < width; x++) {
                        dst_row[x * 4 + 0] = src_row[x * 4 + 2];
                        dst_row[x * 4 + 1] = src_row[x * 4 + 1];
                        dst_row[x * 4 + 2] = src_row[x * 4 + 0];
                        dst_row[x * 4 + 3] = src_row[x * 4 + 3];
                    }
                }

                FPDF_PAGEOBJECT image_obj = FPDFPageObj_NewImageObj(new_doc);
                FPDFImageObj_SetBitmap(&new_page, 1, image_obj, bitmap);
                FPDFImageObj_SetMatrix(image_obj, width, 0, 0, -height, 0, height);
                FPDFPage_InsertObject(new_page, image_obj);
                FPDFPage_GenerateContent(new_page);

                free(image_data);
                FPDFBitmap_Destroy(bitmap);
            }

            MyFileWrite file_write;
            file_write.version = 1;
            file_write.WriteBlock = MyWriteBlock;
            file_write.filename = output_path.c_str();

            bool ok = FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE*)&file_write, FPDF_INCREMENTAL) != 0;
            FPDF_CloseDocument(new_doc);
            return ok;
        }
    };

}  // namespace pdf_combiner

// Función para registrar con Flutter
void PdfCombinerPluginRegisterWithRegistrar(
        FlutterDesktopPluginRegistrarRef registrar) {
    pdf_combiner::PdfCombinerPlugin::RegisterWithRegistrar(
            flutter::PluginRegistrarManager::GetInstance()
                    ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
