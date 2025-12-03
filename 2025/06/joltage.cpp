#include <algorithm>
#include <array>
#include <charconv>
#include <fstream>
#include <future>
#include <numeric>
#include <print>
#include <ranges>
#include <string>
#include <string_view>
#include <vector>

using std::array;
using std::tuple;
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
using str_chunks = vector<string_view>;

string get_input_line(const string &fname)
{
    std::ifstream in_f(fname, std::ios::in);
    if (!in_f.is_open()) {
        throw std::runtime_error("Failed to open file");
    }

    string out;
    std::getline(in_f, out);
    return out;
}

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

    using Bs = std::array<int, NUM_BATTERIES>;

    const Bs sum = stdr::fold_left(pipeline, Bs{}, [](Bs cur, const stdr::viewable_range auto &window) {
        // window is a std::ranges::viewable_range
        auto &&it = cur.begin(); // we'll update this as we iterate the range

        bool reset = false;
        for (const auto &place : window) {
            // once we find a place value to update, all place values that come after need to be
            // reset.
            if (place > *it || reset) {
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
        std::println("Pass filename to read");
        return 1;
    }

    string fname(argv[1]);

    try {
        const Batteries batts = get_input_lines(fname);
        U64 sum{};
        for (const string &b : batts) {
            sum += get_joltage(b);
        }
        std::println("{}", sum);
    }
    catch (std::runtime_error &err) {
        std::println("Error {} while handling {}", err.what(), fname);
        return 1;
    }
    catch (...) {
        std::println("Unknown error handling {}", fname);
        return 1;
    }

    return 0;
}
