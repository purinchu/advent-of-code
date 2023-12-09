// AoC 2023 - Puzzle 15 (Day 8, Puzzle 1)

#include <algorithm>
#include <cctype>
#include <charconv>
#include <cstdint>
#include <fstream>
#include <future>
#include <iostream>
#include <limits>
#include <sstream>
#include <string>
#include <thread>
#include <unordered_map>
#include <utility>
#include <vector>

// config

static const bool g_debug = false;
static const bool g_debug_thread_setup = true;
static const bool g_debug_checkpoints = true;

using std::uint16_t;
using std::uint32_t;
using std::string;
using std::as_const;

struct net_node {
    string left;
    string right;
};

using net_map = std::unordered_map<string, net_node>;

// global vars

string g_path;
net_map g_net;

static void decode_node(const string &line)
{
    // line always looks like XYZ = (ZXC, GKW)
    g_net.emplace(
            string { line, 0, 3 },
            net_node{
             { line, 7, 3},
             { line, 12, 3 }
            });
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
    string cur_node = "AAA";
    unsigned i = 0, cur_str = 0;
    while (cur_node != "ZZZ") {
        i++;

        const auto next_dir = g_path[cur_str++];
        if(cur_str >= g_path.length()) {
            cur_str = 0;
        }

        const auto &temp = g_net[cur_node];
        cur_node = (next_dir == 'R') ? temp.right : temp.left;
    }

    std::cout << "Took " << i << " steps to get to ZZZ\n";

    return 0;
}
