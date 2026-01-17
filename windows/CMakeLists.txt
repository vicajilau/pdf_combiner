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

# Definimos HAS_HEIF para activar el bloque #ifdef en tu .cpp
target_compile_definitions(${PLUGIN_NAME} PRIVATE
        FLUTTER_PLUGIN_IMPL
        HAS_HEIF
)

# =========================
# Include paths
# =========================
target_include_directories(${PLUGIN_NAME} PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
        "${CMAKE_CURRENT_SOURCE_DIR}/include/pdfium"
        "${CMAKE_CURRENT_SOURCE_DIR}/include/libheif"
)

target_include_directories(${PLUGIN_NAME} INTERFACE
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

# =========================
# PDFium & libheif (VENDORED)
# =========================
set(PDFIUM_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")

# We are looking for pdfium.lib
find_library(PDFIUM_LIB NAMES pdfium PATHS "${PDFIUM_ROOT}" NO_DEFAULT_PATH REQUIRED)

# We are looking for pdfium.lib
find_library(HEIF_LIB NAMES heif PATHS "${CMAKE_CURRENT_SOURCE_DIR}/include/libheif" NO_DEFAULT_PATH REQUIRED)
find_library(DE265_LIB NAMES libde265 PATHS "${CMAKE_CURRENT_SOURCE_DIR}/include/libheif" NO_DEFAULT_PATH REQUIRED)


# =========================
# DLL Management (Bundling)
# =========================
set(MY_PLUGIN_DLLS
        "${CMAKE_CURRENT_SOURCE_DIR}/pdfium.dll"
        "${CMAKE_CURRENT_SOURCE_DIR}/heif.dll"
        "${CMAKE_CURRENT_SOURCE_DIR}/libde265.dll"
        "${CMAKE_CURRENT_SOURCE_DIR}/libx265.dll"
)


set(pdf_combiner_bundled_libraries ${MY_PLUGIN_DLLS} PARENT_SCOPE)

# =========================
# Link libraries
# =========================
target_link_libraries(${PLUGIN_NAME} PRIVATE
        flutter
        flutter_wrapper_plugin
        ${PDFIUM_LIB}
        ${HEIF_LIB}
        ${DE265_LIB}
)


add_custom_command(TARGET ${PLUGIN_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${MY_PLUGIN_DLLS}
        "$<TARGET_FILE_DIR:${PLUGIN_NAME}>"
)