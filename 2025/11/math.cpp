#include <algorithm>
#include <array>
#include <chrono>
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

using namespace std::literals::chrono_literals;
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

static void tokenize_line(string_view line, const auto &func)
{
    string_view cur = skip_ws(line);
    size_t idx = 0;

    while(!cur.empty()) {
        const size_t next = cur.find(' ');
        const string_view token = cur.substr(0, next);
        cur = (next != cur.npos)
            ? skip_ws(cur.substr(next))
            : string_view{};
        func(token, idx++);
    }
}

static string inline file_slurp(const string &fname)
{
    // ::ate is used to quickly get filesize with tellg
    std::ifstream in_f(fname, std::ios::in | std::ios::ate);
    if (!in_f.is_open()) {
        throw std::runtime_error("Failed to open file");
    }

    const auto sz = in_f.tellg();
    string str(sz, '\0');
    in_f.seekg(0);
    in_f.read(str.data(), str.size());

    return str;
}

static Int sum_math_input(const string &fname)
{
    // each line a list of numbers to do math upon. last line is the math ops
    // to perform, either '+' or '*'
    const string str = file_slurp(fname);

    static constexpr const size_t MAX_PER_SUM = 4; // max number of entries to reserve per op
    using SumTerm = array<uint16_t, MAX_PER_SUM>;

    vector<SumTerm> terms;
    terms.resize(1023); // We fill with empty SumTerm on purpose so we can operator[] later

    size_t cur_line_idx = 0;

    for (const auto &subr : stdv::split(str, "\n"sv)) {
        // stdv::split is not suitable to further split the line because the
        // spaces are variable-length. So just go old-school looking for ws and
        // non-ws as needed (handled in tokenize).

        const string_view line(subr.begin(), subr.end());
        const string_view line_start(skip_ws(line));
        const char first_ch = line_start[0];

        if (first_ch == '*' || first_ch == '+') {
            // last line, read ops rather than numbers
            Int sum = 0;
            tokenize_line(line_start, [&terms, &sum](string_view tok, size_t idx) {
                if (tok[0] == '*') {
                    // multiplicative identity is 1 not default of 0
                    for (auto &i : terms[idx]) {
                        i = (i == 0) ? 1 : i;
                    }

                    sum += stdr::fold_left(terms[idx], Int(1), std::multiplies{});
                }
                else {
                    sum += stdr::fold_left(terms[idx], Int(0), std::plus{});
                }
            });

            return sum;
        }
        else {
            // data line, read numbers
            tokenize_line(line_start, [&terms, cur_line_idx](string_view tok, size_t idx) {
                terms[idx][cur_line_idx] = int_from_str(tok);
            });

            cur_line_idx++;
        }
    }

    throw std::runtime_error("This should be unreachable for normal input");
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        std::cerr << "Pass filename to read\n";
        return 1;
    }

    const string fname(argv[1]);
    try {
        using namespace std::chrono;

        const auto start = steady_clock::now();
        const Int  sum   = sum_math_input(fname);
        const auto end   = steady_clock::now();

        std::cout << sum << " (" << duration_cast<microseconds>(end - start).count() << "µs)\n";
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
