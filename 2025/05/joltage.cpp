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
    auto &&pipeline = batts
        | stdv::transform([](char c) -> int { return c - '0'; })
        | stdv::pairwise
        ;
    U64 sum = stdr::fold_left(pipeline, 0ul, [](U64 cur, const auto &chs) {
        const auto &[tens, ones] = chs;
        const auto prev_ten = cur / 10;

        // going pairwise, we could possibly use the 'tens' as a new value for a future 'ones' to improve on, or
        // use the 'ones' to update a past 'tens', or
        // use none of these because it would be worse
        const auto candidates = std::array<U64, 3> { tens * 10u + ones, prev_ten * 10u + ones, cur };
        return stdr::max(candidates);
    });

    return sum;
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
