// AoC 2023 - Puzzle 30
//
// HASHMAP - Compile with -std=c++20 for string_view constructors

#include <algorithm>
#include <array>
#include <fstream>
#include <iostream>
#include <string>
#include <string_view>
#include <vector>

// common types

using std::string_view;
using BoxSlot = std::pair<string_view, int>; // lens ID, focal length
using Box = std::vector<BoxSlot>; // holds vector of lenses in a given order

unsigned char aoc_hash(std::string_view sv)
{
    unsigned result = 0;
    for (unsigned ch : sv) {
        result = (17 * (result + ch)) & 0xFF;
    }
    return static_cast<unsigned char>(result);
}

std::string line_from_file(const char *fname)
{
    std::ifstream input;
    std::string line;
    input.open(fname);
    std::getline(input, line);
    return line;
}

int main(int argc, char **argv)
{
    if (argc < 2) { std::cerr << "Enter a file to read\n"; return 1; }
    std::string line = line_from_file(argv[1]);

    const string_view seps = string_view("-=");

    std::array<Box, 256> boxes;
    std::string_view sv(line);

    auto start = sv.begin(); // each token will be in [start,end)
    auto end = std::find(sv.begin(), sv.end(), ',');

    while (start != sv.end()) {
        const auto name = string_view(start,
                std::find_first_of(start, end, seps.begin(), seps.end()));
        const auto code = string_view(name.end(), name.end() + 1); // - or =

        auto &box = boxes[aoc_hash(name)];
        auto existing_slot_it = std::find_if(box.begin(), box.end(),
                [name](const BoxSlot &s) { return name == s.first; });

        if (code[0] == '=') {
            int f_length = *(end - 1) - '0'; // always only one char at end

            // replace existing lens if one exists
            if (existing_slot_it != box.end()) {
                existing_slot_it->second = f_length;
            } else {
                box.emplace_back(name, f_length);
            }
        } else if (existing_slot_it != box.end()) {
            // remove lens from box it is in, if any
            box.erase(existing_slot_it);
        }

        // find next token
        start = (end == sv.end()) ? sv.end() : end + 1;
        end = std::find(start, sv.end(), ',');
    }

    // output all boxes
    unsigned long sum = 0;
    for (std::size_t i = 0; i < boxes.size(); i++) {
        const auto &slots = boxes[i];
        for (std::size_t s = 0; s < slots.size(); s++) {
            sum += (i + 1) * (s + 1) * slots[s].second;
        }
    }

    std::cout << sum << "\n";
    return 0;
}
