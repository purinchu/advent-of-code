#include <algorithm>
#include <array>
#include <fstream>
#include <iostream>
#include <ranges>
#include <string>
#include <string_view>
#include <vector>

using std::array;
using std::string;
using std::vector;
using std::size_t;
using std::string_view;

namespace stdr = std::ranges;
namespace stdv = std::views;

using namespace std::literals::string_literals;
using namespace std::literals::string_view_literals;

using Batteries = vector<string>;
using U64 = std::uint64_t;

static Batteries get_input_lines(const string &fname)
{
    Batteries out;
    std::ifstream in_f(fname, std::ios::in);
    if (!in_f.is_open()) {
        throw std::runtime_error("Failed to open file");
    }

    string buf;
    while (std::getline(in_f, buf)) {
        out.emplace_back(buf);
    }

    return out;
}

static U64 get_joltage(std::string_view batts)
{
    const constexpr size_t NUM_BATTERIES = 12;
    auto &&pipeline = batts
        | stdv::transform([](char c) -> int { return c - '0'; })
        | stdv::slide(NUM_BATTERIES)
        ;

    using Bs = std::array<uint8_t, NUM_BATTERIES>;

    const Bs sum = stdr::fold_left(pipeline, Bs{}, [](Bs cur, const stdr::viewable_range auto &window) {
        // we'll update this in sync with iterating the window range, which is
        // going to be a forward-only view rather than random-access.
        auto &&it = cur.begin();

        bool reset = false;
        for (const auto &place : window) {
            // once we find a place value to update, all place values that come after need to be
            // reset.
            if (reset || place > *it) {
                reset = true;
                *it = place;
            }

            ++it;
        }

        return cur;
    });

    // The result is an array of 0-9 that must be turned into a binary digit by reduction
    return stdr::fold_left(sum, U64{}, [](U64 cur, int d) {
        return cur * 10 + d;
    });
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        std::cerr << "Pass filename to read\n";
        return 1;
    }

    string fname(argv[1]);

    try {
        const Batteries batts = get_input_lines(fname);
        U64 sum{};
        for (const string &b : batts) {
            sum += get_joltage(b);
        }

        std::cout << sum << "\n";
    }
    catch (std::runtime_error &err) {
        std::cerr << "Error " << err.what() << " while handling " << fname << "\n";
        return 1;
    }
    catch (...) {
        std::cerr << "Unknown error handling " << fname << "\n";
        return 1;
    }

    return 0;
}
