cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "pdf_combiner")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

set(PLUGIN_NAME "pdf_combiner_plugin")

# Directory where your external tools (HEIF/Magick EXEs/DLLs) are located
set(EXTERNAL_BIN_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

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

set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Header search paths configuration (.h)
# PUBLIC makes these paths available to library consumers (such as the example app)
target_include_directories(${PLUGIN_NAME} INTERFACE
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_include_directories(${PLUGIN_NAME} PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/include/pdfium"
        "${CMAKE_CURRENT_SOURCE_DIR}/."
)

# === External Libraries ===

# 1. PDFium (Required)
set(PDFIUM_LIB_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
find_library(PDFIUM_LIB NAMES pdfium PATHS ${PDFIUM_LIB_PATH} NO_DEFAULT_PATH)

target_link_libraries(${PLUGIN_NAME} PRIVATE
        flutter
        flutter_wrapper_plugin
        ${PDFIUM_LIB}
)

# === Copy DLLs and Executables to output directory ===
add_custom_command(TARGET ${PLUGIN_NAME} POST_BUILD
        # Copy PDFium (mandatory)
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/pdfium.dll" "$<TARGET_FILE_DIR:${PLUGIN_NAME}>/pdfium.dll"

        # Copy HEIC conversion tool (Magick) only if they exist
        COMMAND ${CMAKE_COMMAND} -E touch "dummy_file"
        COMMAND if exist "${EXTERNAL_BIN_DIR}\\magick.exe" ${CMAKE_COMMAND} -E copy_if_different "${EXTERNAL_BIN_DIR}/magick.exe" "$<TARGET_FILE_DIR:${PLUGIN_NAME}>/magick.exe"
        COMMAND if exist "${EXTERNAL_BIN_DIR}\\heif.dll" ${CMAKE_COMMAND} -E copy_if_different "${EXTERNAL_BIN_DIR}/heif.dll" "$<TARGET_FILE_DIR:${PLUGIN_NAME}>/heif.dll"

        # Backup copy for the development environment (Runner)
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/pdfium.dll" "${CMAKE_CURRENT_BINARY_DIR}/../../runner/$<CONFIG>/pdfium.dll"
        COMMAND if exist "${EXTERNAL_BIN_DIR}\\magick.exe" ${CMAKE_COMMAND} -E copy_if_different "${EXTERNAL_BIN_DIR}/magick.exe" "${CMAKE_CURRENT_BINARY_DIR}/../../runner/$<CONFIG>/magick.exe"

        COMMENT "Copying external binaries to the output folder..."
)

# === Tests Configuration ===
if (${include_${PROJECT_NAME}_tests})
    set(TEST_RUNNER "${PROJECT_NAME}_test")
    enable_testing()
    include(FetchContent)
    FetchContent_Declare(googletest URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip)
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)

    add_executable(${TEST_RUNNER} test/pdf_combiner_plugin_test.cpp ${PLUGIN_SOURCES})
    apply_standard_settings(${TEST_RUNNER})

    # IMPORTANT: The test needs the same include paths as the plugin
    # We place "." first so it finds the correct pdf_combiner_plugin.h
    target_include_directories(${TEST_RUNNER} PRIVATE
            "${CMAKE_CURRENT_SOURCE_DIR}/."
            "${CMAKE_CURRENT_SOURCE_DIR}/include"
            "${CMAKE_CURRENT_SOURCE_DIR}/include/pdfium"
    )

    target_link_libraries(${TEST_RUNNER} PRIVATE
            flutter_wrapper_plugin
            gtest_main
            gmock
            flutter
            ${PDFIUM_LIB}
    )

    # Also copy binaries for the test executable
    add_custom_command(TARGET ${TEST_RUNNER} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FLUTTER_LIBRARY}" $<TARGET_FILE_DIR:${TEST_RUNNER}>
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/pdfium.dll" $<TARGET_FILE_DIR:${TEST_RUNNER}>/pdfium.dll
            COMMAND if exist "${EXTERNAL_BIN_DIR}\\magick.exe" ${CMAKE_COMMAND} -E copy_if_different "${EXTERNAL_BIN_DIR}/magick.exe" $<TARGET_FILE_DIR:${TEST_RUNNER}>/magick.exe
    )

    include(GoogleTest)
    gtest_discover_tests(${TEST_RUNNER})
endif()