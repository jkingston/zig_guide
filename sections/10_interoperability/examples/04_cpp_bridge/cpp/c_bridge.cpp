#include "c_bridge.h"
#include "MyCppClass.hpp"
#include <cstring>
#include <cstdlib>

// Cast opaque pointer to actual C++ object
static MyCppClass* cast(MyCppClass_Opaque* obj) {
    return reinterpret_cast<MyCppClass*>(obj);
}

static const MyCppClass* cast(const MyCppClass_Opaque* obj) {
    return reinterpret_cast<const MyCppClass*>(obj);
}

extern "C" {

MyCppClass_Opaque* MyCppClass_create(int initial_value) {
    try {
        MyCppClass* obj = new MyCppClass(initial_value);
        return reinterpret_cast<MyCppClass_Opaque*>(obj);
    } catch (...) {
        return nullptr;
    }
}

void MyCppClass_destroy(MyCppClass_Opaque* obj) {
    if (obj) {
        delete cast(obj);
    }
}

int MyCppClass_getValue(const MyCppClass_Opaque* obj) {
    if (!obj) return 0;
    try {
        return cast(obj)->getValue();
    } catch (...) {
        return 0;
    }
}

void MyCppClass_setValue(MyCppClass_Opaque* obj, int value) {
    if (!obj) return;
    try {
        cast(obj)->setValue(value);
    } catch (...) {
        // Swallow exceptions at C boundary
    }
}

void MyCppClass_increment(MyCppClass_Opaque* obj) {
    if (!obj) return;
    try {
        cast(obj)->increment();
    } catch (...) {
        // Swallow exceptions at C boundary
    }
}

char* MyCppClass_getMessage(const MyCppClass_Opaque* obj) {
    if (!obj) return nullptr;
    try {
        std::string msg = cast(obj)->getMessage();
        char* result = static_cast<char*>(malloc(msg.length() + 1));
        if (result) {
            strcpy(result, msg.c_str());
        }
        return result;
    } catch (...) {
        return nullptr;
    }
}

void MyCppClass_setMessage(MyCppClass_Opaque* obj, const char* message) {
    if (!obj || !message) return;
    try {
        cast(obj)->setMessage(message);
    } catch (...) {
        // Swallow exceptions at C boundary
    }
}

void MyCppClass_freeString(char* str) {
    free(str);
}

double MyCppClass_calculateSum(const MyCppClass_Opaque* obj,
                                 const double* values,
                                 size_t count) {
    if (!obj || !values) return 0.0;
    try {
        std::vector<double> vec(values, values + count);
        return cast(obj)->calculateSum(vec);
    } catch (...) {
        return 0.0;
    }
}

} // extern "C"
