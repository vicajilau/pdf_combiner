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

// Solo declaración, la implementación irá en el .cpp para evitar LNK2005
#ifdef __cplusplus
extern "C" {
#endif
    int MyWriteBlock(struct FPDF_FILEWRITE_* pThis, const void* pData, unsigned long size);
#ifdef __cplusplus
}
#endif

#endif // MY_FILE_WRITE_H
