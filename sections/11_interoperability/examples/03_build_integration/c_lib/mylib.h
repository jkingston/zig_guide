#ifndef MYLIB_H
#define MYLIB_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Simple C library interface
int32_t add_numbers(int32_t a, int32_t b);
void print_message(const char* message);
double calculate_average(const double* values, size_t count);

#ifdef __cplusplus
}
#endif

#endif // MYLIB_H
