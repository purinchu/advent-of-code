// AoC 2023 - Puzzle 22
// This problem requires to read in an input file that ultimately
// lists information about astronomical readings to find shortest
// paths among.

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

// config

static const bool show_table = false;
static const bool show_pairs = false;
static const bool show_per_dist = false;

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
using gal_pair_list = std::vector<gal_pair>;

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

    // Update global tracking vars
    g_max_col += cur_inflation;
}

static gal_pair_list build_galaxy_pairs()
{
    gal_pair_list result;
    const auto num_gal = g_galaxies.size();

    result.reserve(num_gal * num_gal);

    for (size_t i = 0; i < num_gal; i++) {
        for (size_t j = i + 1; j < num_gal; j++) {
            result.emplace_back(i, j);
        }
    }

    return result;
}

// Re-output galaxy map in fashion it was read-in
static void show_pretty_galaxy()
{
    // sort by x and then by y so we can output easily
    std::sort(g_galaxies.begin(), g_galaxies.end(),
            [](const galaxy &l, const galaxy &r) { return l.first < r.first; });
    std::stable_sort(g_galaxies.begin(), g_galaxies.end(),
            [](const galaxy &l, const galaxy &r) { return l.second < r.second; });

    col_t y = 0;
    row_t x = 0;

    for (const auto &g : as_const(g_galaxies)) {
        const auto &[g_x, g_y] = g;

        // get on right line
        while (y < g_y) {
            while (x++ < g_max_col) {
                std::cout << '.';
            }
            std::cout << "\n";
            x = 0;
            y++;
        }

        // on the right line, print up until galaxy
        while (x++ < g_x) {
            std::cout << '.';
        }

        std::cout << '#';
    }

    // fill in final line
    while (x++ < g_max_col) {
        std::cout << '.';
    }

    std::cout << "\n";
}

// Return distance in discrete steps between galaxies
// Sounds complicated perhaps, but it's literally just the manhattan distance
// if you think a bit about it.
static unsigned line_distance(const galaxy &g1, const galaxy &g2)
{
    using std::abs;

    const auto &[g1_x, g1_y] = g1;
    const auto &[g2_x, g2_y] = g2;
    const uint16_t dx = abs(g2_x - g1_x);
    const uint16_t dy = abs(g2_y - g1_y);

    return dx + dy;
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
        show_pretty_galaxy();
    }

    const gal_pair_list galaxy_pairs = build_galaxy_pairs();
    uint32_t total_distances = 0;

    if constexpr (show_pairs) {
        std::cout << "\nThere are " << galaxy_pairs.size() << " pairs.\n";
        for (const auto &p : galaxy_pairs) {
            const auto &[gal1, gal2] = p;
            std::cout << "\t[" << gal1 << ", " << gal2 << "]: ";

            const auto &[gal1_x, gal1_y] = g_galaxies[gal1];
            const auto &[gal2_x, gal2_y] = g_galaxies[gal2];

            std::cout << "(" << gal1_x << "," << gal1_y << ") to ";
            std::cout << "(" << gal2_x << "," << gal2_y << ").\n";
        }
    }

    for (const auto &p : galaxy_pairs) {
        const auto &[gal1, gal2] = p;
        const auto d = line_distance(g_galaxies[gal1], g_galaxies[gal2]);

        if constexpr (show_per_dist) {
            std::cout << "Distance for " << gal1 << " to " << gal2
                << " was " << d << "\n";
        }

        total_distances += d;
    }

    std::cout << total_distances << "\n";

    return 0;
}
