#include "include/pdf_combiner/save_bitmap_to_png.h"
#include <vector>

// Eliminada la implementación aquí para evitar duplicados (LNK2005)
// Se centraliza en pdf_combiner_plugin.cpp
#include "include/pdf_combiner/stb_image_write.h"

namespace pdf_combiner {

bool save_bitmap_to_png(FPDF_BITMAP bitmap, const std::string& output_path, int compression) {
    int width = FPDFBitmap_GetWidth(bitmap);
    int height = FPDFBitmap_GetHeight(bitmap);
    void* buffer = FPDFBitmap_GetBuffer(bitmap);

    if (!buffer) {
        return false;
    }

    // The buffer is in BGRA format, so we convert it to RGBA
    std::vector<uint8_t> rgba_buffer(width * height * 4);
    uint8_t* src = static_cast<uint8_t*>(buffer);
    uint8_t* dst = rgba_buffer.data();

    for (int i = 0; i < width * height; i++) {
        dst[0] = src[2];  // R <- B
        dst[1] = src[1];  // G <- G
        dst[2] = src[0];  // B <- R
        dst[3] = src[3];  // A <- A
        src += 4;
        dst += 4;
    }

    // Save the image as PNG using stb_image_write
    return stbi_write_png(output_path.c_str(), width, height, 4, rgba_buffer.data(), width * 4) != 0;
}

} // namespace pdf_combiner
