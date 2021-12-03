#include <iostream>
#include <iterator>
#include <fstream>
#include <vector>

int read_string_as_binary(std::string &value)
{
    return stoi(value, 0, 2);
}

bool bit_is_on(int value, uint8_t position)
{
    return value & (1 << position);
}

std::vector<int> &filter_oxygen(std::vector<int> &on_values, std::vector<int> &off_values)
{
    return on_values.size() >= off_values.size() ? on_values : off_values;
}

std::vector<int> &filter_co2(std::vector<int> &on_values, std::vector<int> &off_values)
{
    return on_values.size() < off_values.size() ? on_values : off_values;
}

std::vector<int> filter(
    std::vector<int> &values,
    std::function<std::vector<int> &(std::vector<int> &, std::vector<int> &)> predicate,
    uint8_t total_bits,
    uint8_t position_from_left = 0)
{
    if (values.size() <= 1 || position_from_left >= total_bits)
        return values;

    const uint8_t position_from_right = total_bits - position_from_left - 1;
    std::vector<int> on_values;
    std::vector<int> off_values;
    on_values.reserve(values.size());
    off_values.reserve(values.size());

    std::copy_if(values.begin(), values.end(), std::back_inserter(on_values), [position_from_right](int i)
                 { return bit_is_on(i, position_from_right); });
    std::copy_if(values.begin(), values.end(), std::back_inserter(off_values), [position_from_right](int i)
                 { return !bit_is_on(i, position_from_right); });

    std::vector<int> &newValues = predicate(on_values, off_values);

    return filter(newValues, predicate, total_bits, position_from_left + 1);
}

int main(int argc, char *argv[])
{
    const std::string input = std::string(argv[1]);
    std::ifstream ifstream(input);
    const std::istream_iterator<std::string> start(ifstream);
    const std::istream_iterator<std::string> end;
    std::vector<std::string> number_strings(start, end);

    std::vector<int> numbers;
    std::transform(number_strings.begin(), number_strings.end(), std::back_inserter(numbers), read_string_as_binary);

    const int total_bits = number_strings.front().size();

    const std::vector<int> oxygen = filter(numbers, filter_oxygen, total_bits);
    const std::vector<int> co2_scrubber = filter(numbers, filter_co2, total_bits);

    std::cout << oxygen.front() * co2_scrubber.front() << std::endl;
}
