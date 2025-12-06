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

using Int         = std::uint64_t;
using Term        = pair<Int, Int>;
using NumList     = vector<Int>;     // input data
using TermList    = vector<Term>;    // running sums
using Data        = pair<vector<NumList>,vector<char>>;

static inline Int int_from_str(string_view sv)
{
    Int out;
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

static Int preprocess_input(const string &fname)
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
    string last_line(std::move(input.back()));
    input.pop_back();

    // iterate backwards and converts rows to strings
    string buf(input.size(), '\0');
    size_t line_len = input[0].size();
    vector<Int> nums;
    Int sum = 0;

    for (size_t i = 0; i < line_len; i++) {
        size_t pos = line_len - 1 - i;
        bool has_num = false;
        for (size_t j = 0; j < input.size(); j++) {
            buf[j] = input[j][pos];
            has_num = has_num || (buf[j] != ' ');
        }
        if (has_num) {
            nums.emplace_back(int_from_str(skip_ws(buf)));
            char op = last_line[pos];
            if (op == '*') {
                Int val = stdr::fold_left(nums, Int(1), std::multiplies{});
                sum += val;
            }
            else if (op == '+') {
                Int val = stdr::fold_left(nums, Int(0), std::plus{});
                sum += val;
            }
        }
        else {
            nums.clear();
        }
    }

    return sum;
}

static Data get_math_input(const string &fname)
{
    // each line a list of numbers to do math upon. last line is the math ops
    // to perform, either '+' or '*'
    std::ifstream in_f(fname, std::ios::in);
    if (!in_f.is_open()) {
        throw std::runtime_error("Failed to open file");
    }

    vector<NumList> lines;
    vector<char>    ops;
    string str;
    while(std::getline(in_f, str)) {
        // stdv::split is not suitable because the spaces are variable-length
        // and may or may not start off a line. So just go old-school looking
        // for ws and non-ws as needed.

        NumList cur_line;
        string_view cur = skip_ws(str);
        size_t next = cur.find(" "sv);

        if (cur.starts_with("*"sv) || cur.starts_with("+"sv)) {
            // last line, read ops rather than numbers
            while(!cur.empty()) {
                string_view op = cur.substr(0, next);
                cur = skip_ws(cur.substr(next));
                if (!cur.empty()) {
                    next = cur.find(" "sv);
                    if (next == cur.npos) {
                        next = cur.size();
                    }
                }

                ops.emplace_back(op[0]);
            }
        }
        else {
            // data line, read numbers
            while(!cur.empty()) {
                Int cur_val = int_from_str(cur.substr(0, next));
                cur = skip_ws(cur.substr(next));
                if (!cur.empty()) {
                    next = cur.find(" "sv);
                    if (next == cur.npos) {
                        next = cur.size();
                    }
                }

                cur_line.emplace_back(cur_val);
            }

            lines.emplace_back(std::move(cur_line));
        }
    }

    return make_pair(std::move(lines), std::move(ops));
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        std::cerr << "Pass filename to read\n";
        return 1;
    }

    const string fname(argv[1]);
    try {
        Int sum = preprocess_input(fname);
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
