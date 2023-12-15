// AoC 2023 - Puzzle 30
//
// Grid stuff

#include <algorithm>
#include <array>
#include <charconv>
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
using std::string_view;
using std::pair;

using BoxSlot = pair<string_view, int>; // lens ID, focal length
using Box = vector<BoxSlot>; // holds vector of lenses in a given order
using LensMap = std::unordered_map<string_view, std::size_t>; // which Box a named Lens is in

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
    using namespace std::literals;

    if (argc < 2) {
        std::cerr << "Enter a file to read\n";
        return 1;
    }

    ifstream input;
    input.exceptions(ifstream::badbit);

    const string_view seps = "-="sv;
    std::array<Box, 256> boxes;
    LensMap lens_assignments;

    try {
        input.open(argv[1]);
        string line;
        while (!input.eof() && std::getline(input, line)) {
            std::string_view sv(line);
            auto start = sv.begin();
            auto end = std::find(sv.begin(), sv.end(), ',');

            while (start != sv.end() || end != sv.end()) {
                const auto val = std::string_view(start, end);
                (void) val; // just here in case we want it later

                const auto name = string_view(start,
                        std::find_first_of(start, end, seps.begin(), seps.end()));
                const auto code = string_view(name.end(), name.end() + 1); // - or =

                const std::size_t box_id = aoc_hash(name);
                auto &box = boxes[box_id];
                auto existing_lens_it = std::find_if(box.begin(), box.end(),
                        [name](const BoxSlot &s) { return name == s.first; });

                if (code[0] == '=') {
                    int f_length;
                    std::from_chars(code.end(), end, f_length);

                    // replace existing lens if one exists
                    if (existing_lens_it != box.end()) {
                        existing_lens_it->second = f_length;
                    } else {
                        box.emplace_back(name, f_length);
                    }
                } else {
                    // remove lens from box it is in, if any
                    if (existing_lens_it != box.end()) {
                        box.erase(existing_lens_it);
                    }
                }

                start = (end == sv.end()) ? sv.end() : end + 1;
                end = std::find(start, sv.end(), ',');
            }

            // output all boxes
            std::uint64_t sum = 0;
            for (std::size_t i = 0; i < boxes.size(); i++) {
                const auto &box = boxes[i];

                if (box.empty()) {
                    continue;
                }

                for (std::size_t s = 0; s < box.size(); s++) {
                    sum += (i + 1) * (s + 1) * (box[s].second);
                }
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
