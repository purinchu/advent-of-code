// AoC 2023 - Puzzle 28
//
// Grid stuff

#include <algorithm>
#include <concepts>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iostream>
#include <iterator>
#include <numeric>
#include <string>
#include <string_view>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

// config

static const bool g_show_input = false;

// common types

using std::as_const;
using std::vector;

unsigned char aoc_hash(std::string_view sv)
{
    unsigned int result = 0;

    for(const auto &ch : sv) {
        unsigned char c (ch);
        result += c;
        result *= 17;
        result &= 0xFF; // divide modulo 256
    }

    return static_cast<unsigned char>(result);
}

int main(int argc, char **argv)
{
    using std::cerr;
    using std::cout;
    using std::endl;
    using std::ifstream;
    using std::string;

    if (argc < 2) {
        std::cerr << "Enter a file to read\n";
        return 1;
    }

    ifstream input;
    input.exceptions(ifstream::badbit);

    unsigned sum = 0;

    try {
        input.open(argv[1]);
        string line;
        while (!input.eof() && std::getline(input, line)) {
            std::string_view sv(line);
            auto start = sv.begin();
            auto end = std::find(sv.begin(), sv.end(), ',');

            while(start != sv.end() || end != sv.end()) {
                sum += aoc_hash(std::string_view(start, end));
                start = (end == sv.end()) ? sv.end() : end + 1;
                end = std::find(start, sv.end(), ',');
            }

            cout << sum << "\n";
        }

        input.close();
    }
    catch (ifstream::failure &e) {
        cerr << "Exception on reading input: " << e.what() << endl;
        return 1;
    }
    catch (...) {
        cerr << "Something else went wrong..." << endl;
        return 1;
    }

    return 0;
}
