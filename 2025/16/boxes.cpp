#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstring>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <numeric>
#include <ranges>
#include <string>
#include <string_view>
#include <unordered_set>
#include <utility>
#include <vector>

using std::array;
using std::cout;
using std::cerr;
using std::get;
using std::pair;
using std::setw;
using std::string;
using std::string_view;
using std::make_pair;
using std::vector;
using std::tuple;
using std::size_t;

namespace stdr = std::ranges;
namespace stdv = std::views;

using Coord = std::int32_t;
using Dist = std::uint64_t;
using PtIdx = int;

struct DistEntry
{
    PtIdx from; // must be < to
    PtIdx to;   // must be > from
    Dist  dist;
};

struct Pt
{
    array<Coord, 3> xyz;
    int pt_id;
    int parent;
    int rank = 0;
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

    int pt_id = 0;
    for (const string_view &line : lines) {
        if (line.empty()) { continue; }
        auto coords = stdv::split(line, ',')
            | to_view | to_coord;

        Pt pt;
        stdr::copy(coords, pt.xyz.begin());
        pt.pt_id = pt_id++;
        pt.parent = pt.pt_id;
        out.emplace_back(std::move(pt));
    }

    return out;
}

static auto build_dist_table(const vector<Pt> &pts)
{
    vector<DistEntry> distances;
    for (const auto &[l, r] : stdv::cartesian_product(pts, pts)) {
        if (!(l.xyz < r.xyz)) {
            continue; // skip self-comparison and dual-comparison
        }

        Dist dist = std::transform_reduce(
            l.xyz.begin(), l.xyz.end(), r.xyz.begin(),
            Dist(0), std::plus{},
            [](Coord l, Coord r) {
                Coord d = r - l;
                if (d < 0) { d = -d; };
                return Dist(d) * Dist(d);
            }
        );
        distances.emplace_back(l.pt_id, r.pt_id, dist);
    }

    stdr::sort(distances, std::less{}, &DistEntry::dist);
    return distances;
}

static PtIdx find_parent_circuit(vector<Pt> &points, PtIdx x)
{
    if (points[x].parent != x) {
        points[x].parent = find_parent_circuit(points, points[x].parent);
        return points[x].parent;
    }
    else {
        return x;
    }
}

static void join_circuits(vector<Pt> &points, PtIdx x, PtIdx y)
{
    auto &&px = find_parent_circuit(points, x);
    auto &&py = find_parent_circuit(points, y);

    if (px == py) {
        // same parent, already same circuit
        return;
    }

    // sort so that x has the larger circuit and make y's circuit
    // join into x's
    if (points[px].rank < points[py].rank) {
        std::swap(px, py);
    }

    points[py].parent = px;
    if (points[px].rank == points[py].rank) {
        (points[px].rank)++;
    }

    // revalidate parent field for all potentially-affected circuits
    for (auto &&point : points) {
        if (point.parent == py) {
            point.parent = px;
        }
    }
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

        auto points = get_input_problem(fname);
        const vector<DistEntry> distances = build_dist_table(points);

        for (const auto &dt : distances) {
            join_circuits(points, dt.from, dt.to);

            // if every successive pair of points is part of the same circuit, we're done
            if (stdr::all_of(points | stdv::pairwise, [](const auto &parentpair) {
                        return (get<0>(parentpair).parent) ==
                               (get<1>(parentpair).parent);
                    }))
            {
                cout << points[dt.from].xyz[0] * points[dt.to].xyz[0];
                break;
            }
        }

        const auto stop = steady_clock::now();

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
