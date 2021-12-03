#include <iostream>
#include <iterator>
#include <fstream>
#include <vector>

int read_string_as_binary(std::string & value)
{ 
    return stoi(value, 0, 2);
}

bool bit_is_on(int value, uint8_t position)
{
    return value & (1 << position);
}

bool bits_are_majority_on(std::vector<int> & values, uint8_t position)
{ 
    std::vector<bool> is_on_values;
    is_on_values.reserve(values.size());
  
    std::copy_if (values.begin(), values.end(), std::back_inserter(is_on_values), [position](int i){return bit_is_on(i, position); });
    
    return is_on_values.size() > values.size() / 2;
}

int main(int argc, char *argv[])
{
    const std::string input = std::string(argv[1]);  
    std::ifstream ifstream(input);
    const std::istream_iterator<std::string> start(ifstream);
    const std::istream_iterator<std::string> end;
    std::vector<std::string> numberStrings(start, end);
    
    std::vector<int> numbers;
    std::transform(numberStrings.begin(), numberStrings.end(), std::back_inserter(numbers), read_string_as_binary);

    int gamma = 0;
    int epsilon = 0;
    const int num_bits = 12;

    for (int position = 0; position < num_bits; position++) {
        if (bits_are_majority_on(numbers, position))
            gamma |= (1 << position);
        else {
            epsilon |= (1 << position);
        }
    }
    
    std::cout << epsilon * gamma << std::endl;
}

