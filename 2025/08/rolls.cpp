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

static void find_rolls_free(const Grid &g, vector<uint8_t> &surrounding_count)
{
    surrounding_count.assign(g.chars.size(), 0);

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

    (void) dump_grid;
//  dump_grid(g);
}

static size_t remove_free_rolls(Grid &g, const vector<uint8_t> &surrounding_count)
{
    size_t sum = 0;
    for (size_t i = 0; i < g.chars.size(); i++) {
        if (g.chars[i] == '@' && surrounding_count[i] < 4) {
            g.chars[i] = 'x';
            sum++;
        }
    }

    return sum;
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

        vector<uint8_t> surrounding_count;
        size_t sum;
        size_t total_sum = 0;

        find_rolls_free(g, surrounding_count);
        while ((sum = remove_free_rolls(g, surrounding_count)) > 0) {
            total_sum += sum;
            find_rolls_free(g, surrounding_count);
        }

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
