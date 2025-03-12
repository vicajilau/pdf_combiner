#include <stdio.h>

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

    FILE* file = NULL;
    if (fopen_s(&file, pThis->filename, "ab") != 0 || !file) {
        return 0;  // if file cannot be opened, return 0
    }

    size_t written = fwrite(pData, 1, size, file);  // write data to file
    fclose(file);  // Close the file

    return written == size ? 1 : 0;  // Return 1 if all data was written, 0 otherwise
}
