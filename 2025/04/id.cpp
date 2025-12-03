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

using std::tuple;
using std::string;
using std::vector;
using std::size_t;
using std::string_view;

namespace stdr = std::ranges;
namespace stdv = std::views;

using namespace std::literals::string_literals;
using namespace std::literals::string_view_literals;

using InvSum = std::uint64_t;
using str_chunks = vector<string_view>;

static string get_input_line(const string &fname)
{
    std::ifstream in_f(fname, std::ios::in);
    if (!in_f.is_open()) {
        throw std::runtime_error("Failed to open file");
    }

    string out;
    std::getline(in_f, out);
    return out;
}

static void chunk_str_by_n(string_view s, int chunk_size, str_chunks &out)
{
    size_t pos = 0;

    out.clear();
    while (pos < s.size()) {
        out.emplace_back(s.substr(pos, chunk_size));
        pos += chunk_size;
    }
}

static constexpr void n_divisors(int n, vector<int> &out)
{
    // all divisors that evenly divide into n, excluding n itself
    switch (n) {
        case 2 : out.assign({ 1 }); return;
        case 3 : out.assign({ 1 }); return;
        case 4 : out.assign({ 1, 2 }); return;
        case 5 : out.assign({ 1 }); return;
        case 6 : out.assign({ 1, 2, 3 }); return;
        case 7 : out.assign({ 1 }); return;
        case 8 : out.assign({ 1, 2, 4 }); return;
        case 9 : out.assign({ 1, 3 }); return;
        case 10: out.assign({ 1, 2, 5 }); return;
        default: {
            std::println("Invalid divisor {}", n);
            throw std::runtime_error("Invalid divisor");
        }
    }
}

static InvSum sum_invalid_in_range(InvSum from, InvSum upto)
{
    std::array<char, 18> buf;
    vector<int> divs(4);
    str_chunks chunks;

    const auto is_inv = [&chunks, &buf, &divs](InvSum i) {
        const auto res = std::to_chars(buf.data(), buf.data() + buf.size(), i);
        const std::string_view res_view(buf.data(), res.ptr - buf.data());

        n_divisors(res_view.size(), divs);
        return stdr::any_of(divs, [&chunks, &res_view](const int divisor) {
            chunk_str_by_n(res_view, divisor, chunks);
            const auto ret = stdr::unique(chunks);
            return stdr::distance(chunks.begin(), ret.begin()) == 1;
        });
    };

    auto &&inv_view = stdv::iota(from, upto + 1)
        | stdv::filter([](InvSum i) { return i >= 10; }) // so we don't try to divisor 1-digit nums
        | stdv::filter(is_inv)
        ;
    const InvSum num_invalid = stdr::fold_left(inv_view, InvSum(0), std::plus<InvSum>{});

    return num_invalid;
}

static auto bounds_from_range(std::string_view rng)
    -> tuple<InvSum, InvSum>
{
    size_t pos = rng.find("-"sv);

    const auto left = rng.substr(0, pos);
    const auto right = rng.substr(pos + 1);

    InvSum outl, outr;
    std::from_chars(left.data(), left.data() + left.size(), outl);
    std::from_chars(right.data(), right.data() + right.size(), outr);

    return std::make_tuple(outl, outr);
}

static InvSum sum_invalid_in_line(std::string_view line)
{
    // break line into subranges divided by ','
    InvSum inv = 0;
    for (const auto &subr : stdv::split(line, ","sv)) {
        const std::string_view rng(subr.begin(), subr.end());
        const auto [l, r] = bounds_from_range(rng);
        inv += sum_invalid_in_range(l, r);
    }

    return inv;
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        std::println("Pass filename to read");
        return 1;
    }

    string fname(argv[1]);

    try {
        const InvSum sum = sum_invalid_in_line(get_input_line(fname));
        std::println("{} invalid IDs", sum);
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
