// AoC 2023 - Puzzle 42
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
static const bool g_show_stats = false;
static const bool g_use_doublesteps = false;
static const bool g_show_distances = false;

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

#if 0
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
#endif

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
        distances.assign(W * H * 2, std::numeric_limits<int>::max());
    }

    void find_min_path(const node start, const int max_steps);

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

    vector<std::pair<int, int>> neighbor_dirs_for_node() const {
        static const std::array checkers {
            -2, 0,  2, 0 , 0, 2,  0, -2 ,
            -1, 1, -1, -1, 1, 1,  1, -1,
            0, 0  // go away and back is valid
        };

        vector<std::pair<int, int>> dirs;
        for (size_t i = 0; i < checkers.size() / 2; i++) {
            dirs.emplace_back(checkers[i * 2], checkers[i * 2 + 1]);
        }

        return dirs;
    }

    bool hit_rock_dirs(int dist, pos_t cx, pos_t cy, int dx, int dy);
    bool hit_rock(int dist, pos_t nx, pos_t ny);

    node end_node() const { node n{.type = node::end}; return n; };

    // distances
    std::size_t idx_from_node(const node n) const {
        return (n.row * W) + (n.col);
    };

    int dist (const node n) const { return distances[idx_from_node(n)]; };
    void set_dist (const node n, int d) { distances[idx_from_node(n)] = d; };

    // input
    const grid<uint16_t> &m_g;

    // problem state
    vector<int> distances;
    vector<std::pair<node, int>> off_edge;
    unordered_map<node, bool> was_visited;

    // misc metadata
    int W;
    int H;

    // stats
    uint_fast64_t num_visits = 0, num_neighbor_passes = 0;
    uint_fast64_t cumu_visits = 0;
    uint_fast64_t num_neighbor_added = 0, num_distance_updates = 0;
};

bool pathfinder::hit_rock_dirs(int dist, pos_t cx, pos_t cy, int dx, int dy)
{
    if (!dx && !dy) {
        return false;
    }

    // just go through all the directions...
    if        (dx ==  0 && dy ==  2) {
        return hit_rock(dist, cx, cy + 1) || hit_rock(dist, cx, cy + 2);
    } else if (dx ==  0 && dy == -2) {
        return hit_rock(dist, cx, cy - 1) || hit_rock(dist, cx, cy - 2);
    } else if (dx ==  2 && dy ==  0) {
        return hit_rock(dist, cx + 1, cy) || hit_rock(dist, cx + 2, cy);
    } else if (dx == -2 && dy ==  0) {
        return hit_rock(dist, cx - 1, cy) || hit_rock(dist, cx - 2, cy);
    } else if (dx ==  1 && dy ==  1) {
        return hit_rock(dist, cx + 1, cy + 1) || (hit_rock(dist, cx + 1, cy) && hit_rock(dist, cx, cy + 1));
    } else if (dx ==  1 && dy == -1) {
        return hit_rock(dist, cx + 1, cy - 1) || (hit_rock(dist, cx + 1, cy) && hit_rock(dist, cx, cy - 1));
    } else if (dx == -1 && dy ==  1) {
        return hit_rock(dist, cx - 1, cy + 1) || (hit_rock(dist, cx - 1, cy) && hit_rock(dist, cx, cy + 1));
    } else if (dx == -1 && dy == -1) {
        return hit_rock(dist, cx - 1, cy - 1) || (hit_rock(dist, cx - 1, cy) && hit_rock(dist, cx, cy - 1));
    }

    return true;
}

bool pathfinder::hit_rock(int dist, pos_t nx, pos_t ny)
{
    // if we go off board, record where it would have happened
    if (nx >= W) {
        off_edge.emplace_back(node{.row = ny, .col = nx - W}, dist);
    }
    if (ny >= H) {
        off_edge.emplace_back(node{.row = ny - H, .col = nx}, dist);
    }
    if (nx < 0) {
        off_edge.emplace_back(node{.row = ny, .col = nx + W}, dist);
    }
    if (ny < 0) {
        off_edge.emplace_back(node{.row = ny + H, .col = nx}, dist);
    }

    return (nx < 0 || ny < 0 || nx >= W || ny >= H || m_g.at(nx, ny) == '#');
}

void pathfinder::find_min_path(const node start, const int max_steps)
{
    const auto node_distance_compare = [this](const node &l, const node &r) {
        return dist(l) > dist(r);
    };

    std::priority_queue<
        node, vector<node>,
        decltype(node_distance_compare)
        > to_visit(node_distance_compare);

    if constexpr (g_use_doublesteps) {
        if (max_steps % 2 != 0) {
            // make one step manually and then go by two as normal
            // note that we can't ever land on the start spot again in this
            // situation so it shouldn't be part of the visit set!

            for (const auto &new_dir : neighbor_dirs_one_step()) {
                auto [dx, dy] = new_dir;
                if (hit_rock(1, start.col + dx, start.row + dy)) {
                    continue;
                }

                node c{start.col + dx, start.row + dy};
                set_dist(c, 1);
                to_visit.push(c);
            }
        }
    }

    // can happen if steps are even or double-stepping is not in use
    if (to_visit.empty()) {
        set_dist(start, 0);
        to_visit.push(start);
    }

    while(!to_visit.empty()) {
        node cur = to_visit.top();
        to_visit.pop();

        // each visit needs to reach out to all possible nodes reachable in one
        // move from here and mark those neighbors to be visited as
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

        int new_dist = dist(cur) + 1;

        if constexpr (g_use_doublesteps) {
            new_dist++; // 2 steps at a time
        }

        if (new_dist > max_steps) {
            // if we're searching this distance there's nothing shorter left
            was_visited[cur] = true;
            continue;
        }

        auto neighbors = neighbor_dirs_for_node();
        // in DCE we trust...
        if constexpr (!g_use_doublesteps) {
            neighbors = neighbor_dirs_one_step();
        }

        // Go through all possible directions and new nodes
        for (const auto &new_dir : as_const(neighbors)) {
            pos_t nx = cx;
            pos_t ny = cy;
            auto [dx, dy] = new_dir;

            nx += dx;
            ny += dy;

            if constexpr (g_use_doublesteps) {
                // we're taking an even number of steps and must move each
                // step, so plan out 2 steps at a time. This checks for that
                // and for staying on the board
                if (hit_rock_dirs(new_dist, cx, cy, dx, dy)) {
                    continue; // can't go through the rocks
                }
            } else {
                if (hit_rock(new_dist, nx, ny)) {
                    continue; // can't go through the rocks
                }
            }

            node candidate { ny, nx };
            if (!was_visited.contains(candidate)) {
                if (dist(candidate) > new_dist) {
                    set_dist(candidate, new_dist);

                    num_distance_updates++;
                }

                to_visit.push(candidate);
                num_neighbor_added++;
            }
        }

        was_visited[cur] = true;
    }

    // before we return, ensure our list of out-of-bounds encounters has
    // been de-duplicated
    const auto comp = [](const auto &l, const auto &r) {
        if (l.second < r.second) {
            return true;
        } else if (r.second < l.second) {
            return false;
        } else {
            return l.first < r.first;
        }
    };

    std::sort(off_edge.begin(), off_edge.end(), comp);
    vector<std::pair<node, int>> temp;
    std::unique_copy(off_edge.begin(), off_edge.end(), back_inserter(temp));
    std::swap(off_edge, temp);
}

