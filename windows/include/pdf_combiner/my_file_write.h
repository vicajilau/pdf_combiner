#ifndef MY_FILE_WRITE_H
#define MY_FILE_WRITE_H

#include <stdio.h>
#include "../pdfium/fpdf_save.h"

// Estructura compatible con FPDF_FILEWRITE
typedef struct MyFileWrite {
    int version;
    int (*WriteBlock)(struct FPDF_FILEWRITE_* pThis, const void* pData, unsigned long size);
    const char* filename;
    FILE* file;
} MyFileWrite;

// Implementación del callback de escritura
static int MyWriteBlock(struct FPDF_FILEWRITE_* pThis, const void* pData, unsigned long size) {
    MyFileWrite* pMe = (MyFileWrite*)pThis;
    if (!pMe || !pData) return 0;

    if (!pMe->file) {
        // Abrir en modo "wb" (write binary) para sobreescribir/crear
        if (fopen_s(&pMe->file, pMe->filename, "wb") != 0 || !pMe->file) {
            return 0;
        }
    }

    size_t written = fwrite(pData, 1, size, pMe->file);
    return (written == size) ? 1 : 0;
}

#endif // MY_FILE_WRITE_H
