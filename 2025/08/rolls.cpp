#include <algorithm>
#include <array>
#include <cstring>
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
using std::make_pair;
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

    static const auto ring = array { // col, row
        make_pair(-1, -1), make_pair( 0, -1), make_pair( 1, -1),
        make_pair(-1,  0),                    make_pair( 1,  0),
        make_pair(-1,  1), make_pair( 0,  1), make_pair( 1,  1),
    };

    const auto update_xy = [&g, &surrounding_count](size_t c, size_t r) {
        if (g.chars[r * g.w + c] != '@') {
            return;
        }

        for (const auto &[col, row] : ring) {
            const size_t newc = c + col;
            const size_t newr = r + row;
            if (newc < g.w && newr < g.h) {
                surrounding_count[g.w * newr + newc]++;
            }
        }
    };

    static constexpr const int STRIDE = 8;
    using StrideInt = uint64_t;
    const auto swar_at = [&g, &surrounding_count](size_t c, size_t r) {
        static_assert(sizeof(StrideInt) == STRIDE);
        StrideInt val;

        const size_t idx = r * g.w + c;
        std::memcpy(&val, &g.chars[idx], sizeof(val));
        static constexpr const StrideInt mask = ~StrideInt(0) / 255 * '@'; // every byte has @
        static constexpr const StrideInt ones = ~StrideInt(0) / 255 * 0x01;   // every byte has 0x01
        static constexpr const StrideInt topb = ~StrideInt(0) / 255 * 0x80;   // every byte has 0x80

        // See https://lemire.me/blog/2017/01/20/how-quickly-can-you-remove-spaces-from-a-string/
        // for source of this function. What it does is for each of the four
        // bytes that are zero, they are set to 0x80. The >>7 turns that to
        // 0x01. We use xor to set zero bytes that match @
        const StrideInt roll_p = val ^ mask; // bytes are 0 when @ present
        const StrideInt haszero = (((roll_p) - ones) & ~roll_p & topb);
        const StrideInt adder = haszero >> 7;
        array<uint8_t, STRIDE> out;
        array<uint8_t, STRIDE+2> conv_out {};
        std::memcpy(out.data(), &adder, STRIDE);

        // pre-process overlapped adds for rows above/below
        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < STRIDE; j++) {
                conv_out[i + j] += out[j];
            }
        }

        // update row above
        for (int j = 0; j < STRIDE + 2; j++) {
            surrounding_count[idx - g.w - 1 + j] += conv_out[j];
        }

        // update this row (left and right)
        for (int j = 0; j < STRIDE; j++) {
            surrounding_count[idx - 1 + j] += out[j];
            surrounding_count[idx + 1 + j] += out[j];
        }

        // update row below
        for (int j = 0; j < STRIDE + 2; j++) {
            surrounding_count[idx + g.w - 1 + j] += conv_out[j];
        }
    };

    // Handle special-case individually but do most processing through SWAR
    // methods

    // first row
    for (size_t c = 0; c < g.w; c++) {
        update_xy(c, 0);
    }

    for (size_t r = 1; r < (g.h - 1); r++) {
        update_xy(0, r);
        size_t c = 1;

        // meet alignment requirements
        for ( ; c < STRIDE; c++) {
            update_xy(c, r);
        }

        // c + STRIDE goes 1 too far which is why we don't need to check < g.w
        // - 1 for the last column
        while (c + STRIDE < g.w) {
            swar_at(c, r);
            c += STRIDE;
        }

        for ( ; c < g.w; c++) {
            update_xy(c, r);
        }
    }

    // last row
    for (size_t c = 0; c < g.w; c++) {
        update_xy(c, g.h - 1);
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
