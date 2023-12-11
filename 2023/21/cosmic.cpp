// AoC 2023 - Puzzle 21
// This problem requires to read in an input file that ultimately
// lists information about astronomical readings to find shortest
// paths among.

#include <cstdint>
#include <fstream>
#include <iostream>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

// config

static const bool show_table = true;

// coordinate system:
// leftmost character is 0, increases by 1 each character going to the right
// topmost character is 0, increases by 1 each additional line down

using std::uint16_t;
using std::uint32_t;
using std::as_const;

// We are to read in galaxies from a file. But we just need to find distances
// between pairs of galaxies, we don't actually need to retain the entire table
// of input, just the list of galaxies.
using col_t = uint16_t;
using row_t = uint16_t;
using galaxy = std::pair<col_t, row_t>;
using gal_list = std::vector<galaxy>;
using gal_pair = std::pair<int, int>; // A pair of galaxy IDs in the vector

// global vars
gal_list g_galaxies;
std::set<col_t> g_seen_columns;
col_t g_max_col = 0; // Exclusive, not inclusive

static void decode_line(const std::string &line)
{
    using std::make_pair;
    using std::string;

    static row_t y = 0;
    col_t x = 0;

    if (!g_max_col) {
        g_max_col = line.length();
    } else if (g_max_col != line.length()) {
        throw std::runtime_error("Malformed input, mangled line!");
    }

    // first check for galaxy-expanded line
    if (line.find('#') == string::npos) {
        y++; // implicitly add empty line
    }
    else {
        for (auto ch : line) {
            if(ch == '#') {
                g_galaxies.emplace_back(make_pair(x, y));
                g_seen_columns.insert(x);
            }

            x++;
        }
    }

    y++;
}

// Rows will be inflated automatically as input file is read, but we
// can't inflate columns until we're sure which ones have no galaxies.
static void inflate_columns()
{
    // make a map of column IDs to inflation amounts
    std::map<col_t, unsigned> inflate_amount;
    unsigned cur_inflation = 0;

    for (col_t col_id = 0; col_id < g_max_col; col_id++) {
        if(!g_seen_columns.contains(col_id)) {
            // column was empty, inflate everything to the right
            cur_inflation++;
        }

        inflate_amount[col_id] = cur_inflation;
    }

    // Now that we know how much inflation to perform, perform it
    for (auto &galaxy : g_galaxies) {
        auto &[x, y] = galaxy;
        x += inflate_amount[x];
    }
}

int main(int argc, char **argv)
{
    using std::cerr;
    using std::cout;
    using std::endl;
    using std::ifstream;
    using std::string;

    if (argc < 2) {
        std::cerr << "Enter a file to read\n";
        return 1;
    }

    g_galaxies.reserve(500);

    ifstream input;
    input.exceptions(ifstream::badbit);

    try {
        input.open(argv[1]);
        string line;
        while (!input.eof() && std::getline(input, line)) {
            decode_line(line);
        }

        input.close();
    }
    catch (ifstream::failure &e) {
        cerr << "Exception on reading input: " << e.what() << endl;
        return 1;
    }

    inflate_columns();

    if constexpr (show_table) {
        for (const auto &n : as_const(g_galaxies)) {
            const auto &[x, y] = n;
            std::cout << "Galaxy at " << x << ", " << y << "\n";
        }
    }

    return 0;
}
