#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstring>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <ranges>
#include <string>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
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
using namespace std::literals::string_view_literals;

using Int = std::uint64_t;
using NodeMap = std::unordered_map<string_view, vector<string_view>>;
using Visited = std::unordered_set<string_view>;

// Simulates a map of Node -> uint8_t. The Node serves as the index
using Graph = vector<uint8_t>; // Just use up to 64K entries to store distances

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

static inline int int_from_str(string_view sv)
{
    int out = 0;
    std::from_chars(sv.data(), sv.data() + sv.size(), out);
    return out;
}

static inline auto skip_ws(string_view sv)
{
    const auto pos = sv.find_first_not_of(" "sv);
    if (pos != sv.npos) {
        return sv.substr(pos);
    }
    return string_view{};
}

static auto decode_input_line(string_view line)
    -> pair<string_view, vector<string_view>>
{
    const auto colon_pos = line.find(':');
    const auto name = line.substr(0, colon_pos);

    vector<string_view> outs;
    auto remainder = skip_ws(line.substr(colon_pos + 1));

    while (!remainder.empty()) {
        const auto next_space = remainder.find(' ');
        if (next_space >= remainder.size()) {
            outs.emplace_back(remainder);
            remainder = string_view{};
        }
        else {
            outs.emplace_back(remainder.substr(0, next_space));
            remainder = skip_ws(remainder.substr(next_space + 1));
        }
    }

    return make_pair(name, outs);
}

static NodeMap get_input_problem(string_view lines)
{
    const auto to_view = stdv::transform([](const auto &subr) {
        // convert subranges of char* to a string_view
        return string_view(subr.begin(), subr.end());
    });

    return stdv::split(lines, '\n')
        | to_view
        | stdv::filter([](const auto &line) { return !line.empty(); })
        | stdv::transform(decode_input_line)
        | stdr::to<NodeMap>();
}

static Int num_paths_to(const NodeMap &n, Visited &v, string_view from, string_view to)
{
    const auto outs = n.at(from);

    // base case
    if (stdr::find(outs, to) != outs.end()) {
        return 1;
    }

    if (v.contains(from)) {
        return 0; // cycle detected, not a path
    }

    // recursive
    v.emplace(from);

    Int num_paths = 0;
    for (const auto out : outs) {
        num_paths += num_paths_to(n, v, out, to);
    }

    v.erase(from);

    return num_paths;
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

        const auto data  = file_slurp(fname);
        const auto nodes = get_input_problem(data);
        Visited visits;

        const Int sum = num_paths_to(nodes, visits, "you"sv, "out"sv);
        const auto stop = steady_clock::now();

        cout << sum;
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
