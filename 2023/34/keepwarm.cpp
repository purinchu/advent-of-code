// AoC 2023 - Puzzle 34
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
#include <numeric>
#include <queue>
#include <string>
#include <string_view>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

#include <unistd.h>

// config

static const bool g_show_input = false;
static const bool g_show_final = true;

// common types

using std::as_const;
using std::pair;
using std::tuple;
using std::unordered_map;
using std::vector;

enum class Dir { west, east, north, south };
using pos_t = uint16_t;

struct node
{
    // assumes a node being visited will have all neighbors reachable in a
    // straight line considered, such that the *next* node will be forced to
    // turn. A node will always consider E/W or N/S turns in this situation, so
    // the only thing we need to know is whether we're looking horizontally or
    // vertically for the next move.
    pos_t row = 0;      // start node is at 0,0 with horiz=false
    pos_t col = 0;
    bool horiz = false;
    enum { normal, end } type = normal;

    bool operator==(const node& o) const = default;
};

template<>
struct std::hash<node>
{
    std::size_t operator()(const node& n) const noexcept
    {
        std::size_t h1 = std::hash<pos_t>{}(n.row);
        std::size_t h2 = std::hash<pos_t>{}(n.col);

        return h1 ^ (h2 << 1) ^ (n.horiz << 2);
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

static const char *dir_name(Dir d)
{
    switch(d) {
        case Dir::east:  return "east ";
        case Dir::west:  return "west ";
        case Dir::north: return "north";
        case Dir::south: return "south";
        default: return "ERROR";
    }
}

std::ostream& operator <<(std::ostream &os, const node &n)
{
    std::ios::fmtflags os_flags(os.flags());
    bool is_start = !n.col && !n.row;
    const char *hv = n.horiz ? " H " : " V ";

    if (n.type == node::end) {
        os << "[end node]";
        return os;
    }

    os << std::setw(2) << (n.col+1) << ","
        << std::setw(2) << (n.row+1) << " "
        << (is_start ? "H,V" : hv) << " "
        ;
    os.flags(os_flags);
    return os;
}

auto make_grid(std::ifstream &input) -> grid<uint16_t>
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
    pathfinder(const grid<uint16_t> &g, bool use_part1_rules)
        : m_g(g)
        , W(g.width())
        , H(g.height())
        , max_steps(use_part1_rules ? 3 : 10)
        , part1_rules(use_part1_rules)
    {
        // the +1 is for the end node
        distances.assign(W * H * 2 + 1, std::numeric_limits<int>::max());
    }

    void find_min_path(const node start);

    // support routines
    vector<Dir> neighbor_dirs_for_node(const node n) const {
        static const std::array horiz_dir = { Dir::east , Dir::west  };
        static const std::array  vert_dir = { Dir::south, Dir::north };

        vector<Dir> dirs;

        if (n.horiz || is_start(n)) {
            std::copy(horiz_dir.begin(), horiz_dir.end(), back_inserter(dirs));
        }

        if (!n.horiz || is_start(n)) {
            std::copy(vert_dir.begin(), vert_dir.end(), back_inserter(dirs));
        }

        return dirs;
    }

    std::pair<int, int> offset_for_dir(Dir dir) const {
        static const std::array x_off = { -1, 1, 0, 0 };
        static const std::array y_off = { 0, 0, -1, 1 };

        int dx = x_off[(int) dir];
        int dy = y_off[(int) dir];

        return {dx, dy};
    }

    bool is_start(const node &n) const { return !n.col && !n.row; };

    node end_node() const { node n{.type = node::end}; return n; };

    // distances
    std::size_t idx_from_node(const node n) const {
        if (n.type == node::end) { return distances.size() - 1; }
        return (n.row * W * 2) + (n.col * 2) + (int) n.horiz;
    };

    int dist (const node n) const { return distances[idx_from_node(n)]; };
    void set_dist (const node n, int d) { distances[idx_from_node(n)] = d; };

    // input
    const grid<uint16_t> &m_g;

    // problem state
    vector<int> distances;
    unordered_map<node, bool> was_visited;
    unordered_map<node, node> predecessors;

    // misc metadata
    int W;
    int H;
    int max_steps;
    bool part1_rules;

    // stats
    uint_fast64_t num_visits = 0, num_neighbor_passes = 0;
    uint_fast64_t cumu_visits = 0;
    uint_fast64_t num_neighbor_added = 0, num_distance_updates = 0;
};

// TODO add "const node goal" argument once we can figure out how to do a
// virtual 0-distance transition from multiple possible ending nodes at lower
// right to a single goal state
void pathfinder::find_min_path(const node start)
{
    const auto node_distance_compare = [&](const node &l, const node &r) {
        return dist(l) > dist(r);
    };

    std::priority_queue<
        node, vector<node>,
        decltype(node_distance_compare)
        > to_visit(node_distance_compare);

    set_dist(start, 0);
    to_visit.push(start);

    while(!to_visit.empty()) {
        node cur = to_visit.top();
        to_visit.pop();

        // if the end node pops up here, this is the shortest possible path
        // to it and we're done. This can be a shortcut if there's still a
        // lot of other nodes to visit.

        if (cur == end_node()) {
            std::cout << "Found end node, distance = " << dist(end_node()) << "\n";
            return;
        }

        // each visit needs to reach out to all possible nodes reachable in a
        // straight line from here and mark those neighbors to be visited as
        // appropriate.

        num_visits++;
        cumu_visits += to_visit.size();

        if (was_visited.contains(cur)) {
            // possible depending on the number of candidate nodes in flight
            // to be looked at. candidate set is supposed to be a *set*
            continue;
        }

        num_neighbor_passes++;

        auto cx = cur.col, cy = cur.row;

        // Have a single (virtual) goal node that has zero cost to transition
        // to from the any node in the lower right.
        // This relies on the other checks to ensure *this* node state was valid!
        if (cx == W - 1 && cy == H - 1) {
            node e = end_node();
            if (!was_visited.contains(e)) {
                if (dist(e) > dist(cur)) {
                    set_dist(e, dist(cur));
                    predecessors[e] = cur;

                    num_distance_updates++;
                }

                to_visit.push(e);
                num_neighbor_added++;
            }

            was_visited[cur] = true;
            continue;
        }

        // Go through all possible directions and new nodes
        for (const auto new_dir : neighbor_dirs_for_node(cur)) {
            int new_dist = dist(cur);
            auto nx = cx;
            auto ny = cy;
            auto [dx, dy] = offset_for_dir(new_dir);

            for (int steps = 1; steps <= max_steps; steps++) {
                nx += dx;
                ny += dy;

                if (nx < 0 || ny < 0 || nx >= W || ny >= H) {
                    break; // stay on the board
                }

                new_dist += (m_g.at(nx, ny) - '0');

                if (!part1_rules && steps < 4 && steps) {
                    continue; // can't turn until 4 consecutive steps
                }

                node candidate { ny, nx, (new_dir == Dir::north || new_dir == Dir::south) };

                if (!was_visited.contains(candidate)) {
                    if (dist(candidate) > new_dist) {
                        set_dist(candidate, new_dist);
                        predecessors[candidate] = cur;

                        num_distance_updates++;
                    }

                    to_visit.push(candidate);
                    num_neighbor_added++;
                }
            }
        }

        was_visited[cur] = true;
    }
}

int main(int argc, char **argv)
{
    using namespace std::chrono;
    using std::cout;

    bool part1_rules = false;
    int opt;
    while ((opt = getopt(argc, argv, "1h")) != -1) {
        switch(opt) {
            case 'h': cout << "-1 to use part 1 rules. input filename required.\n";
                return 0;
            case '1': part1_rules = true;
                break;
            default:
                std::cerr << "error detected. input filename required.\n";
                return 1;
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
    pathfinder p(g, part1_rules);

    time_point t1 = steady_clock::now();

    p.find_min_path(node{});

    time_point t2 = steady_clock::now();

    int min_dist = p.dist(p.end_node());

    auto H = g.height(), W = g.width();

    cout << "Min. distance: " << min_dist;

    if constexpr (g_show_final) {
        std::unordered_map<uint32_t,bool> on_path;

        // pre-process where path landed then print it to console
        node min_node = p.end_node();
        while(p.predecessors.contains(min_node)) {
            auto prev_node = p.predecessors[min_node];
            bool horiz = prev_node.horiz;
            if (prev_node == node{}) {
                horiz = min_node.row == 0;
            }
            if (min_node == p.end_node()) {
                // reset coord to avoid breaking trace
                min_node.row = H - 1;
                min_node.col = W - 1;
            }

            if (horiz) {
                const int dx = min_node.col > prev_node.col ? -1 : 1;
                for (auto c = min_node.col; c != prev_node.col; c += dx) {
                    on_path[(c << 16) | min_node.row] = true;
                }
            } else {
                const int dy = min_node.row > prev_node.row ? -1 : 1;
                for (auto r = min_node.row; r != prev_node.row; r += dy) {
                    on_path[(min_node.col << 16) | r] = true;
                }
            }

            on_path[(prev_node.col << 16) | prev_node.row] = true;
            min_node = prev_node;
        }

        cout << "\n";
        for (int j = 0; j < H; j++) {
            for (int i = 0; i < W; i++) {
                if (on_path.contains((i << 16) | j)) {
                    cout << "\e[31;42m" << g.at(i, j);
                } else {
                    cout << "\e[0m" << g.at(i, j);
                }
            }
            cout << "\e[0m\n";
        }

        cout << "\nstats: ";
        cout << "visits: " << p.num_visits;
        cout << ", avg visit queue: " << p.cumu_visits / p.num_visits;
        cout << ", neighbor_passes: " << p.num_neighbor_passes;
        cout << ", neighbor_added: " << p.num_neighbor_added;
        cout << ", distance_updates: " << p.num_distance_updates;
        cout << "\n";
        cout << "grid size: " << W * H;
        cout << ", avg neighbors per grid cell: " << p.num_neighbor_added / (W * H);
        cout << ", time: " << duration<double>(t2 - t1).count();
        cout << "\n";
    }

    (void) dir_name; // silence clang warning about non-use
    return 0;
}

// vim: fdm=marker:
