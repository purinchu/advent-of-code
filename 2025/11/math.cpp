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
        const auto [nums, ops] = get_math_input(fname);

        if constexpr (false) {
            for (const auto &op : ops) {
                std::cout << "op will be " << op << "\n";
            }

            for (const auto &num_line : nums) {
                std::cout << "New line of numbers: [\n";
                for (const auto &num : num_line) {
                    std::cout << "    " << num << "\n";
                }
                std::cout << "]\n";
            }
        }

        // running sum will be a pair for the add / mult, initialized with the
        // respective identity

        Term init = make_pair(0, 1); // add / mult
        TermList running_sum(ops.size(), init);

        for (const auto &num_line : nums) {
            for (size_t i = 0; i < ops.size(); i++) {
                const auto &[add_cur, mult_cur] = running_sum[i];
                const Int num = num_line[i];
                running_sum[i] = make_pair(add_cur + num, mult_cur * num);
            }
        }

        Int sum = 0;
        for (size_t i = 0; i < ops.size(); i++) {
            const auto &[add_res, mult_res] = running_sum[i];
            sum += (ops[i] == '*') ? mult_res : add_res;
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
