// AoC 2023 - Puzzle 17 (Day 9, Puzzle 1)

#include <algorithm>
#include <cctype>
#include <charconv>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <iterator>
#include <numeric>
#include <sstream>
#include <stack>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

// config

static const bool g_debug     = false;

using std::string;
using std::vector;
using std::as_const;

using nums = vector<int32_t>;
using num_list = vector<nums>;
using num_stack = std::stack<nums, vector<nums>>;

// global vars

num_list g_readings;

static void decode_sensor_readings(const string &line)
{
    // line always looks like a list of numbers
    nums readings;
    std::istringstream line_str(line);

    while(!line_str.eof()) {
        int32_t num;
        line_str >> num;
        readings.push_back(num);
    }

    g_readings.push_back(readings);
}

static int32_t extrapolate_next(const nums &xs)
{
    nums cur_diffs;
    nums cur_list (xs);

    cur_list.push_back(0); // shortcut to optimize stack of adjacent_differences
                           // not my idea!...
    while(cur_list.size() > 1) {
        std::adjacent_difference(cur_list.begin(), cur_list.end(), back_inserter(cur_diffs));

        // first element is not part of adjacent difference
        cur_list = nums(++cur_diffs.begin(), cur_diffs.end());
        cur_diffs.clear();
    }

    return -cur_list[0];
}

int main(int argc, char **argv)
{
    using std::cerr;
    using std::cout;
    using std::endl;
    using std::ifstream;

    if (argc < 2) {
        std::cerr << "Enter a file to read\n";
        return 1;
    }

    ifstream input;
    input.exceptions(ifstream::badbit);

    try {
        input.open(argv[1]);

        // Read sensor readings
        string line;
        while (!input.eof() && std::getline(input, line)) {
            if (line.empty()) {
                continue;
            }

            decode_sensor_readings(line);
        }

        input.close();
    }
    catch (ifstream::failure &e) {
        cerr << "Exception on reading input: " << e.what() << endl;
        return 1;
    }

    if (g_readings.empty()) {
        cerr << "Invalid data read!\n";
        return 1;
    }

    if constexpr (0) {
        for (const auto & node : g_readings) {
            for (const auto &num : node) {
                std::cout << num << ' ';
            }
            std::cout << "\n";
        }
    }

    int32_t sum = 0;
    for (const auto &readings : g_readings) {
        const auto next_val = extrapolate_next(readings);
//      std::cout << next_val << "\n";
        sum += next_val;
    }

    std::cout << sum << "\n";
    return 0;
}
