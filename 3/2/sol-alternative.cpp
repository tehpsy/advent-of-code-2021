#include <iostream>
#include <iterator>
#include <fstream>
#include <vector>

using Values = std::vector<int>;

int read_string_as_binary(std::string &value)
{
    return stoi(value, 0, 2);
}

bool bit_is_on(int value, uint8_t position)
{
    return value & (1 << position);
}

Values &filter_oxygen(Values &on_values, Values &off_values)
{
    return on_values.size() >= off_values.size() ? on_values : off_values;
}

Values &filter_co2(Values &on_values, Values &off_values)
{
    return on_values.size() < off_values.size() ? on_values : off_values;
}

Values filter(
    Values &values,
    std::function<Values &(Values &, Values &)> predicate,
    uint8_t total_bits,
    uint8_t position_from_left = 0)
{
    if (values.size() <= 1 || position_from_left >= total_bits)
        return values;

    const uint8_t position_from_right = total_bits - position_from_left - 1;

    Values::iterator partition_point = std::partition(
        values.begin(),
        values.end(),
        [position_from_right](int i)
        {
            return bit_is_on(i, position_from_right);
        });

    const int num_on_values = std::distance(values.begin(), partition_point);

    Values on_values(values.begin(), partition_point);
    Values off_values(partition_point, values.end());
    Values &filtered_values = predicate(on_values, off_values);

    return filter(filtered_values, predicate, total_bits, position_from_left + 1);
}

int main(int argc, char *argv[])
{
    const std::string input = std::string(argv[1]);
    std::ifstream ifstream(input);
    const std::istream_iterator<std::string> start(ifstream);
    const std::istream_iterator<std::string> end;
    std::vector<std::string> number_strings(start, end);

    Values numbers;
    std::transform(number_strings.begin(), number_strings.end(), std::back_inserter(numbers), read_string_as_binary);

    const int total_bits = number_strings.front().size();

    const Values oxygen = filter(numbers, filter_oxygen, total_bits);
    const Values co2_scrubber = filter(numbers, filter_co2, total_bits);

    std::cout << oxygen.front() * co2_scrubber.front() << std::endl;
}
