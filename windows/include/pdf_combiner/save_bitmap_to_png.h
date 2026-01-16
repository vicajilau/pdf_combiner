#ifndef PDF_COMBINER_SAVE_BITMAP_TO_PNG_H_
#define PDF_COMBINER_SAVE_BITMAP_TO_PNG_H_

#include "../pdfium/fpdfview.h"
#include <string>

namespace pdf_combiner {
    bool save_bitmap_to_png(FPDF_BITMAP bitmap, const std::string& output_path, int compression);
}

#endif  // PDF_COMBINER_SAVE_BITMAP_TO_PNG_H_
