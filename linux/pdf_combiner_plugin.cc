#include "include/pdf_combiner/pdf_combiner_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>
#include <vector>
#include <string>

#include "pdf_combiner_plugin_private.h"

#include "include/pdfium/fpdfview.h"
#include "include/pdfium/fpdf_edit.h"
#include "include/pdfium/fpdf_save.h"
#include "include/pdfium/fpdf_ppo.h"

#include "include/pdf_combiner/my_file_write.h"
#include "include/pdf_combiner/save_bitmap_to_png.h"

#define PDF_COMBINER_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), pdf_combiner_plugin_get_type(), \
                              PdfCombinerPlugin))

struct _PdfCombinerPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(PdfCombinerPlugin, pdf_combiner_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void pdf_combiner_plugin_handle_method_call( PdfCombinerPlugin* self, FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

    if (strcmp(method, "mergeMultiplePDF") == 0) {
        response = merge_multiple_pdfs(fl_method_call_get_args(method_call));
    } else if (strcmp(method, "createPDFFromMultipleImage") == 0) {
        response = create_pdf_from_multiple_images(fl_method_call_get_args(method_call));
    } else if (strcmp(method, "createImageFromPDF") == 0) {
        response = create_image_from_pdf(fl_method_call_get_args(method_call));
    } else {
        response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* merge_multiple_pdfs(FlValue* args) {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "Expected a map with inputPaths and outputPath", nullptr));
    }

    // Get inputPaths (List<String>)
    FlValue* input_paths_value = fl_value_lookup_string(args, "paths");
    if (!input_paths_value || fl_value_get_type(input_paths_value) != FL_VALUE_TYPE_LIST) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "inputPaths must be a list of strings", nullptr));
    }

    // Get outputPath (String)
    FlValue* output_path_value = fl_value_lookup_string(args, "outputDirPath");
    if (!output_path_value || fl_value_get_type(output_path_value) != FL_VALUE_TYPE_STRING) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "outputPath must be a string", nullptr));
    }

    // Cast outputPath to C-string
    const char* output_path = fl_value_get_string(output_path_value);

    // Cast inputPaths to a strings vector
    int num_pdfs = fl_value_get_length(input_paths_value);
    std::vector<std::string> input_paths;
    for (int i = 0; i < num_pdfs; i++) {
        FlValue* path_value = fl_value_get_list_value(input_paths_value, i);
        if (!path_value || fl_value_get_type(path_value) != FL_VALUE_TYPE_STRING) {
            return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "Each item in inputPaths must be a string", nullptr));
        }
        input_paths.push_back(std::string(fl_value_get_string(path_value)));
    }

    // Create an empty document
    FPDF_DOCUMENT new_doc = FPDF_CreateNewDocument();
    if (!new_doc) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("document_creation_failed", "Failed to create new PDF document", nullptr));
    }

    int total_pages = 0;  // Variable to track total pages

    // Process each PDF file in input_paths
    for (const auto& input_path : input_paths) {
        // Load the PDF file
        FPDF_DOCUMENT doc = FPDF_LoadDocument(input_path.c_str(), nullptr);
        if (!doc) {
            FPDF_CloseDocument(new_doc);
            return FL_METHOD_RESPONSE(fl_method_error_response_new("document_loading_failed", ("Failed to load document: " + input_path).c_str(), nullptr));
        }

        // Get the number of pages in the loaded document
        int page_count = FPDF_GetPageCount(doc);

        // Import the page into the new document
        if (!FPDF_ImportPages(new_doc, doc, nullptr, total_pages)) {
            FPDF_CloseDocument(doc);
            FPDF_CloseDocument(new_doc);
            return FL_METHOD_RESPONSE(fl_method_error_response_new("page_import_failed", "Failed to import page into new document", nullptr));
        }
        total_pages += page_count;

        // Close the loaded document
        FPDF_CloseDocument(doc);
    }

    MyFileWrite file_write;
    file_write.version = 1;
    file_write.WriteBlock = MyWriteBlock;
    file_write.filename = output_path;

    // Save the new document
    if (!FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE*)&file_write, FPDF_INCREMENTAL)) {
        FPDF_CloseDocument(new_doc);
        return FL_METHOD_RESPONSE(fl_method_error_response_new("document_save_failed", "Failed to save the new PDF document", nullptr));
    }

    // Close the new document
    FPDF_CloseDocument(new_doc);

    // Return success response with the output path
    g_autoptr(FlValue) result = fl_value_new_string(output_path);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* create_pdf_from_multiple_images(FlValue* args) {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "Expected a map with inputPaths and outputPath", nullptr));
    }

    // Get inputPaths (List<String>)
    FlValue* input_paths_value = fl_value_lookup_string(args, "paths");
    if (!input_paths_value || fl_value_get_type(input_paths_value) != FL_VALUE_TYPE_LIST) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "inputPaths must be a list of strings", nullptr));
    }

    // Get width (String)
    FlValue* max_width_value = fl_value_lookup_string(args, "width");
    if (!max_width_value || fl_value_get_type(max_width_value) != FL_VALUE_TYPE_INT) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "width must be an int", nullptr));
    }

    // Cast width to C-int
    int64_t max_width = fl_value_get_int(max_width_value);

    // Get height (String)
    FlValue* max_height_value = fl_value_lookup_string(args, "height");
    if (!max_height_value || fl_value_get_type(max_height_value) != FL_VALUE_TYPE_INT) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "maxHeight must be an int", nullptr));
    }

    // Cast height to C-int
    int64_t max_height = fl_value_get_int(max_height_value);

    // Get keepAspectRatio (Bool)
    FlValue* keep_aspect_ratio_value = fl_value_lookup_string(args, "keepAspectRatio");
    if (!keep_aspect_ratio_value || fl_value_get_type(keep_aspect_ratio_value) != FL_VALUE_TYPE_BOOL) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "keepAspectRatio must be a boolean", nullptr));
    }

    // Get boolean value
    bool keep_aspect_ratio = fl_value_get_bool(keep_aspect_ratio_value);

    // Get outputPath (String)
    FlValue* output_path_value = fl_value_lookup_string(args, "outputDirPath");
    if (!output_path_value || fl_value_get_type(output_path_value) != FL_VALUE_TYPE_STRING) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "outputPath must be a string", nullptr));
    }

    // Cast outputPath to C-string
    const char* output_path = fl_value_get_string(output_path_value);

    // Cast inputPaths to a strings vector
    int num_images = fl_value_get_length(input_paths_value);
    std::vector<std::string> input_paths;

    for (int i = 0; i < num_images; i++) {
        FlValue* path_value = fl_value_get_list_value(input_paths_value, i);
        if (!path_value || fl_value_get_type(path_value) != FL_VALUE_TYPE_STRING) {
            return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "Each item in inputPaths must be a string", nullptr));
        }
        input_paths.push_back(std::string(fl_value_get_string(path_value)));
    }

    // Create an empty document
    FPDF_DOCUMENT new_doc = FPDF_CreateNewDocument();
    if (!new_doc) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("document_creation_failed", "Failed to create new PDF document", nullptr));
    }

    // Process each image file in input_paths
    for (const auto& input_path : input_paths) {
        // Load the image and get its dimensions
        int width, height, channels;
        unsigned char* image_data = stbi_load(input_path.c_str(), &width, &height, &channels, 4);
        if (!image_data) {
            FPDF_CloseDocument(new_doc);
            return FL_METHOD_RESPONSE(fl_method_error_response_new("image_loading_failed", ("Failed to load image: " + input_path).c_str(), nullptr));
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

            unsigned char* resized_image_data = new unsigned char[new_width * new_height * 4];

            if (!stbir_resize_uint8_linear(image_data, width, height, 0, resized_image_data, new_width, new_height, 0, STBIR_RGBA)) {
                stbi_image_free(image_data);
                FPDF_CloseDocument(new_doc);
                return FL_METHOD_RESPONSE(fl_method_error_response_new("image_resize_failed", "Failed to resize image", nullptr));
            }

            // Free only the original image, not the resized one
            stbi_image_free(image_data);

            // Assigning the new values
            image_data = resized_image_data;
            width = new_width;
            height = new_height;
        }

        FPDF_PAGE new_page = FPDFPage_New(new_doc, FPDF_GetPageCount(new_doc), width, height);
        if (!new_page) {
            stbi_image_free(image_data);
            FPDF_CloseDocument(new_doc);
            return FL_METHOD_RESPONSE(fl_method_error_response_new("page_creation_failed", ("Failed to create page for image: " + input_path).c_str(), nullptr));
        }

        // Crate bitmap of the image
        FPDF_BITMAP bitmap = FPDFBitmap_Create(width, height, 0);
        FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xFFFFFFFF);
        unsigned char* bitmap_buffer = (unsigned char*)FPDFBitmap_GetBuffer(bitmap);
        int stride = FPDFBitmap_GetStride(bitmap);

        for (int y = 0; y < height; y++) {
            unsigned char* src_row = image_data + y * width * 4;
            unsigned char* dst_row = bitmap_buffer + (height - 1 - y) * stride;

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
            return FL_METHOD_RESPONSE(fl_method_error_response_new("image_object_creation_failed", ("Failed to create image object for: " + input_path).c_str(), nullptr));
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
    file_write.filename = output_path;

    // Save the new document
    if (!FPDF_SaveAsCopy(new_doc, (FPDF_FILEWRITE*)&file_write, FPDF_INCREMENTAL)) {
        FPDF_CloseDocument(new_doc);
        return FL_METHOD_RESPONSE(fl_method_error_response_new("document_save_failed", "Failed to save the new PDF document", nullptr));
    }

    // Close the new document
    FPDF_CloseDocument(new_doc);

    // Return success response with the output path
    g_autoptr(FlValue) result = fl_value_new_string(output_path);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* create_image_from_pdf(FlValue* args) {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
                "invalid_arguments", "Expected a map with inputPath, outputDirPath, width, height, compression and createOneImage keys", nullptr));
    }

    // Get params from the map
    const char* input_path = fl_value_get_string(fl_value_lookup_string(args, "path"));

    // Get width (String)
    FlValue* max_width_value = fl_value_lookup_string(args, "width");
    if (!max_width_value || fl_value_get_type(max_width_value) != FL_VALUE_TYPE_INT) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "width must be an int", nullptr));
    }

    // Cast width to C-int
    int64_t max_width = fl_value_get_int(max_width_value);

    // Get height (String)
    FlValue* max_height_value = fl_value_lookup_string(args, "height");
    if (!max_height_value || fl_value_get_type(max_height_value) != FL_VALUE_TYPE_INT) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "height must be an int", nullptr));
    }

    // Cast height to C-int
    int64_t max_height = fl_value_get_int(max_height_value);

    // Get compression (String)
    FlValue* compression_value = fl_value_lookup_string(args, "compression");
    if (!compression_value || fl_value_get_type(compression_value) != FL_VALUE_TYPE_INT) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "compression must be an int", nullptr));
    }

    // Cast height to C-int
    int compression = (int)fl_value_get_int(compression_value);

    const char* output_path = fl_value_get_string(fl_value_lookup_string(args, "outputDirPath"));
    if (!input_path || !output_path) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
                "invalid_arguments", "Missing path or outputDirPath", nullptr));
    }

    // Load the PDF document
    FPDF_DOCUMENT doc = FPDF_LoadDocument(input_path, nullptr);
    if (!doc) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
                "document_loading_failed", "Failed to load PDF document", nullptr));
    }

    int page_count = FPDF_GetPageCount(doc);
    if (page_count < 1) {
        FPDF_CloseDocument(doc);
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
                "empty_pdf", "The PDF document is empty", nullptr));
    }

    FlValue* result = fl_value_new_list();


    // Get createOneImage (Bool)
    FlValue* create_one_image_value = fl_value_lookup_string(args, "createOneImage");
    if (!create_one_image_value || fl_value_get_type(create_one_image_value) != FL_VALUE_TYPE_BOOL) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("invalid_arguments", "createOneImage must be a boolean", nullptr));
    }

    // Get boolean value
    bool create_one_image = fl_value_get_bool(create_one_image_value);

    if (create_one_image) {
        int total_width = 0;
        int total_height = 0;

        // First, calculate the total width and height for the combined image
        std::vector<FPDF_PAGE> pages(page_count);
        std::vector<double> page_widths(page_count);
        std::vector<double> page_heights(page_count);

        for (int i = 0; i < page_count; ++i) {
            FPDF_PAGE page = FPDF_LoadPage(doc, i);
            if (!page) continue;

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

            total_width = std::max(total_width, (int)width); // Use the max width
            total_height += (int)height; // Sum the heights for vertical layout
        }

        // Create a bitmap large enough to hold all pages vertically
        FPDF_BITMAP combined_bitmap = FPDFBitmap_Create(total_width, total_height, 0xFFFFFFFF);
        if (!combined_bitmap) {
            FPDF_CloseDocument(doc);
            return FL_METHOD_RESPONSE(fl_method_error_response_new(
                    "bitmap_creation_failed", "Failed to create combined bitmap", nullptr));
        }

        int current_y = 0;

        // Render each page into the large combined image
        for (int i = 0; i < page_count; ++i) {
            FPDF_PAGE page = pages[i];

            // Render the page into the combined bitmap at the correct position
            FPDF_RenderPageBitmap(combined_bitmap, page, 0, current_y, (int)page_widths[i], (int)page_heights[i], 0, FPDF_ANNOT);
            current_y += (int)page_heights[i]; // Move the y position down for the next page
        }

        // Save the combined bitmap to a PNG file
        std::string output_image_path = std::string(output_path) + "/combined_image.png";
        if (!save_bitmap_to_png(combined_bitmap, output_image_path, compression)) {
            FPDFBitmap_Destroy(combined_bitmap);
            FPDF_CloseDocument(doc);
            return FL_METHOD_RESPONSE(fl_method_error_response_new(
                    "image_save_failed", "Failed to save combined image", nullptr));
        }

        // Add the combined image path to the result list
        FlValue* image_path_value = fl_value_new_string(output_image_path.c_str());
        fl_value_append(result, image_path_value);

        // Clean up resources
        FPDFBitmap_Destroy(combined_bitmap);
        for (int i = 0; i < page_count; ++i) {
            FPDF_ClosePage(pages[i]);
        }
    } else {
        for (int i = 0; i < page_count; ++i) {
            FPDF_PAGE page = FPDF_LoadPage(doc, i);
            if (!page) continue;

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
                return FL_METHOD_RESPONSE(fl_method_error_response_new(
                        "bitmap_creation_failed", "Failed to create bitmap", nullptr));
            }

            // Render the page into the bitmap
            FPDF_RenderPageBitmap(bitmap, page, 0, 0, (int)width, (int)height, 0, FPDF_ANNOT);

            // Save the bitmap to a PNG file
            std::string output_image_path = std::string(output_path) + "/image_" + std::to_string(i+1) + ".png";
            if (!save_bitmap_to_png(bitmap, output_image_path, compression)) {
                FPDF_ClosePage(page);
                FPDF_CloseDocument(doc);
                return FL_METHOD_RESPONSE(fl_method_error_response_new(
                        "image_save_failed", "Failed to save image", nullptr));
            }

            // Add the image path to the result list
            FlValue* image_path_value = fl_value_new_string(output_image_path.c_str());
            fl_value_append(result, image_path_value);

            // Clean resources
            FPDFBitmap_Destroy(bitmap);
            FPDF_ClosePage(page);
        }
    }

    FPDF_CloseDocument(doc);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void pdf_combiner_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(pdf_combiner_plugin_parent_class)->dispose(object);
  FPDF_DestroyLibrary(); // Destroy the FPDF library
}

static void pdf_combiner_plugin_class_init(PdfCombinerPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = pdf_combiner_plugin_dispose;
}

static void pdf_combiner_plugin_init(PdfCombinerPlugin* self) {
  FPDF_InitLibrary(); // Initialize the FPDF library
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  PdfCombinerPlugin* plugin = PDF_COMBINER_PLUGIN(user_data);
  pdf_combiner_plugin_handle_method_call(plugin, method_call);
}

void pdf_combiner_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  PdfCombinerPlugin* plugin = PDF_COMBINER_PLUGIN(
      g_object_new(pdf_combiner_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "pdf_combiner",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
