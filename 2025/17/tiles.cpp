#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
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
using std::pair;
using std::string;
using std::string_view;
using std::make_pair;
using std::vector;
using std::tuple;
using std::size_t;

namespace stdr = std::ranges;
namespace stdv = std::views;

using Coord = std::int32_t;
using Area = std::uint64_t;
using Pt = pair<Coord, Coord>;

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

static inline Coord int_from_str(string_view sv)
{
    Coord out = 0;
    std::from_chars(sv.data(), sv.data() + sv.size(), out);
    return out;
}

static vector<Pt> get_input_problem(const string &fname)
{
    const auto to_view = stdv::transform([](const auto &subr) {
        // convert subranges of char* to a string_view
        return string_view(subr.begin(), subr.end());
    });
    const auto to_coord = stdv::transform([](const string_view sv) {
        return int_from_str(sv);
    });

    vector<Pt> out;
    const string file_data = file_slurp(fname);

    auto lines = stdv::split(file_data, '\n')
        | to_view;

    for (const string_view &line : lines) {
        if (line.empty()) { continue; }
        auto coords = stdv::split(line, ',')
            | to_view | to_coord;

        out.emplace_back(make_pair(*(coords.begin()), *(++coords.begin())));
    }

    return out;
}

static auto build_area_table(const vector<Pt> &pts)
{
    vector<Area> areas;
    for (const auto &[l, r] : stdv::cartesian_product(pts, pts)) {
        if (!(l < r)) {
            continue; // skip self-comparison and dual-comparison
        }

        Coord dx = std::abs(l.first  - r.first ) + 1;
        Coord dy = std::abs(l.second - r.second) + 1;

        areas.emplace_back(Area(dx) * Area(dy));
    }

    return areas;
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

        const auto points = get_input_problem(fname);
        const vector<Area> areas = build_area_table(points);

        const Area highest = stdr::max(areas);

        const auto stop = steady_clock::now();

        cout << highest;
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
