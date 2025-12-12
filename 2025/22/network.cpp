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
using MemoMap = std::unordered_map<string, Int>;
using Visited = vector<string_view>;

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

    stdr::sort(outs);
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

static Int num_paths_to(const NodeMap &n, Visited &v, MemoMap &memo, string_view from, string_view to, int flags = 0)
{
    // The input set is intractable without use of memoization. But we need to
    // make sure the key captures all inputs, including whether 0, 1 or 2 of
    // the needed nodes have been found along this path.
    const auto key = string{from.begin(), from.end()} + string{to.begin(), to.end()} + std::to_string(flags);
    if (const auto it = memo.find(key); it != memo.end()) {
        return it->second;
    }

    const auto it = n.find(from);
    if (it == n.end()) {
        return memo[key] = 0; // no edges from this node to anywhere
    }

    const auto outs = it->second;

    // base case
    if (stdr::binary_search(outs, to)) {
        const Int result = (flags == 3) ? 1 : 0;
        return memo[key] = result;
    }

    if (from == "dac"sv) { flags |= 1; }
    if (from == "fft"sv) { flags |= 2; }

    // recursive
    v.push_back(from);

    auto path_tally = [&](const auto &out) { return num_paths_to(n, v, memo, out, to, flags); };
    const Int num_paths = stdr::fold_left(outs | stdv::transform(path_tally), Int(0), std::plus{});

    v.pop_back();

    return memo[key] = num_paths;
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

        const auto data  = file_slurp(fname); // needs to outlive get_input_problem and num_paths_to
        const auto nodes = get_input_problem(data);

        Visited visited;
        MemoMap memo;

        const Int sum = num_paths_to(nodes, visited, memo, "svr"sv, "out"sv);

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
