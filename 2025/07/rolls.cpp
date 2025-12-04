#include <algorithm>
#include <array>
#include <charconv>
#include <iostream>
#include <fstream>
#include <future>
#include <numeric>
#include <ranges>
#include <string>
#include <string_view>
#include <vector>

using std::array;
using std::tuple;
using std::cout;
using std::cerr;
using std::string;
using std::vector;
using std::size_t;
using std::string_view;

namespace stdr = std::ranges;
namespace stdv = std::views;

struct Grid
{
    string chars;
    size_t w;
    size_t h;
};

static Grid get_input_lines(const string &fname)
{
    Grid out;
    std::ifstream in_f(fname, std::ios::in);
    if (!in_f.is_open()) {
        throw std::runtime_error("Failed to open file");
    }

    string buf;
    while (std::getline(in_f, buf)) {
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
        const Grid g = get_input_lines(fname);
        cout << "Grid size: " << g.w << "," << g.h << "\n";

        vector<uint8_t> surrounding_count(g.chars.size(), 0);

        const auto dump_grid = [&surrounding_count](const Grid &g) {
            for (size_t i = 0; i < g.h; i++) {
                for (size_t j = 0; j < g.w; j++) {
                    const size_t idx = j + i * g.w;
                    if (g.chars[idx] == '@' && surrounding_count[idx] < 4) {
                        cout << "\e[0;30m\e[46m" << (int) surrounding_count[j + i * g.w] << "\e[0m";
                    }
                    else {
                        cout << (int) surrounding_count[j + i * g.w];
                    }
                }
                cout << "\n";
            }
            cout << "---\n\n";
        };

        for (size_t i = 0; i < g.chars.size(); i++) {
            if (g.chars[i] != '@') {
                continue;
            }
            size_t c = i % g.w;
            size_t r = i / g.w;

            using std::make_pair;
            const auto ring = array { // col, row
                make_pair(-1, -1), make_pair( 0, -1), make_pair( 1, -1),
                make_pair(-1,  0),                    make_pair( 1,  0),
                make_pair(-1,  1), make_pair( 0,  1), make_pair( 1,  1),
            };

            for (const auto &[col, row] : ring) {
                const size_t newc = c + col;
                const size_t newr = r + row;
                if (newc < g.w && newr < g.h) {
                    surrounding_count[g.w * newr + newc]++;
                }
            }
        }

        dump_grid(g);

        size_t sum = 0;
        for (size_t i = 0; i < g.chars.size(); i++) {
            if (g.chars[i] == '@' && surrounding_count[i] < 4) {
                sum++;
            }
        }

        cout << sum << "\n";
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
