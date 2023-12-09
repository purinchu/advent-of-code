// AoC 2023 - Puzzle 16 (Day 8, Puzzle 2)

#include <algorithm>
#include <cctype>
#include <charconv>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <iterator>
#include <numeric>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

// config

static const bool g_debug     = false;
static const bool g_show_step = false;

using std::string;
using std::vector;
using std::as_const;

struct net_node {
    string left;
    string right;
    uint32_t last_seen = 0;
};

using net_map = std::unordered_map<string, net_node>;

// global vars

string g_path;
net_map g_net;
vector<string> g_simul_nodes;

static void decode_node(const string &line)
{
    // line always looks like XYZ = (ZXC, GKW)
    g_net.emplace(
            string { line, 0, 3 },
            net_node{
             { line, 7, 3},
             { line, 12, 3 }
            });

    // starting node
    if (line[2] == 'A') {
        g_simul_nodes.emplace_back(line, 0, 3);
    }
}

static bool is_done()
{
    return std::all_of(g_simul_nodes.cbegin(), g_simul_nodes.cend(),
            [](const string &s) { return s[2] == 'Z'; } );
}

// Suggested on Stack Overflow but gives incorrect answer
constexpr auto mylcm(auto x, auto... xs)
{
    return ((x = std::lcm(x, xs)), ...);
}

// back to brute force to calculate LCM of multiple numbers at once
// Other internet-accessible solutions seem to give invalid answers
static uint64_t mult_lcm(vector<unsigned>::const_iterator start, vector<unsigned>::const_iterator end)
{
    using count_map = std::unordered_map<unsigned, unsigned>;

    auto it = start;
    count_map highest_seen;

    while(it != end) {
        count_map cur_map;
        unsigned val = *it++;
        const unsigned highest_mult = std::sqrt(val) + 1;
        unsigned divisor = 2;

        while(val > divisor && divisor < highest_mult) {
            if ((val % divisor) == 0) {
                // found a multiple
                cur_map[divisor]++;
                val /= divisor;
            } else {
                divisor++;
            }
        }

        cur_map[val]++; // Last multiplication factor

        for (const auto &cur_pair : cur_map) {
            const auto &[divisor, count] = cur_pair;
            if (count > highest_seen[divisor]) {
                highest_seen[divisor] = count;
            }
        }
    }

    uint64_t result = 1;
    for (const auto &cur_pair : highest_seen) {
        result *= (cur_pair.first * cur_pair.second);
    }

    return result;
}

static void show_simul_nodes(unsigned start)
{
    using std::cout;

    cout << start << " [";
    for (const auto &node : g_simul_nodes) {
        cout << node << ", ";
    }
    cout << "]\n";
}

int main(int argc, char **argv)
{
    using std::cerr;
    using std::cout;
    using std::endl;
    using std::ifstream;

    if (argc < 2) {
        std::cerr << "Enter a file to read\n";
        return 1;
    }

    ifstream input;
    input.exceptions(ifstream::badbit);

    try {
        input.open(argv[1]);

        // Read pathway to repeat
        std::getline(input, g_path);

        // Read network nodes
        string line;
        while (!input.eof() && std::getline(input, line)) {
            if (line.empty()) {
                continue;
            }

            decode_node(line);
        }

        input.close();
    }
    catch (ifstream::failure &e) {
        cerr << "Exception on reading input: " << e.what() << endl;
        return 1;
    }

    if (g_path.empty() || g_net.empty()) {
        cerr << "Invalid data read!\n";
        return 1;
    }

    if constexpr (0) {
        std::cout << "string path: " << g_path << "\n";
        for (const auto & node : g_net) {
            const auto & [path, netnode] = node;
            std::cout << "For " << path << "...\n";
            std::cout << "    (" << netnode.left << ", " << netnode.right << ")\n";
        }
    }

    // Starting from AAA, count steps until ZZZ
    unsigned i = 0, cur_str = 0;

    if constexpr (g_show_step) {
        show_simul_nodes(0);
    }

    vector<unsigned> cycle_lengths;
    cycle_lengths.reserve(g_simul_nodes.size());

    while (!is_done()) {
        i++;

        const auto next_dir = g_path[cur_str++];
        if (cur_str >= g_path.length()) {
            cur_str = 0;
        }

        if (next_dir == 'R') {
            for(size_t i = 0; i < g_simul_nodes.size(); i++) {
                g_simul_nodes[i] = g_net[g_simul_nodes[i]].right;
            }
        }
        else {
            for(size_t i = 0; i < g_simul_nodes.size(); i++) {
                g_simul_nodes[i] = g_net[g_simul_nodes[i]].left;
            }
        }

        for(size_t j = 0; j < g_simul_nodes.size(); j++) {
            auto &node = g_simul_nodes[j];
            if (!g_net[node].last_seen && node[2] == 'Z') {
                g_net[node].last_seen = i;
                std::cout << j << ": Node " << node << " last seen " << i << " steps ago.\n";
                cycle_lengths.push_back(i);
            }
        }

        if (cycle_lengths.size() == g_simul_nodes.size()) {
            std::cout << "Cycle detected, try this cycle count: "
                << mult_lcm(cycle_lengths.cbegin(), cycle_lengths.cend())
                << "\n";
            return 0;
        }

        if constexpr (g_show_step) {
            show_simul_nodes(i);
        }

        if (!(i & 0x001FFFFF)) {
            std::cout << "checkpoint " << i << "\n";
        }
    }

    std::cout << "Took " << i << " steps to get all nodes to **Z\n";

    return 0;
}
