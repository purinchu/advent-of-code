// AoC 2023 - Puzzle 33
//
// Grid stuff

#include <algorithm>
#include <concepts>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iostream>
#include <iterator>
#include <limits>
#include <numeric>
#include <string>
#include <string_view>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

// config

static const bool g_show_input = true;
static const bool g_show_final = true;

// common types

using std::as_const;
using std::pair;
using std::tuple;
using std::vector;

enum class Dir { west, east, north, south };
using pos_t = uint16_t;

struct node
{
    pos_t row = 0;
    pos_t col = 0;
    int distance = std::numeric_limits<int>::max();
    int consec_step = 0;
    Dir dir_in = Dir::north;
    bool visited = false;
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

    grid<std::uint16_t> g;

    try {
        input.open(argv[1]);
        string line;
        while (!input.eof() && std::getline(input, line)) {
            g.add_line(line);
        }

        input.close();
    }
    catch (ifstream::failure &e) {
        cerr << "Exception on reading input: " << e.what() << endl;
        return 1;
    }
    catch (...) {
        cerr << "Something else went wrong..." << endl;
        return 1;
    }

    if constexpr (g_show_input) {
        g.dump_grid();
        cout << "\n";
    }

    vector<node> nodes; // hold a grid of nodes with distances
    vector<size_t> unvisited; // holds IDs from nodes; working set

    std::ofstream dbg;
    dbg.open("debug.log");

    const auto W = g.width(), H = g.height();
    nodes.resize(W * H);
    for (pos_t j = 0; j < H; j++) {
        for (pos_t i = 0; i < W; i++) {
            nodes[j * W + i].row = j;
            nodes[j * W + i].col = i;
        }
    }

    nodes[0].distance = 0;
    int steps = 0;
    bool destination_found = false;
    Dir ldir;

    while(!destination_found) {
        using enum Dir;
        auto min_node_it = std::min_element(nodes.begin(), nodes.end(),
                [](const auto &l, const auto &r) {
                return (l.visited == r.visited)
                ? (l.distance < r.distance)
                : (l.visited < r.visited);
                });
        if (min_node_it == nodes.end() || min_node_it->visited) {
            break;
        }
        auto &cur = *min_node_it;
        auto cx = cur.col, cy = cur.row;
        steps = cur.consec_step;
        ldir = cur.dir_in;

        vector<tuple<node, Dir, int>> candidates;

        dbg << "Cur: " << cx << "," << cy << " distance " << cur.distance << "\n";

        if (cy > 0 && (!steps || ldir == east || ldir == west || (ldir == north && steps < 3))) {
            const auto n = nodes[(cy-1) * W + cx];
            if (!n.visited) { candidates.emplace_back(n, north, ldir == north ? steps + 1 : 1); }
        }
        if (cy < (H-1) && (!steps || ldir == east || ldir == west || (ldir == south && steps < 3))) {
            const auto n = nodes[(cy+1) * W + cx];
            if (!n.visited) { candidates.emplace_back(n, south, ldir == south ? steps + 1 : 1); }
        }
        if (cx > 0 && (!steps || ldir == north || ldir == south || (ldir == west && steps < 3))) {
            const auto n = nodes[cy * W + (cx-1)];
            if (!n.visited) { candidates.emplace_back(n, west, ldir == west ? steps + 1 : 1); }
        }
        if (cx < (W-1) && (!steps || ldir == north || ldir == south || (ldir == east && steps < 3))) {
            const auto n = nodes[cy * W + (cx+1)];
            if (!n.visited) { candidates.emplace_back(n, east, ldir == east ? steps + 1 : 1); }
        }

        dbg << "Considering " << candidates.size() << " neighbors\n";
        for (auto & neighbor : candidates) {
            auto &[node, dir, new_steps] = neighbor;
            auto &node_ref = nodes[node.row * W + node.col];

            dbg << "  Could move to " << node_ref.col << "," << node_ref.row << " (dir " << dir_name(dir) << ") ";
            int new_dist = cur.distance + (g.at(node.col, node.row) - '0');
            if (new_dist < node_ref.distance || (new_dist == node.distance && node.consec_step > new_steps)) {
                node_ref.distance = new_dist;
                node_ref.consec_step = new_steps;
                node_ref.dir_in = dir;
                dbg << "** ";
            }
            dbg << "Dist " << node_ref.distance << ", steps " << new_steps << "\n";
        }

        cur.visited = true;
        if (cur.col == W - 1 && cur.row == H - 1) {
            destination_found = true;
        }
    }

    cout << "Final distance to dest is " << nodes[H * W - 1].distance << "\n";

    static const char dir_ch[] = "<>^v";
    if constexpr (g_show_final) {
        for (pos_t j = 0; j < H; j++) {
            for (pos_t i = 0; i < W; i++) {
                const auto &n = nodes[j * W + i];
                cout << dir_ch[(int)n.dir_in];
            }
            cout << "\n";
        }
        //      g.dump_grid();
    }

    return 0;
}

// vim: fdm=marker:
