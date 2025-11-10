#include "mylib.h"
#include <stdio.h>

int32_t add_numbers(int32_t a, int32_t b) {
    return a + b;
}

void print_message(const char* message) {
    printf("[C Library] %s\n", message);
}

double calculate_average(const double* values, size_t count) {
    if (count == 0) return 0.0;

    double sum = 0.0;
    for (size_t i = 0; i < count; i++) {
        sum += values[i];
    }
    return sum / (double)count;
}
