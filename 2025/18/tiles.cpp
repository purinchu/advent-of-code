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

struct Seg
{
    Pt p1;
    Pt p2;
};

static inline bool is_vert(const Seg &s)
{
    return s.p1.first == s.p2.first;
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

static vector<Seg> build_segments(const vector<Pt> &pts)
{
    vector<Seg> out = stdv::pairwise(pts)
        | stdv::transform([](const auto &tpl) { return Seg{get<0>(tpl), get<1>(tpl)}; })
        | stdr::to<vector>();
    out.emplace_back(pts.back(), pts.front());

    return out;
}

static auto find_highest_area(const vector<Pt> &pts)
{
    vector<Seg> segs = build_segments(pts);

    const auto is_pt_fully_inside = [&pts](const auto &pr, Pt p) {
        const Pt l = get<0>(pr);
        const Pt r = get<1>(pr);
        const auto [x1, x2] = std::minmax(l.first,  r.first);
        const auto [y1, y2] = std::minmax(l.second, r.second);

        return (p.first > x1 && p.first < x2 && p.second > y1 && p.second < y2);
    };

    const auto does_line_intersect = [&pts](const auto &pr, Seg s) {
        const Pt l = get<0>(pr);
        const Pt r = get<1>(pr);
        const auto [x1, x2] = std::minmax(l.first,  r.first);
        const auto [y1, y2] = std::minmax(l.second, r.second);
        const auto [sx1, sx2] = std::minmax(s.p1.first,  s.p2.first);
        const auto [sy1, sy2] = std::minmax(s.p1.second, s.p2.second);

        // check if a line cuts fully through. A partial cut will be caught
        // by the check for a point within the rectange.
        if (sx1 == sx2) { // vert seg
            bool res = sx1 > x1 && sx2 < x2 && (sy1 <= y1 && sy2 >= y2);
            return res;
        }
        else { // horiz seg
            bool res = sy1 > y1 && sy2 < y2 && (sx1 <= x1 && sx2 >= x2);
            return res;
        }
    };

    const auto is_valid_rect = [&](const auto &pr) {
        if (stdr::any_of(pts, [&](const Pt &p) { return is_pt_fully_inside(pr, p); })
          || stdr::any_of(segs, [&](const Seg &s) { return does_line_intersect(pr, s); })
            )
        {
            return false;
        }

        return true;
    };

    const auto find_area = [](const auto &pr) {
        const auto &[l, r] = pr;
        Coord dx = std::abs(l.first  - r.first ) + 1;
        Coord dy = std::abs(l.second - r.second) + 1;
        return Area(dx) * Area(dy);
    };

    auto &&tiles_gen = stdv::cartesian_product(pts, pts)
        | stdv::filter([](const auto &pr) { return get<0>(pr) > get<1>(pr); })
        | stdv::filter(is_valid_rect)
        | stdv::transform(find_area);

    const Area highest = stdr::max(tiles_gen);
    return highest;
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
        const Area highest = find_highest_area(points);

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
