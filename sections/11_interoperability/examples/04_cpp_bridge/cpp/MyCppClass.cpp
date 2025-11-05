#include "MyCppClass.hpp"
#include <numeric>

MyCppClass::MyCppClass(int initial_value)
    : value_(initial_value), message_("Default message") {
}

MyCppClass::~MyCppClass() {
    // Cleanup if needed
}

int MyCppClass::getValue() const {
    return value_;
}

void MyCppClass::setValue(int value) {
    value_ = value;
}

void MyCppClass::increment() {
    value_++;
}

std::string MyCppClass::getMessage() const {
    return message_;
}

void MyCppClass::setMessage(const std::string& msg) {
    message_ = msg;
}

double MyCppClass::calculateSum(const std::vector<double>& values) const {
    return std::accumulate(values.begin(), values.end(), 0.0);
}
