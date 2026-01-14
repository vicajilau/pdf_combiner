cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "pdf_combiner")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

set(PLUGIN_NAME "pdf_combiner_plugin")

list(APPEND PLUGIN_SOURCES
        "pdf_combiner_plugin.cpp"
        "pdf_combiner_plugin.h"
        "save_bitmap_to_png.cpp"
)

add_library(${PLUGIN_NAME} SHARED
        "include/pdf_combiner/pdf_combiner_plugin_c_api.h"
        "pdf_combiner_plugin_c_api.cpp"
        ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
        "${CMAKE_CURRENT_SOURCE_DIR}/include/pdfium"
)

# === Librerías Externas ===

# 1. PDFium
set(PDFIUM_LIB_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
find_library(PDFIUM_LIB NAMES pdfium PATHS ${PDFIUM_LIB_PATH} NO_DEFAULT_PATH)

# 2. libheif
set(HEIF_LIB_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
find_library(HEIF_LIB NAMES heif PATHS ${HEIF_LIB_PATH} NO_DEFAULT_PATH)

target_link_libraries(${PLUGIN_NAME} PRIVATE 
    flutter 
    flutter_wrapper_plugin 
    ${PDFIUM_LIB}
)

if (HEIF_LIB)
    target_link_libraries(${PLUGIN_NAME} PRIVATE ${HEIF_LIB})
    target_compile_definitions(${PLUGIN_NAME} PRIVATE HAS_HEIF)
    message(STATUS "libheif encontrado: ${HEIF_LIB}")
else()
    message(WARNING "libheif no encontrado. Soporte HEIC desactivado.")
endif()

# === Copia de DLLs (Fundamental para que la App arranque) ===
add_custom_command(TARGET ${PLUGIN_NAME} POST_BUILD
    # Copia a la carpeta del plugin
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/pdfium.dll" "$<TARGET_FILE_DIR:${PLUGIN_NAME}>/pdfium.dll"
    # Copia a la carpeta del Runner (ejecutable final)
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/pdfium.dll" "${CMAKE_CURRENT_BINARY_DIR}/../../runner/$<CONFIG>/pdfium.dll"
)

if (HEIF_LIB)
    add_custom_command(TARGET ${PLUGIN_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/heif.dll" "$<TARGET_FILE_DIR:${PLUGIN_NAME}>/heif.dll"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/heif.dll" "${CMAKE_CURRENT_BINARY_DIR}/../../runner/$<CONFIG>/heif.dll"
        COMMENT "Copiando heif.dll..."
    )
endif()

# === Tests ===
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
    target_include_directories(${TEST_RUNNER} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    target_link_libraries(${TEST_RUNNER} PRIVATE 
        flutter_wrapper_plugin 
        gtest_main 
        gmock 
        flutter 
        ${PDFIUM_LIB}
    )
    if (HEIF_LIB)
        target_link_libraries(${TEST_RUNNER} PRIVATE ${HEIF_LIB})
    endif()
    
    add_custom_command(TARGET ${TEST_RUNNER} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FLUTTER_LIBRARY}" $<TARGET_FILE_DIR:${TEST_RUNNER}>
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/pdfium.dll" $<TARGET_FILE_DIR:${TEST_RUNNER}>/pdfium.dll
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/heif.dll" $<TARGET_FILE_DIR:${TEST_RUNNER}>/heif.dll
    )
    include(GoogleTest)
    gtest_discover_tests(${TEST_RUNNER})
endif()
