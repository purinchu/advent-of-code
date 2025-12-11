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

using Node = std::uint16_t;
using Toggles = array<Node, 14>; // space for up to 14 toggle buttons
using Joltage = array<std::uint16_t, 10>; // space for up to 10 joltages
using Machine = tuple<Node, Toggles, Joltage>;

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

static inline auto chars_between(string_view str, char l, char r)
{
    if (str[0] != l) {
        throw std::runtime_error("Can't find ch");
    }

    const auto pos = str.find(r);
    return make_pair(str.substr(1, pos - 1), str.substr(pos));
}

static Machine decode_input_line(string_view line)
{
    auto [light_req, btn_pos] = chars_between(line, '[', ']');
    auto btn_start = skip_ws(btn_pos.substr(1));

    size_t idx = 0;
    Node end_state = 0;
    for (const char ch : light_req) {
        if (ch == '#') {
            end_state |= (1 << idx);
        }
        idx++;
    }

    Toggles toggles = {}; // array of bits to toggle when pressed
    idx = 0;
    while (btn_start.front() == '(') {
        auto [nums, num_end] = chars_between(btn_start, '(', ')');
        btn_start = skip_ws(num_end.substr(1));
        uint16_t cur_toggle = 0;

        for (const char ch : nums) {
            if (ch == ',') {
                continue;
            }
            int i = ch - '0';
            cur_toggle |= (1 << i);
        }

        toggles[idx++] = cur_toggle;
    }

    const auto to_view = stdv::transform([](const auto &subr) {
        // convert subranges of char* to a string_view
        return string_view(subr.begin(), subr.end());
    });

    Joltage j = {};

    auto [joltages, jolt_end] = chars_between(btn_start, '{', '}');
    auto num_it = stdv::split(joltages, ',')
        | to_view
        | stdv::transform(int_from_str);
    idx = 0;
    for (const int jolt : num_it) {
        j[idx++] = jolt;
    }

    return Machine(end_state, std::move(toggles), std::move(j));
}

static vector<Machine> get_input_problem(const string &fname)
{
    const auto to_view = stdv::transform([](const auto &subr) {
        // convert subranges of char* to a string_view
        return string_view(subr.begin(), subr.end());
    });

    return stdv::split(file_slurp(fname), '\n')
        | to_view
        | stdv::filter([](const auto &line) { return !line.empty(); })
        | stdv::transform(decode_input_line)
        | stdr::to<std::vector>();
}

static int solve_machine(const Node goal, const Toggles &ts)
{
    // Djikstra! Go search through potential next steps until we find the
    // goal.

    Graph distances(65536, std::numeric_limits<uint8_t>::max());
    vector<Node> node_queue;
    node_queue.reserve(128);

    node_queue.emplace_back(0); // start state
    distances[0] = 0;

    while(!node_queue.empty()) {
        Node cur = node_queue.back();
        uint8_t cur_distance = distances[cur];
        node_queue.pop_back();

        // Did we find the end state?
        if (cur == goal) {
            return distances[cur];
        }

        // Find neighbors
        const uint8_t new_dist = 1 + cur_distance;
        for (const Node n : ts) {
            if (n == 0) {
                continue;
            }

            const Node new_node = n ^ cur;
            const uint8_t cur_dist = distances[new_node];

            if (cur_dist > new_dist) {
                // better path
                distances[new_node] = new_dist;
                node_queue.push_back(new_node);
            }
        }

        // ensure sorted to find shortest paths first
        stdr::sort(node_queue, std::greater{}, [&distances](const Node &n)
                { return distances[n]; });
    }

    throw std::runtime_error("Couldn't solve machine!");
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

        auto pipeline = get_input_problem(fname)
            | stdv::transform([](const auto &tpl) {
                    const auto &[goal, toggles, _] = tpl;
                    return solve_machine(goal, toggles);
                });
        const int sum = stdr::fold_left(pipeline, 0, std::plus{});

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
