// AoC 2023 - Puzzle 46
//
// Grid stuff

#include <algorithm>
#include <chrono>
#include <concepts>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <limits>
#include <map>
#include <numeric>
#include <queue>
#include <string>
#include <string_view>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

// Linux stuff
#include <sys/ioctl.h>
#include <asm/termbits.h>

#include <unistd.h>

// config

static const bool g_show_input = false;
static const bool g_draw_grid = false;
static const bool g_show_stats = false;
static const bool g_dump_edges = false;

// common types

using std::as_const;
using std::pair;
using std::tuple;
using std::unordered_map;
using std::vector;

enum class Dir { west, east, north, south };
using pos_t = int;

struct node
{
    // assumes a node being visited will have all neighbors reachable in a
    // straight line considered, such that the *next* node will be forced to
    // turn. A node will always consider E/W or N/S turns in this situation, so
    // the only thing we need to know is whether we're looking horizontally or
    // vertically for the next move.
    pos_t row = 0;      // start/end node are at any position
    pos_t col = 0;
    enum { normal, end, start } type = normal;

    bool operator==(const node& o) const = default;
    auto operator<=>(const node& o) const = default;
};

template<>
struct std::hash<node>
{
    std::size_t operator()(const node& n) const noexcept
    {
        std::size_t h1 = std::hash<pos_t>{}(n.row);
        std::size_t h2 = std::hash<pos_t>{}(n.col);

        return h1 ^ (h2 << 1);
    }
};

// coordinate system:
// leftmost character is 0, increases by 1 each character going to the right
// topmost character is 0, increases by 1 each additional line down
template <std::integral T>
struct grid
{
    using container_t = vector<char>;
    using pos_t       = T;
    using bounds_t    = std::tuple<pos_t, pos_t, int>; // start, end, step

    void add_line(const std::string &line);

    bounds_t steps_for_dir(const pos_t pos, const Dir dir) const;
    container_t extract_line(const pos_t pos, const Dir dir) const;
    void set_line(const container_t &line, const pos_t pos, const Dir dir);
    char at(const pos_t col, const pos_t row) const;

    pos_t height() const { return m_height; }
    pos_t width() const { return m_width; }
    std::string_view view() const { return std::string_view(m_grid.data(), m_width * m_height); }

    void dump_grid() const;

    public:
    container_t m_grid;
    pos_t m_width = 0, m_height = 0;
};

//{{{
template <std::integral T>
void grid<T>::add_line(const std::string &line)
{
    if(!m_width) { m_width = line.size(); }
    std::copy(line.begin(), line.end(), std::back_inserter(m_grid));
    m_height++;
}

template <std::integral T>
void grid<T>::dump_grid() const
{
    using std::cout;
    cout << "grid: " << m_width << "x" << m_height << "\n";
    for(pos_t row = 0; row < m_height; row++) {
        const auto it = &m_grid[row * m_width];
        std::copy(it, it + m_width, std::ostream_iterator<char>(cout));
        cout << "\n";
    }
}

// common code for iterating across a column or row
template <std::integral T>
auto grid<T>::steps_for_dir(const pos_t pos, const Dir dir) const
-> bounds_t
{
    pos_t start = 0, end = 0;
    int stride = 1; // can be negative

    // we will iterate up to AND INCLUDING the end
    if (dir == Dir::east || dir == Dir::west) {
        start = pos * m_width;
        end = (pos + 1) * m_width - 1;
    } else {
        start = pos;
        end = pos + m_width * (m_height - 1);
        stride = m_width;
    }

    if (dir == Dir::north || dir == Dir::west) {
        stride *= -1;
        std::swap(start, end);
    }

    end += stride; // so we can abort as soon as we see this

    return std::make_tuple(start, end, stride);
}

template <std::integral T>
auto grid<T>::extract_line(const pos_t pos, const Dir dir) const
-> container_t
{
    container_t result;
    const auto &[start, end, stride] = steps_for_dir(pos, dir);

    for (pos_t i = start; i != end; i += stride) {
        result.push_back(m_grid[i]);
    }

    return result;
}

template <std::integral T>
void grid<T>::set_line(const container_t &line, const pos_t pos, const Dir dir)
{
    const auto &[start, end, stride] = steps_for_dir(pos, dir);

    auto it = line.begin();
    for (pos_t i = start; i != end; i += stride) {
        m_grid[i] = *it++;
    }
}

template <std::integral T>
char grid<T>::at(const pos_t col, const pos_t row) const
{
    return m_grid[row * m_width + col];
}
//}}}

