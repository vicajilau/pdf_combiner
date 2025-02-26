#include "include/pdf_combiner/pdf_combiner_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "pdf_combiner_plugin.h"

void PdfCombinerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  pdf_combiner::PdfCombinerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
