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

#define PDF_COMBINER_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), pdf_combiner_plugin_get_type(), \
                              PdfCombinerPlugin))

struct _PdfCombinerPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(PdfCombinerPlugin, pdf_combiner_plugin, g_object_get_type())

typedef struct MyFileWrite {
    int version;
    int (*WriteBlock)(struct MyFileWrite* pThis, const void* pData, unsigned long size);
    const char* filename;  // Name of the file to write
} MyFileWrite;

// MyWriteBlock declaration
static int MyWriteBlock(MyFileWrite* pThis, const void* pData, unsigned long size);

// MyWriteBlock implementation
static int MyWriteBlock(MyFileWrite* pThis, const void* pData, unsigned long size) {
    if (!pThis || !pData) {
        return 0;  // if params are null, return 0
    }

    FILE* file = fopen(pThis->filename, "ab");  // Open file in append binary mode
    if (!file) {
        return 0;  // if file cannot be opened, return 0
    }

    size_t written = fwrite(pData, 1, size, file);  // write data to file
    fclose(file);  // Cierra el archivo

    return written == size ? 1 : 0;  // Return 1 if all data was written, 0 otherwise
}

// Called when a method call is received from Flutter.
static void pdf_combiner_plugin_handle_method_call(
    PdfCombinerPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

    if (strcmp(method, "getPlatformVersion") == 0) {
        response = get_platform_version();
    } else if (strcmp(method, "mergeMultiplePDF") == 0) {
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

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* merge_multiple_pdfs(FlValue* args) {
    printf("Args type: %d\n", fl_value_get_type(args));
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
                "invalid_arguments", "Expected a map with inputPaths and outputPath", nullptr));
    }

    // Get inputPaths (List<String>)
    FlValue* input_paths_value = fl_value_lookup_string(args, "paths");
    if (!input_paths_value || fl_value_get_type(input_paths_value) != FL_VALUE_TYPE_LIST) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
                "invalid_arguments", "inputPaths must be a list of strings", nullptr));
    }

    // Get outputPath (String)
    FlValue* output_path_value = fl_value_lookup_string(args, "outputDirPath");
    if (!output_path_value || fl_value_get_type(output_path_value) != FL_VALUE_TYPE_STRING) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
                "invalid_arguments", "outputPath must be a string", nullptr));
    }

    // Cast outputPath to C-string
    const char* output_path = fl_value_get_string(output_path_value);

    // Cast inputPaths to a strings vector
    int num_pdfs = fl_value_get_length(input_paths_value);
    std::vector<std::string> input_paths;
    for (int i = 0; i < num_pdfs; i++) {
        FlValue* path_value = fl_value_get_list_value(input_paths_value, i);
        if (!path_value || fl_value_get_type(path_value) != FL_VALUE_TYPE_STRING) {
            return FL_METHOD_RESPONSE(fl_method_error_response_new(
                    "invalid_arguments", "Each item in inputPaths must be a string", nullptr));
        }
        input_paths.push_back(std::string(fl_value_get_string(path_value)));
    }

    // Create an empty document
    FPDF_DOCUMENT new_doc = FPDF_CreateNewDocument();
    if (!new_doc) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
                "document_creation_failed", "Failed to create new PDF document", nullptr));
    }

    // Process each PDF file in input_paths
    for (const auto& input_path : input_paths) {
        // Cargar el documento PDF
        FPDF_DOCUMENT doc = FPDF_LoadDocument(input_path.c_str(), nullptr);
        if (!doc) {
            FPDF_CloseDocument(new_doc);
            return FL_METHOD_RESPONSE(fl_method_error_response_new(
                    "document_loading_failed", ("Failed to load document: " + input_path).c_str(), nullptr));
        }

        // Get the number of pages in the loaded document
        int page_count = FPDF_GetPageCount(doc);

        // Import each page into the new document
        for (int i = 0; i < page_count; i++) {
            // Import the page from the loaded document
            FPDF_PAGE page = FPDF_LoadPage(doc, i);
            if (!page) {
                FPDF_CloseDocument(doc);
                FPDF_CloseDocument(new_doc);
                return FL_METHOD_RESPONSE(fl_method_error_response_new(
                        "page_loading_failed", "Failed to load page from document", nullptr));
            }

            // Get the number of pages in the old document
            unsigned long length = FPDF_GetPageCount(doc);

            // Import the page into the new document
            if (!FPDF_ImportPagesByIndex(new_doc, doc, nullptr, length, 0)) {
                FPDF_ClosePage(page);
                FPDF_CloseDocument(doc);
                FPDF_CloseDocument(new_doc);
                return FL_METHOD_RESPONSE(fl_method_error_response_new(
                        "page_import_failed", "Failed to import page into new document", nullptr));
            }

            // Close the imported page
            FPDF_ClosePage(page);
        }

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
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
                "document_save_failed", "Failed to save the new PDF document", nullptr));
    }

    // Close the new document
    FPDF_CloseDocument(new_doc);

    // Return success response with the output path
    g_autoptr(FlValue) result = fl_value_new_string(output_path);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* create_pdf_from_multiple_images(FlValue* args) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("UNIMPLEMENTED", "createPDFFromMultipleImage not implemented", nullptr));
}

FlMethodResponse* create_image_from_pdf(FlValue* args) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("UNIMPLEMENTED", "createImageFromPDF not implemented", nullptr));
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

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
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
