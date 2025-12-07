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
    size_t w;
    size_t h;
};

// In case we SIMD later
static constexpr const size_t STRIDE = 8;

static Grid get_input_lines(const string &fname)
{
    Grid out;
    std::ifstream in_f(fname, std::ios::in);
    if (!in_f.is_open()) {
        throw std::runtime_error("Failed to open file");
    }

    string buf;

    while (std::getline(in_f, buf)) {
        const size_t des_sz = STRIDE * ((buf.size() + (STRIDE - 1)) / STRIDE);
        buf.resize(des_sz, '.');

        out.chars.append(buf);

        out.h++;
        out.w = buf.size();
    }

    return out;
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        cerr << "Pass filename to read\n";
        return 1;
    }

    string fname(argv[1]);

    try {
        Grid g = get_input_lines(fname);
        cout << "Grid size: " << g.w << "," << g.h << "\n";

        vector<Int> tachyons(g.w, 0); // number of beams through a cell

        for (size_t i = 0; i < g.h; i++) {
            const string_view line(&g.chars[g.w * i], g.w);

            // look for start
            const auto start_pos = line.find('S');
            if (start_pos < line.size()) {
                tachyons[start_pos] = 1;
                continue;
            }

            // look for splitters
            auto &&splitters = line | stdv::enumerate
                | stdv::filter([](const auto &tpl) { return get<1>(tpl) == '^'; });
            for (const auto [idx, ch] : splitters) {
//              cout << "line " << i << " has a splitter at " << idx << "\n";
                Int old = tachyons[idx];
                tachyons[idx - 1] += old;
                tachyons[idx + 1] += old;
                tachyons[idx    ] =  0; // shielded by splitter
            }
        }

        const Int total_sum = stdr::fold_left(tachyons, Int(0), std::plus{});
        cout << total_sum << "\n";
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
