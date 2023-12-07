// AoC 2023 - Puzzle 10
//
// BRUTE FORCE
//

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

struct seed_map {
    uint32_t start;
    uint32_t len;
    int32_t offset;
};

using seed_vector = std::vector<seed_map>;

// global vars

std::vector<std::pair<uint32_t, uint32_t>> seeds;
std::unordered_map<string, string> name_maps;
std::unordered_map<string, seed_vector> id_maps;

string src;
string dest;

static void read_seeds(const string &line)
{
    std::istringstream ibuf(line);
    uint32_t start, len;

    ibuf.ignore(100, ':');
    ibuf >> std::ws; // skip whitespace

    while (!ibuf.eof()) {
        ibuf >> start >> len;

        seeds.push_back(std::make_pair(start, len));
    }
}

static void read_map_id(const string &line)
{
    char buf[128];
    std::istringstream ibuf(line);

    ibuf.get(buf, sizeof buf, '-');
    src = string{buf};
    ibuf.ignore(4, '\n');

    ibuf.get(buf, sizeof buf, ' ');
    dest = string{buf};

    name_maps[src] = dest;
    (void) id_maps[src].size(); // create vector
}

static void read_map_range(const string &line)
{
    std::istringstream ibuf(line);
    uint32_t dest_place, src_place, len;

    ibuf >> dest_place >> src_place >> len;

    id_maps[src].emplace_back(src_place, len, dest_place - src_place);
}

static void decode_line(const string &line)
{
    using std::cout;

    if (line.find("seeds:") != std::string::npos) {
        read_seeds(line);
    }
    else if (line.find("map:") != std::string::npos) {
        read_map_id(line);
    }
    else if (line.size() != 0) {
        read_map_range(line);
    }
}

static int32_t find_match_offset(const string &group, uint32_t id)
{
    const seed_vector &group_ranges = as_const(id_maps).find(group)->second;

    const auto &res = std::find_if(group_ranges.begin(), group_ranges.end(), [id](const seed_map &m) {
            return id >= m.start && (id - m.start) < m.len;
            });

    // a group may not match, in which case the offset is defined to be 0
    if (res != group_ranges.end()) {
        return res->offset;
    }

    return 0;
}

static uint32_t location_from_seed(uint32_t seed_id)
{
    string cur_source = "seed";
    const string last_source = "location";
    uint32_t cur_id = seed_id;

    while (cur_source != "location") {
        const auto cur_dest = name_maps[cur_source];
        if constexpr (g_debug) {
            std::cout << cur_source << " " << cur_id << "\n";
        }

        cur_id += find_match_offset(cur_source, cur_id);
        cur_source = cur_dest;
    }

    if constexpr (g_debug) {
        std::cout << "location " << cur_id << "\n";
    }

    return cur_id;
}

struct alignas(std::hardware_destructive_interference_size) work_package
{
    std::vector<std::pair<uint32_t, uint32_t>> seeds;
    uint32_t min_loc_result = 0;
};

static void find_min_one_thread(work_package &w)
{
    const auto id = std::this_thread::get_id();

    uint32_t min_loc = std::numeric_limits<uint32_t>::max();
    uint32_t count = 0;

    for (const auto &seed_pair : as_const(w.seeds)) {
        const auto [start, len] = seed_pair;
        for (uint32_t i = 0; i < len; i++) {
            const auto loc = location_from_seed(start + i);
            min_loc = (min_loc < loc) ? min_loc : loc;
        }

        if constexpr (g_debug_checkpoints) {
            count += len;

            if (count >= 1000000) {
                std::cout << "checkpoint [" << id << "] processed " << count
                    << " since last checkpoint. Cur min = " << min_loc << "\n";
                count = 0;
            }
        }
    }

    w.min_loc_result = min_loc;
}

static uint32_t find_min_loc_threaded()
{
    std::vector<work_package> thread_work;
    const unsigned max_threads = std::thread::hardware_concurrency();
    thread_work.resize(max_threads);

    // Break up into batches for each thread to work on
    for (const auto &seed_set : seeds) {
        const auto [first, len] = seed_set;
        uint32_t batch_size = len / max_threads;

        if (batch_size == 0) {
            batch_size = 1;
        }

        uint32_t start = first;
        uint32_t num_left = len;
        int i = 0;

        while (num_left > 0) {
            uint32_t this_size = (num_left > batch_size) ? batch_size : num_left;

            if ((unsigned) i == max_threads - 1) {
                this_size = num_left;
            }

            thread_work[i].seeds.push_back(std::make_pair(start, this_size));

            if constexpr (g_debug_thread_setup) {
                std::cout << "Thread " << i << " will work on start = " << start
                    << " and size = " << this_size << "\n";
            }

            ++i;
            num_left -= this_size;
            start += this_size;
        }
    }

    std::vector<std::jthread*> thread_array;
    thread_array.reserve(max_threads);

    for (unsigned i = 0; i < max_threads; i++) {
        thread_array[i] = new std::jthread(find_min_one_thread, std::ref(thread_work[i]));
        std::cout << "Created thread " << i << "\n";
    }

    uint32_t min_loc = std::numeric_limits<uint32_t>::max();

    for (unsigned i = 0; i < max_threads; i++) {
        thread_array[i]->join();
        delete thread_array[i];
        thread_array[i] = nullptr;

        const uint32_t loc = thread_work[i].min_loc_result;
        std::cout << "Thread " << i << " done! Min was: " << loc << "\n";

        min_loc = (min_loc < loc) ? min_loc : loc;
    }

    return min_loc;
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

    seeds.reserve(256);

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

    if constexpr (0) {
        for (const auto & node : name_maps) {
            std::cout << node.first << " maps to " << node.second << "\n";
        }

        for (const auto & node : id_maps) {
            std::cout << "For " << node.first << "...\n";
            for (const auto & bleh : node.second) {
                std::cout
                    << "\tstart: " << bleh.start
                    << ", len: " << bleh.len
                    << ", offset: " << bleh.offset
                    << "\n";
            }
        }
    }

    uint32_t min_loc = find_min_loc_threaded();

    std::cout << "Lowest location found: " << min_loc << "\n";

    return 0;
}
