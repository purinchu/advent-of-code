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
using Circuit = std::unordered_set<PtIdx>;
using Circuits = vector<Circuit>;

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
    Circuits out_circ;
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
        out.emplace_back(std::move(pt));
    }

    return out;
}

static Circuits build_circuits(const vector<Pt> &pts)
{
    return pts | stdv::transform([](const Pt &p) {
        Circuit single;
        single.emplace(p.pt_id);
        return single;
    }) | stdr::to<std::vector>();
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

static void connect_points(Circuits &circuits, const PtIdx pt1, const PtIdx pt2)
{
    auto circ_it1 = stdr::find_if(circuits, [pt1](const Circuit &c) { return c.contains(pt1); });
    auto circ_it2 = stdr::find_if(circuits, [pt2](const Circuit &c) { return c.contains(pt2); });

    if (circ_it1 == circ_it2) {
        // already part of same circuit
        return;
    }

    circ_it1->merge(*circ_it2);
    circuits.erase(circ_it2);
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

        const auto &points                = get_input_problem(fname);
        auto &&circuits                   = build_circuits(points);
        const vector<DistEntry> distances = build_dist_table(points);

        for (const auto &dt : distances) {
            connect_points(circuits, dt.from, dt.to);
            if (circuits.size() == 1) {
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
