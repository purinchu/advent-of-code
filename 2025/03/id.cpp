#include <array>
#include <charconv>
#include <fstream>
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

namespace stdr = std::ranges;
namespace stdv = std::views;

using namespace std::literals::string_literals;
using namespace std::literals::string_view_literals;

using InvSum = std::uint64_t;

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

static InvSum sum_invalid_in_range(InvSum from, InvSum upto)
{
    std::array<char, 18> buf;
    const auto is_inv = [&buf](InvSum i) {
        const auto res = std::to_chars(buf.data(), buf.data() + buf.size(), i);
        const std::string_view res_view(buf.data(), res.ptr - buf.data());
        if ((res_view.size() & 0x1) != 0) {
            return false; // odd-length cannot match
        }
        return res_view.substr(0, res_view.size() / 2) == res_view.substr(res_view.size() / 2);
    };

    auto &&inv_view = stdv::iota(from, upto + 1)
        | stdv::filter(is_inv)
        ;
//  num_invalid = stdr::fold_left(inv_view, InvSum(0), std::plus{});
    const InvSum num_invalid = std::accumulate(inv_view.begin(), inv_view.end(), InvSum(0), std::plus<InvSum>{});

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
