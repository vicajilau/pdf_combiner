#include "include/pdf_combiner/pdf_combiner_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#include "pdf_combiner_plugin_private.h"
#include "include/pdfium/fpdfview.h"

#define PDF_COMBINER_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), pdf_combiner_plugin_get_type(), \
                              PdfCombinerPlugin))

struct _PdfCombinerPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(PdfCombinerPlugin, pdf_combiner_plugin, g_object_get_type())

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
    if (!args || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENT", "Invalid arguments", nullptr));
    }

    FlValue* paths_value = fl_value_lookup_string(args, "paths");
    FlValue* output_path_value = fl_value_lookup_string(args, "outputDirPath");

    if (!paths_value || !output_path_value) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENT", "Missing paths or output path", nullptr));
    }

    const char* output_path = fl_value_get_string(output_path_value);
    int file_count = fl_value_get_length(paths_value);

    if (file_count == 0) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("EMPTY_LIST", "No PDFs provided", nullptr));
    }

    // Crear documento de salida
    FPDF_DOCUMENT output_doc = FPDF_CreateNewDocument();
    if (!output_doc) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new("PDF_CREATION_FAILED", "Failed to create new PDF document", nullptr));
    }

    for (int i = 0; i < file_count; i++) {
        const char* file_path = fl_value_get_string(fl_value_get_list_value(paths_value, i));
        FPDF_DOCUMENT doc = FPDF_LoadDocument(file_path, nullptr);
        if (!doc) {
            continue;
        }

        int page_count = FPDF_GetPageCount(doc);
        for (int j = 0; j < page_count; j++) {
            FPDF_PAGE page = FPDF_LoadPage(doc, j);
            if (!page) {
                continue;
            }
            FPDFPage_New(output_doc, j, FPDF_GetPageWidth(page), FPDF_GetPageHeight(page));
            FPDFPage_GenerateContent(output_doc);
            FPDF_ClosePage(page);
        }
        FPDF_CloseDocument(doc);
    }

    // Guardar el documento final
    if (!FPDF_SaveAsCopy(output_doc, output_path, FPDF_SAVE_NO_INCREMENTAL)) {
        FPDF_CloseDocument(output_doc);
        return FL_METHOD_RESPONSE(fl_method_error_response_new("SAVE_FAILED", "Failed to save merged PDF", nullptr));
    }

    FPDF_CloseDocument(output_doc);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(output_path)));
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