static std::ostream& operator <<(std::ostream &os, const node &n)
{
    std::ios::fmtflags os_flags(os.flags());

    if (n.type == node::end) {
        os << "[end node]";
        return os;
    }

    os << std::setw(2) << (n.col+1) << ","
        << std::setw(2) << (n.row+1) << " "
        << (n.type == node::start ? "(start)" : "") << " "
        << (n.type == node::end ? "(end)" : "") << " "
        ;
    os.flags(os_flags);
    return os;
}

static auto make_grid(std::ifstream &input) -> grid<uint16_t>
{
    std::string line;
    grid<uint16_t> g;

    while (!input.eof() && std::getline(input, line)) {
        g.add_line(line);
    }

    input.close();

    if constexpr (g_show_input) {
        g.dump_grid();
        std::cout << "\n";
    }

    return g;
}

struct pathfinder
{
    pathfinder(const grid<uint16_t> &g)
        : m_g(g)
        , W(g.width())
        , H(g.height())
    {
    }

    void find_intersections(const node start);

    // support routines
    vector<std::pair<int, int>> neighbor_dirs_one_step() const {
        static const std::array checkers {
            -1, 0, 1, 0, 0, -1, 0, 1
        };

        vector<std::pair<int, int>> dirs;
        for (size_t i = 0; i < checkers.size() / 2; i++) {
            dirs.emplace_back(checkers[i * 2], checkers[i * 2 + 1]);
        }

        return dirs;
    }

    bool hit_rock(pos_t nx, pos_t ny);

    node end_node() const { return node { .row = H - 1, .col = W - 2 }; };

    void add_edge(const node n1, const node n2, int dist) {
        edges[n1][n2] = dist;
        edges[n2][n1] = dist;
    }

    // distances
    node idx_from_node(const node n) const {
        return n;
    };

    int dist (const node n) const {
        const auto it = distances.find(n);
        if (it != distances.end()) {
            return it->second;
        }
        return 0;
    };

    // input
    const grid<uint16_t> &m_g;

    // problem state
    std::map<node, int> distances;
    std::map<node, bool> was_visited;
    std::map<node, std::map<node, int>> edges;

    // misc metadata
    int W;
    int H;

    // stats
    uint_fast64_t num_visits = 0, num_neighbor_passes = 0;
    uint_fast64_t cumu_visits = 0;
    uint_fast64_t num_neighbor_added = 0, num_distance_updates = 0;
};

bool pathfinder::hit_rock(pos_t nx, pos_t ny)
{
    if (nx < 0 || ny < 0 || nx >= W || ny >= H) {
        return true;
    }

    return (m_g.at(nx, ny) == '#');
}

void pathfinder::find_intersections(const node start)
{
    vector<std::tuple<node, int, int>> to_visit;

    to_visit.emplace_back(start, 0, 1); // headed south

    const node en = end_node();

    // NOTE: For this puzzle, each "node visit" is the straight-line path
    // from the node to the exit, or a steep slope. No backtracking because
    // we must only touch a path once.

    while(!to_visit.empty()) {
        auto [cur, last_dx, last_dy] = to_visit[0];
        to_visit.erase(to_visit.begin());

        // each visit needs to reach out to all possible nodes reachable in one
        // move from here and mark those neighbors to be visited as
        // appropriate.

        if (cur.col == en.col && cur.row == en.row) {
            // Visited a 'normal' end node, need to flag the virtual end node
            // as a zero-distance neighbor to make it available to finish.

            if (0) {
                std::cout << "\"" << (cur.col+1) << "," << (cur.row+1) << "\" [label=END shape=octagon]\n";
            }
            was_visited[cur] = true;
            continue;
        } else if (cur.col == 1 && cur.row == 0 && last_dy != 1) {
            if (0) {
                std::cout << "\"" << (cur.col+1) << "," << (cur.row+1) << "\" [label=START shape=octagon]\n";
            }
            // made it back to start?
            was_visited[cur] = true;
            continue;
        }

        num_neighbor_passes++;

        auto cx = cur.col, cy = cur.row;

        // ensure we're in middle of intersection
        if (cur != start) {
            if (m_g.at(cx + 1, cy) == '.' || m_g.at(cx - 1, cy) == '.' ||
                m_g.at(cx, cy + 1) == '.' || m_g.at(cx, cy - 1) == '.')
            {
                // not an intersection
                std::cerr << "Ended up starting a node not from the start, end or slope!\n";
                std::cerr << " at " << cur.col << "," << cur.row << "\n";
                throw "uh oh";
            }
        }

        // Make at least one step in the new direction
        cx += last_dx;
        cy += last_dy;
        int new_dist = 1;

        // used to keep moving until we find another node to visit
        vector<std::tuple<node, int, int>> visit_slopes;

        while(visit_slopes.empty()) {
            // Go through all possible directions and find the next step in
            // path or the slopes to visit
            vector<pair<pos_t, pos_t>> next_paths;
            const auto neighbors = neighbor_dirs_one_step();

            for (const auto &new_dir : as_const(neighbors)) {
                pos_t nx = cx;
                pos_t ny = cy;
                auto [dx, dy] = new_dir;

                nx += dx;
                ny += dy;

                if (hit_rock(nx, ny)) {
                    continue; // can't go through the rocks
                }

                // would this cause us to double back?
                if (dx == -last_dx && dy == -last_dy) {
                    continue;
                }

                // is this the final node? If so we'll introduce a single
                // virtual end node elsewhere, but need to visit the last
                // normal node to have the right distance.
                if (nx == W - 2 && ny == H - 1) {
                    visit_slopes.emplace_back(end_node(), last_dx, last_dy);
                    add_edge(cur, end_node(), new_dist + 1);
                    continue;
                }

                // otherwise still working through the path...
                next_paths.emplace_back(nx, ny);
            }

            // searched all directions, now act

            if (next_paths.empty() && visit_slopes.empty()) {
                std::cerr << "Dead end for " << cur << "\n";
                break;
            }

            if (next_paths.size() > 1 && visit_slopes.empty()) {
                node intersection{cy, cx};
                if (was_visited[intersection]) {
                    break;
                }

                if(0) {
                    std::cout << "\"" << (cur.col+1) << "," << (cur.row+1)
                        << "\"--\"" // bi-directional edge
                        << (intersection.col+1) << "," << (intersection.row+1)
                        << "\" [label=" << (new_dist) << "]\n";
                }

                add_edge(cur, intersection, new_dist);

                for (const auto &next : as_const(next_paths)) {
                    const auto [nx, ny] = next;

                    // send a feeler in each open direction
                    visit_slopes.emplace_back(node{cy, cx}, nx - cx, ny - cy);
                }
            }

            if (next_paths.size() == 1) {
                const auto [nx, ny] = next_paths[0];
                last_dx = nx - cx;
                last_dy = ny - cy;
                cx = nx;
                cy = ny;
            }

            new_dist++;
        }

        std::copy(visit_slopes.begin(), visit_slopes.end(), back_inserter(to_visit));

        was_visited[cur] = true;
    }
}

static void draw_color_grid(const pathfinder &p)
{
    using std::cout;

    // 'Qualia' color theme
    // https://www.reddit.com/r/unixporn/comments/hjzw5f/oc_qualitative_color_palette_for_ansi_terminal/fwpludj/
    using std::make_tuple;
    std::array color_cycle = {
        make_tuple(0xEF, 0xA6, 0xA2),  // color 1
        make_tuple(0x80, 0xC9, 0x90),  // color 2
        make_tuple(0xA6, 0x94, 0x60),  // color 3
        make_tuple(0xA3, 0xB8, 0xEF),  // color 4
        make_tuple(0xE6, 0xA3, 0xDC),  // color 5
        make_tuple(0x50, 0xCA, 0xCD),  // color 6
        make_tuple(0x74, 0xC3, 0xE4),  // color E
        make_tuple(0xF2, 0xA1, 0xC2),  // color D
        make_tuple(0xCC, 0xAC, 0xED),  // color C
        make_tuple(0xC8, 0xC8, 0x74),  // color B
        make_tuple(0x5A, 0xCC, 0xAF),  // color A
        make_tuple(0xE0, 0xAF, 0x85),  // color 9
    };

    // draw to console with colors indicating position
    const int H = p.m_g.height();
    const int W = p.m_g.width();

    // preprocess
    std::map<node, int> flattened_dists;
    for (const auto &edge_from : p.edges) {
        const auto &[src, edges_out] = edge_from;
        flattened_dists[src] = edges_out.size();
        for (const auto &edge_out : edges_out) {
            const auto &[dest, dist] = edge_out;
            (void) flattened_dists[dest];
        }
    }

    // terminal size
    struct winsize wsize = {};
    pos_t max_width = W;
    if (ioctl(1, TIOCGWINSZ, &wsize) == 0) {
        max_width = std::min<pos_t>(wsize.ws_col, W);
    }

    for (pos_t j = 0; j < H; j++) {
        for (pos_t i = 0; i < max_width; i++) {
            node n{.row = j, .col = i};
            if (auto d = flattened_dists[n]; d > 0) {
                const auto [cr, cg, cb] = color_cycle[d % color_cycle.size()];
                cout << "\e[48;2;" << cr << ";" << cg << ";" << cb << "m"
                    << p.m_g.at(i, j);
            } else {
                cout << "\e[0m" << p.m_g.at(i, j);
            }
        }
        cout << "\e[0m\n";
    }

    if constexpr (g_show_stats) {
        cout << "\nstats: ";
        cout << "visits: " << p.num_visits;
        cout << ", avg visit queue: " << p.cumu_visits / (p.num_visits == 0 ? 1 : p.num_visits);
        cout << ", neighbor_passes: " << p.num_neighbor_passes;
        cout << ", neighbor_added: " << p.num_neighbor_added;
        cout << ", distance_updates: " << p.num_distance_updates;
        cout << "\n";
        cout << "grid size: " << W * H;
        cout << ", avg neighbors per grid cell: " << p.num_neighbor_added / (W * H);
        cout << "\n";
    }

    cout << "Could reach " << p.was_visited.size() << " garden plots.\n";
    cout << "\n";
}

