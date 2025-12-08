#include <algorithm>
#include <array>
#include <fstream>
#include <iostream>
#include <ranges>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

using std::array;
using std::make_pair;
using std::pair;
using std::size_t;
using std::string;
using std::string_view;
using std::vector;

namespace stdr = std::ranges;
namespace stdv = std::views;

using namespace std::literals::string_view_literals;

using Int = std::uint64_t;

static inline Int int_from_str(string_view sv)
{
    Int out = 0;
    std::from_chars(sv.data(), sv.data() + sv.size(), out);
    return out;
}

static inline auto skip_ws(string_view sv)
{
    const auto pos = sv.find_first_not_of(" "sv);
    if (pos != sv.npos) {
        return sv.substr(pos);
    }
    return string_view{};
}

static Int sum_reversed_input(const string &fname)
{
    vector<string> out_lines;
    vector<string> input;

    // each line a list of numbers to do math upon. last line is the math ops
    // to perform, either '+' or '*'. The remaining lines need to be
    // essentially transposed matrix-style, and then the part 1 code should
    // work by re-parsing the adjusted string input.
    std::ifstream in_f(fname, std::ios::in);
    if (!in_f.is_open()) {
        throw std::runtime_error("Failed to open file");
    }

    string str;
    while(std::getline(in_f, str)) {
        input.emplace_back(std::move(str));
    }

    // handle separately, these are the ops
    const string last_line(std::move(input.back()));
    input.pop_back();

    // iterate backwards and converts nums read from top to bottom to integers
    // as we go.
    string buf(input.size(), '\0');
    const size_t line_len = input[0].size();
    vector<Int> nums;
    Int sum = 0;

    for (size_t i = 0; i < line_len; i++) {
        const size_t pos = line_len - 1 - i; // to count backwards

        // transpose rows into a string.  If no number is ever detected then
        // this column was the last number in the list of numbers to operate
        // upon.
        bool has_num = false;
        for (size_t j = 0; j < input.size(); j++) {
            buf[j] = input[j][pos];
            has_num = has_num || (buf[j] != ' ');
        }

        // skip empty columns
        if (!has_num) {
            continue;
        }

        nums.emplace_back(int_from_str(skip_ws(buf)));

        // check if we have an operation to apply
        const char op = last_line[pos];
        if (op == ' ') {
            continue;
        }

        const Int val = (op == '*')
            ? stdr::fold_left(nums, Int(1), std::multiplies{})
            : stdr::fold_left(nums, Int(0), std::plus{});
        sum += val;
        nums.clear();
    }

    return sum;
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        std::cerr << "Pass filename to read\n";
        return 1;
    }

    const string fname(argv[1]);
    try {
        const Int sum = sum_reversed_input(fname);
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