static void draw_color_grid(const pathfinder &p, const int max_steps)
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
    int sum = 0;
    const int H = p.m_g.height();
    const int W = p.m_g.width();

    for (pos_t j = 0; j < H; j++) {
        for (pos_t i = 0; i < W; i++) {
            node n{.row = j, .col = i};
            if (auto d = p.dist(n); d <= max_steps) {
                sum++;

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
        cout << ", avg visit queue: " << p.cumu_visits / p.num_visits;
        cout << ", neighbor_passes: " << p.num_neighbor_passes;
        cout << ", neighbor_added: " << p.num_neighbor_added;
        cout << ", distance_updates: " << p.num_distance_updates;
        cout << "\n";
        cout << "grid size: " << W * H;
        cout << ", avg neighbors per grid cell: " << p.num_neighbor_added / (W * H);
        cout << "\n";
    }

    cout << "Could reach " << p.was_visited.size() << " garden plots.\n";
    cout << "The ones highlighted are reachable using up to " << max_steps << " steps.\n";
}

static unsigned long count_cells_recursive(
        const grid<uint16_t> &g,
        node start,
        int max_steps,
        bool trisect,
        int subdivide
        )
{
    using std::pair;
    unsigned long sum = 0;

    pathfinder p(g);

    p.find_min_path(start, max_steps);
    sum = p.was_visited.size();

    if (g.at(start.col, start.row) == 'S') {
        draw_color_grid(p, subdivide ? subdivide : max_steps);
    }

    if (trisect) {
        // break up distances by what part of grid they fell into
        vector<int> tri_dist(9, 0);
        pos_t third_h = g.height() / 3;
        pos_t third_w = g.width() / 3;

        for (const auto &p : p.was_visited) {
            const node n = p.first;
            pos_t cy = 2, cx = 2;
            while(n.row < cy * third_h)
                cy--;
            while(n.col < cx * third_w)
                cx--;
            tri_dist[3 * cy + cx]++;
        }

        for (size_t j = 0; j < 3; j++) {
            for (size_t i = 0; i < 3; i++) {
                const auto idx = j * 3 + i;
                std::cout << "Sec. " << idx << ' ' << tri_dist[idx] << ", ";
            }
            std::cout << "\n";
        }

        int sum = std::accumulate(tri_dist.begin(), tri_dist.end(), 0);
        std::cout << "checksum: " << sum << "\n";
    }

    if (subdivide > 0) {
        // break up into visited cells that are <= the given value or those
        // greater.
        int even_corners = std::count_if(p.was_visited.begin(), p.was_visited.end(),
                [&p, subdivide](const auto &val) {
                const auto d = p.dist(val.first);
                return (d % 2 == 0 && d > subdivide);
                });
        int even_interior = std::count_if(p.was_visited.begin(), p.was_visited.end(),
                [&p, subdivide](const auto &val) {
                const auto d = p.dist(val.first);
                return (d % 2 == 0 && d <= subdivide);
                });

        std::cout << "For even parity:\n";
        std::cout << "\t" << even_corners << " plots reachable >" << subdivide << "\n";
        std::cout << "\t" << even_interior << " plots reachable <=" << subdivide << "\n";

        int odd_corners = std::count_if(p.was_visited.begin(), p.was_visited.end(),
                [&p, subdivide](const auto &val) {
                const auto d = p.dist(val.first);
                return (d % 2 == 1 && d > subdivide);
                });
        int odd_interior = std::count_if(p.was_visited.begin(), p.was_visited.end(),
                [&p, subdivide](const auto &val) {
                const auto d = p.dist(val.first);
                return (d % 2 == 1 && d <= subdivide);
                });

        std::cout << "For odd parity:\n";
        std::cout << "\t" << odd_corners << " plots reachable >" << subdivide << "\n";
        std::cout << "\t" << odd_interior << " plots reachable <=" << subdivide << "\n";

        const int assumed_steps = 26501365; // from problem input
        const int odd_full = odd_corners + odd_interior;
        const int even_full = even_corners + even_interior;

        // number of grids in each dir
        const long n = (assumed_steps - g.width()/2) / g.width();

        unsigned long total =  // Don't you feel so smart?? I feel so smart!!
            ((n+1)*(n+1)) * odd_full +
            (n*n) * even_full -
            (n+1) * odd_corners +
            n * even_corners; // so l33t!!!!111one

        std::cout << "In theory the final answer for this particular remarkably well-behaved input\n";
        std::cout << "is: \e[30;102m" << total << "\e[0m\n";
    }

    return sum;
}

int main(int argc, char **argv)
{
    using namespace std::chrono;
    using std::cout;

    int max_steps = 0;
    int subdivide = 0;
    bool trisect = false;
    int opt;
    while ((opt = getopt(argc, argv, "th")) != -1) {
        switch(opt) {
            default:
            case 's':
                subdivide = true;
                break;
            case 't':
                trisect = true;
                break;
            case 'h': cout << "usage: ./garden [-t] filename [max_steps] [subdivision]\n";
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

    if (++optind < argc) {
        max_steps = std::stoi(argv[optind]);
    }

    if (max_steps > 1024) {
        std::cerr << "Max steps seems too big: " << max_steps << "\n";
        return 1;
    }

    if (++optind < argc) {
        subdivide = std::stoi(argv[optind]);
    }

    auto g = make_grid(input);
    auto H = g.height(), W = g.width();

    if (!max_steps) {
        max_steps = std::max(H, W) - 1;
    }
    if (!subdivide && W == H) {
        subdivide = (W - 1) / 2;
    }

    // find start
    node start{};
    for (pos_t j = 0; j < H; j++) {
        for (pos_t i = 0; i < W; i++) {
            if (g.at(i, j) == 'S') {
                start.row = j;
                start.col = i;
                start.type = node::start;
            }
        }
    }

    if (start.type != node::start) {
        std::cout << "Couldn't find the start point!\n";
        return 1;
    }

    // now that we know we found it, reset to type=normal to avoid
    // splintering the multiverse
    start.type = node::normal;

    time_point t1 = steady_clock::now();

    unsigned long dist = count_cells_recursive(g, start, max_steps, trisect, subdivide);

    time_point t2 = steady_clock::now();

    if (!subdivide) {
        // answer given by the subdivision code
        cout << dist << "\n";
    }

    cout << "time: " << duration<double>(t2 - t1).count() << "\n";

    return 0;
}

// vim: fdm=marker:
