#include <algorithm>
#include <array>
#include <cstring>
#include <iostream>
#include <fstream>
#include <ranges>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

using std::array;
using std::cout;
using std::cerr;
using std::get;
using std::string;
using std::string_view;
using std::make_pair;
using std::vector;
using std::tuple;
using std::size_t;

namespace stdr = std::ranges;
namespace stdv = std::views;

using Int = std::uint64_t;

struct Grid
{
    string chars;
    size_t w = 0;
    size_t h = 0;
};

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

static Grid get_input_lines(const string &fname)
{
    Grid out { file_slurp(fname) };
    out.w = out.chars.find('\n');
    out.h = stdr::count(out.chars, '\n');

    return out;
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        cerr << "Pass filename to read\n";
        return 1;
    }

    string fname(argv[1]);
    cout.sync_with_stdio(false);

    try {
        Grid g = get_input_lines(fname);
        cout << "Grid size: " << g.w << "," << g.h << "\n";

        vector<Int> tachyons(g.w, 0); // number of beams through a cell
        bool start_found = false;
        unsigned num_splits = 0;

        for (const auto &subr : stdv::split(g.chars, '\n')) {
            const string_view line(subr.begin(), subr.end());

            // look for start
            if (!start_found) [[unlikely]] {
                const auto start_pos = line.find('S');
                if (start_pos < line.size()) {
                    tachyons[start_pos] = 1;
                    start_found = true;
                    continue;
                }
            }

            // look for splitters
            auto &&splitters = line
                | stdv::enumerate
                | stdv::filter([](const auto &tpl) { return get<1>(tpl) == '^'; })
                ;

            for (const auto [idx, ch] : splitters) {
                const Int old = tachyons[idx];
                tachyons[idx - 1] += old;
                tachyons[idx + 1] += old;
                tachyons[idx    ]  = 0; // shielded by splitter
                if (old > 0) {
                    num_splits++;
                }
            }
        }

        const Int total_sum = stdr::fold_left(tachyons, Int(0), std::plus{});
        cout << "sum=" << total_sum << ", splits=" << num_splits << "\n";
    }
    catch (std::runtime_error &err) {
        cerr << "Error " << err.what() << " while handling " << fname << "\n";
        return 1;
    }
    catch (...) {
        cerr << "Unknown error handling " << fname << "\n";
        return 1;
    }

    return 0;
}