static unsigned dist_to_end(
        std::unordered_map<node, bool> &visited,
        const pathfinder &p,
        const node dest,
        const node cur
        )
{
    unsigned max_dist = 0;
    node max_node = cur;

    // check with all children for best path to the end

    auto it = p.edges.find(cur);
    if (it == p.edges.end()) {
        std::cerr << "Something screwy going on!\n";
        return 0;
    }

    if (cur == dest) {
        return 0;
    }

    visited[cur] = true;

    // it->first is cur, it->second is the map of outbound edges
    const auto &[src_node, out_edge_map] = *it;

    for (const auto &out_edge : out_edge_map) {
        const auto &[out_node, dist] = out_edge;

        if (visited[out_node]) {
            continue;
        }

        auto cur_dist = dist + dist_to_end(visited, p, dest, out_node);
        if (cur_dist > max_dist) {
            max_dist = cur_dist;
            max_node = out_node;
        }
    }

    visited[cur] = false;

    return max_dist;
}

static unsigned long count_cells_recursive(const grid<uint16_t> &g, node start)
{
    pathfinder p(g);

    p.find_intersections(start);

    if (g_draw_grid) {
        draw_color_grid(p);
    }

    // All intersections have been found, now do a brute force search for
    // all possible paths through the graph.

    node en = p.end_node();
    std::unordered_map<node, bool> visited;

    // speedup by looking for the penultimate node instead
    unsigned total_dist;

    if (p.edges[en].size() == 1) {
        node penultimate = p.edges[en].begin()->first;

        total_dist = dist_to_end(visited, p, penultimate, start);
        total_dist += p.edges[en][penultimate];
    } else {
        total_dist = dist_to_end(visited, p, en, start);
    }

    if constexpr (g_dump_edges) {
        for (const auto &edge : as_const(p.edges)) {
            const auto &[src, destmap] = edge;
            for (const auto &edge_end : destmap) {
                const auto &[dest, dist] = edge_end;
                std::cout << "Edge from " << src << " to "
                    << dest << ", distance = " << dist << "\n";
            }
        }
    }

    return total_dist;
}

int main(int argc, char **argv)
{
    using namespace std::chrono;
    using std::cout;

    int opt;
    while ((opt = getopt(argc, argv, "h")) != -1) {
        switch(opt) {
            default:
                std::cerr << "Something went wrong with getopt\n";
                return 1;
            case 'h':
                cout << "usage: " << argv[0] << " filename\n";
                return 0;
        }
    }

    if (optind >= argc) {
        std::cerr << "Enter a file to read\n";
        return 1;
    }

    std::ifstream input;
    input.open(argv[optind]);
    if (!input.is_open()) {
        std::cerr << "Unable to open " << argv[optind] << "\n";
        return 1;
    }

    auto g = make_grid(input);

//  draw_color_grid(g);

    // find start
    node start{ 0, 1 };

    time_point t1 = steady_clock::now();

    unsigned long dist = count_cells_recursive(g, start);

    time_point t2 = steady_clock::now();

    cout << "dist: " << dist << "\n";
    cout << "time: " << duration<double>(t2 - t1).count() << "\n";

    return 0;
}

// vim: fdm=marker:
