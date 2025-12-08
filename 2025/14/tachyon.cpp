#include <algorithm>
#include <array>
#include <chrono>
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
        using namespace std::chrono;

        const auto start = steady_clock::now();

        Grid g = get_input_lines(fname);
        cout << "Grid size: " << g.w << "," << g.h << "\n";

        vector<Int> tachyons(g.w, 0); // number of beams through a cell
        unsigned num_splits = 0;

        // this is a wee bit clunky but I don't want to have a boolean check
        // while we're iterating through the meat of the range, so break out
        // the start stuff into a manually-advanced loop and then do a normal
        // range-based loop afterwards.
        auto lines = stdv::split(g.chars, '\n')
            | stdv::transform([](const auto &subr) {
                // each line will start as a subrange that must be manually
                // converted to a std::string_view.
                return string_view(subr.begin(), subr.end());
            });

        auto it = lines.begin();
        while (it != lines.end()) {
            const string_view line(*it);
            ++it;

            const size_t pos = line.find('S');
            if (pos < line.size()) {
                tachyons[pos] = 1;
                break;
            }
        }

        const auto remainder = stdr::subrange(it, stdr::end(lines));

        for (const string_view line : remainder) {
            auto splitters = line
                | stdv::enumerate
                | stdv::filter([](const auto &tpl) { return get<1>(tpl) == '^'; })
                | stdv::keys // get the first element which is the index
                ;

            for (const size_t idx : splitters) {
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

        const auto stop   = steady_clock::now();

        cout << "sum=" << total_sum << ", splits=" << num_splits;
        cout << " (" << duration_cast<microseconds>(stop - start).count() << "µs)\n";
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
