#ifndef C_BRIDGE_H
#define C_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque pointer type for C++ object
typedef struct MyCppClass_Opaque MyCppClass_Opaque;

// Constructor/Destructor
MyCppClass_Opaque* MyCppClass_create(int initial_value);
void MyCppClass_destroy(MyCppClass_Opaque* obj);

// Value operations
int MyCppClass_getValue(const MyCppClass_Opaque* obj);
void MyCppClass_setValue(MyCppClass_Opaque* obj, int value);
void MyCppClass_increment(MyCppClass_Opaque* obj);

// String operations
// Caller must free the returned string using MyCppClass_freeString
char* MyCppClass_getMessage(const MyCppClass_Opaque* obj);
void MyCppClass_setMessage(MyCppClass_Opaque* obj, const char* message);
void MyCppClass_freeString(char* str);

// Array operations
double MyCppClass_calculateSum(const MyCppClass_Opaque* obj,
                                 const double* values,
                                 size_t count);

#ifdef __cplusplus
}
#endif

#endif // C_BRIDGE_H
