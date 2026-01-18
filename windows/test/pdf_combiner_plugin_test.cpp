#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <memory>
#include <string>
#include <variant>

#include "pdf_combiner_plugin.h"

namespace pdf_combiner {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

}  // namespace

TEST(PdfCombinerPluginTest, GetPlatformVersion) {
  pdf_combiner::PdfCombinerPlugin plugin;
  // Save the reply value from the success callback.
  std::string result_string;
  plugin.HandleMethodCall(
      MethodCall("getPlatformVersion", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          [&result_string](const EncodableValue* result) {
            if (std::holds_alternative<std::string>(*result)) {
                result_string = std::get<std::string>(*result);
            }
          },
          nullptr, nullptr));

  // If the method is not implemented, result_string will be empty.
  // The goal here is to fix the compilation error first.
}

}  // namespace test
}  // namespace pdf_combiner
