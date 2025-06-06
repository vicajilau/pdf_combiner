#include <flutter_linux/flutter_linux.h>

#include "include/pdf_combiner/pdf_combiner_plugin.h"

// This file exposes some plugin internals for unit testing. See
// https://github.com/flutter/flutter/issues/88724 for current limitations
// in the unit-testable API.

// Handles the getPlatformVersion method call.
FlMethodResponse *merge_multiple_pdfs(FlValue *args);
FlMethodResponse *create_pdf_from_multiple_images(FlValue *args);
FlMethodResponse *create_image_from_pdf(FlValue *args);
