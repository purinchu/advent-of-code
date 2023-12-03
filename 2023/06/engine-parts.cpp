// AoC 2023 - Puzzle 05
// This problem requires to read in an input file, a table that includes part
// numbers mixed with other numbers, periods, or other symbols part numbers are
// distinguished from other numbers by being adjacent to a symbol diagonals
// included. periods are not symbols.
// The puzzle is to determine the sum of all part numbers in the table

#include <cctype>
#include <charconv>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <set>
#include <string>
#include <utility>
#include <vector>

// config

static const bool show_table = false;
static const bool debug = false;

// coordinate system:
// leftmost character is 1, increases by 1 each character going to the right
// topmost character is 1, increases by 1 each additional line

using std::uint16_t;
using std::uint32_t;
using std::as_const;

// position of a potential match between symbol and number
// assume no more than 65,536
struct point {
    uint16_t x = 0;
    uint16_t y = 0;
};

// a number that is optionally a part number
struct number {
    uint32_t value = 0;
    uint16_t x0 = 0; // start on line
    uint16_t x1 = 0; // char after end on line
    uint16_t y  = 0; // line number
    bool is_part = false;
};

using symbol_pos = uint32_t; // encodes (x,y) positions into one value

// global vars
std::set<symbol_pos> symbol_pointes;
std::vector<number> numbers;

static inline symbol_pos encoded_pos_from_point(point m)
{
    return symbol_pos(uint32_t(m.x << 16) | m.y);
}

static inline point point_from_encoded_pos(symbol_pos p)
{
    return point(p >> 16, p & 0xFFFF);
}

static void add_number(const std::string &line, uint16_t x0, uint16_t x1, uint16_t y)
{
    number new_num;

    new_num.x0 = x0;
    new_num.x1 = x1;
    new_num.y = y;

    (void) std::from_chars(line.data() + x0 - 1, line.data() + x1 - 1, new_num.value);

    numbers.push_back(new_num);
}

static void add_symbol(uint16_t x, uint16_t y)
{
    symbol_pointes.emplace(encoded_pos_from_point(point{x, y}));
}

static void decode_line(const std::string &line)
{
    static uint16_t y = 0;
    uint16_t x0 = 0;
    uint16_t x = 0;
    bool in_num = false;

    y++; // new line to process

    for (auto ch : line) {
        x++; // new char to process

        if(std::isdigit(ch)) {
            if constexpr (show_table) {
                std::cout << "\e[1;31m"; // bold red
            }

            if (!in_num) { // newly in number?
                in_num = true;
                x0 = x;
            }
        }
        else {
            if constexpr (show_table) {
                std::cout << (ch == '.' ? "\e[0;38m" : "\e[0;32m"); // gray or green
            }

            if (in_num) { // newly out of number?
                in_num = false;

                add_number(line, x0, x, y);
            }

            if (ch != '.') { // symbol
                add_symbol(x, y);
            }
        }

        if constexpr (show_table) {
            std::cout << ch;
        }
    }

    // end of the line, check for any numbers
    if (in_num) {
        add_number(line, x0, x + 1, y);
    }

    if constexpr (show_table) {
        std::cout << "\e[0m" << std::endl; // reset color
    }
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

    numbers.reserve(256);

    ifstream input;
    input.exceptions(ifstream::badbit);

    try {
        input.open(argv[1]);
        string line;
        while (!input.eof() && std::getline(input, line)) {
            decode_line(line);
        }

        input.close();
    }
    catch (ifstream::failure &e) {
        cerr << "Exception on reading input: " << e.what() << endl;
        return 1;
    }

    if constexpr (debug) {
        for (const auto &n : as_const(numbers)) {
            std::cout << n.value << "," << n.x0 << "-" << n.x1 << "," << n.y << "\n";
        }

        for (const auto &sym : as_const(symbol_pointes)) {
            point m{point_from_encoded_pos(sym)};
            std::cout << "symbol at " << m.x << "," << m.y << "\n";
        }
    }

    // look for matches
    for (const auto &sym : as_const(symbol_pointes)) {
        point m{point_from_encoded_pos(sym)};

        for (int i = -1; i < 2; i++) {
            for (int j = -1; j < 2; j++) {
                uint16_t test_x = m.x + i;
                uint16_t test_y = m.y + j;

                // ok to be out of bounds, no number will match
                for (auto &n : numbers) {
                    n.is_part = n.is_part || (n.y == test_y && test_x >= n.x0 && test_x < n.x1);
                }
            }
        }
    }

    uint32_t sum = 0;

    for (const auto &n : as_const(numbers)) {
        if (n.is_part) {
            sum += n.value;
        }
    }

    cout << sum << endl;

    return 0;
}
