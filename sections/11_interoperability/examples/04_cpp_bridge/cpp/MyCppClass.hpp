#ifndef MYCPPCLASS_HPP
#define MYCPPCLASS_HPP

#include <string>
#include <vector>

class MyCppClass {
public:
    MyCppClass(int initial_value);
    ~MyCppClass();

    int getValue() const;
    void setValue(int value);
    void increment();

    std::string getMessage() const;
    void setMessage(const std::string& msg);

    double calculateSum(const std::vector<double>& values) const;

private:
    int value_;
    std::string message_;
};

#endif // MYCPPCLASS_HPP
