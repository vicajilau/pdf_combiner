cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "pdf_combiner")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

set(PLUGIN_NAME "pdf_combiner_plugin")

# =========================
# Plugin Sources
# =========================
list(APPEND PLUGIN_SOURCES
        "pdf_combiner_plugin.cpp"
        "pdf_combiner_plugin.h"
        "save_bitmap_to_png.cpp"
        "stb_implementation.cpp"
)

add_library(${PLUGIN_NAME} SHARED
        "include/pdf_combiner/pdf_combiner_plugin_c_api.h"
        "pdf_combiner_plugin_c_api.cpp"
        ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
        CXX_VISIBILITY_PRESET hidden
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# =========================
# Include paths
# =========================
target_include_directories(${PLUGIN_NAME} PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
        "${CMAKE_CURRENT_SOURCE_DIR}/include/pdfium"
)

target_include_directories(${PLUGIN_NAME} INTERFACE
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

# =========================
# PDFium (REQUIRED)
# =========================
set(PDFIUM_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")

find_library(PDFIUM_LIB
        NAMES pdfium
        PATHS "${PDFIUM_ROOT}"
        NO_DEFAULT_PATH
        REQUIRED
)

if (NOT EXISTS "${PDFIUM_ROOT}/pdfium.dll")
    message(FATAL_ERROR "pdfium.dll not found in ${PDFIUM_ROOT}")
endif()

# =========================
# Link libraries
# =========================
target_link_libraries(${PLUGIN_NAME} PRIVATE
        flutter
        flutter_wrapper_plugin
        ${PDFIUM_LIB}
)

# =========================
# Register DLLs for Bundling
# =========================

# This variable is used by the generated flutter/generated_plugins.cmake
# to include these files in the final application bundle.
set(pdf_combiner_bundled_libraries
  "${PDFIUM_ROOT}/pdfium.dll"
  PARENT_SCOPE
)

# Optional: libheif (only if present)
if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/heif.dll")
    set(pdf_combiner_bundled_libraries
      ${pdf_combiner_bundled_libraries}
      "${CMAKE_CURRENT_SOURCE_DIR}/heif.dll"
      PARENT_SCOPE
    )
endif()

# Copy to the plugin's output directory for local linkage/testing
add_custom_command(TARGET ${PLUGIN_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${PDFIUM_ROOT}/pdfium.dll"
        "$<TARGET_FILE_DIR:${PLUGIN_NAME}>/pdfium.dll"
        COMMENT "Copying pdfium.dll to plugin directory"
)

# =========================
# Tests (optional)
# =========================
if (${include_${PROJECT_NAME}_tests})
    set(TEST_RUNNER "${PROJECT_NAME}_test")
    enable_testing()

    include(FetchContent)
    FetchContent_Declare(
            googletest
            URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
    )

    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)

    add_executable(${TEST_RUNNER}
            test/pdf_combiner_plugin_test.cpp
            ${PLUGIN_SOURCES}
    )

    apply_standard_settings(${TEST_RUNNER})

    target_include_directories(${TEST_RUNNER} PRIVATE
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_SOURCE_DIR}/include"
            "${CMAKE_CURRENT_SOURCE_DIR}/include/pdfium"
    )

    target_link_libraries(${TEST_RUNNER} PRIVATE
            flutter
            flutter_wrapper_plugin
            gtest_main
            gmock
            ${PDFIUM_LIB}
    )

    add_custom_command(TARGET ${TEST_RUNNER} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${PDFIUM_ROOT}/pdfium.dll"
            "$<TARGET_FILE_DIR:${TEST_RUNNER}>/pdfium.dll"
    )

    include(GoogleTest)
    gtest_discover_tests(${TEST_RUNNER})
endif()
