// AoC 2023 - Puzzle 33
//
// Grid stuff

#include <algorithm>
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
#include <string>
#include <string_view>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

// config

static const bool g_show_input = false;
static const bool g_show_final = false;
static const bool g_debug_log  = false;

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
    pos_t row = 0;
    pos_t col = 0;
    int consec_step = 0;
    Dir dir_in = Dir::north; // only valid for consec_step > 0

    bool operator==(const node& o) const = default;
};

template<>
struct std::hash<node>
{
    std::size_t operator()(const node& n) const noexcept
    {
        std::size_t h1 = std::hash<pos_t>{}(n.row);
        std::size_t h2 = std::hash<pos_t>{}(n.col);
        std::size_t h3 = std::hash<int>{}(n.consec_step);
        std::size_t h4 = std::hash<Dir>{}(n.dir_in);

        return h1 ^ (h2 << 1) ^ (h3 << 2) ^ (h4 << 3);
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
    os << std::setw(2) << (n.col+1) << ","
        << std::setw(2) << (n.row+1) << " "
        << (n.consec_step ? dir_name(n.dir_in) : "  -  ") << " "
        << n.consec_step << " steps";
    os.flags(os_flags);
    return os;
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

    std::ofstream dbg;
    dbg.open(g_debug_log ? "debug.log" : "/dev/null");

    const auto W = g.width(), H = g.height();

    vector<node> to_visit; // may have multiple node at an x,y, also incl dir,step

    unordered_map<node, int> distances;
    unordered_map<node, bool> was_visited;
    unordered_map<node, node> predecessors;

    node start { };
    distances[start] = 0;
    to_visit.push_back(start);

    while(!to_visit.empty()) {
        using enum Dir;

        auto min_node_it = std::min_element(to_visit.begin(), to_visit.end(),
                [&distances](const node &l, const node &r) {
                    const auto lnode = distances.find(l);
                    const auto rnode = distances.find(r);
                    const auto end = distances.end();
                    const auto m = std::numeric_limits<int>::max();
                    return ((lnode != end) ? lnode->second : m)
                         < ((rnode != end) ? rnode->second : m);
                });

        if (min_node_it == to_visit.end() || was_visited.contains(*min_node_it)) {
            cout << "Breaking early! Potential problem?";
            break;
        }

        auto cur   = *min_node_it;
        auto cx    = cur.col;
        auto cy    = cur.row;
        auto steps = cur.consec_step;
        Dir ldir   = cur.dir_in;

        dbg << "Cur: [" << cur << "]. distance " << distances[cur] << "\n";

        static const std::array dirs      = { north, south, west, east };
        static const std::array wrong_dir = { east, west, south, north };

        // new_dir is the direction we were going when we came into the new
        // cell. eg. to be 'south', we'd have come from the cell directly above
        // so the offset would be +1 (to get the right y from the cell above's y)
        static const std::array x_off     = { -1, 1, 0, 0 };
        static const std::array y_off     = { 0, 0, -1, 1 };

        // Go through all possible directions and new nodes
        for (const auto &new_dir : dirs) {
            const char *dn = dir_name(new_dir);
            dbg << "  considering " << dn << "\n";

            if (new_dir == wrong_dir[(int) ldir]) {
                dbg << "  " << dn << " won't work, wrong dir coming from " << dir_name(ldir) << "\n";
                continue; // no backward turns
            }

            int nx = cx + x_off[(int) new_dir];
            int ny = cy + y_off[(int) new_dir];

            dbg << "  " << dn << " gives x,y offset of (" << x_off[(int)new_dir] << "," << y_off[(int)new_dir] << ")\n";

            if (nx < 0 || ny < 0 || nx >= W || ny >= H) {
                dbg << "  " << dn << " won't work, takes us off board. " << nx << ' ' << ny << "\n";
                continue; // stay on the board
            }

            int new_steps = (ldir == new_dir) ? steps + 1 : 1;

            if (new_steps > 3) {
                dbg << "  " << dn << " won't work, 4 consecutive steps.\n";
                continue; // no lengthy straight-line distances
            }

            dbg << "  may add move to (" << nx + 1 << "," << ny + 1 << ") if distance works out.\n";

            node candidate { static_cast<pos_t>(ny), static_cast<pos_t>(nx), new_steps, new_dir };
            if (!was_visited.contains(candidate)) {
                to_visit.push_back(candidate);
                int new_dist = distances[cur] + (g.at(nx, ny) - '0');
                if (!distances.contains(candidate) || distances[candidate] > new_dist) {
                    dbg << "  did add new move to (" << nx+1 << "," << ny+1 << "), distance " << distances[candidate] << "\n";
                    distances[candidate] = new_dist;
                    predecessors[candidate] = cur;
                } else {
                    dbg << "  already going to visit (" << nx+1 << "," << ny+1 << "), distance " << distances[candidate] << "\n";
                }
            } else {
                dbg << "  did not add move to (" << nx+1 << "," << ny+1 << ") as it's already visited.\n";
                dbg << "  (distance is " << distances[candidate] << ")\n";
            }
        }

        was_visited[cur] = true;
        std::erase(to_visit, cur);

        dbg << "Visited " << cur << ". Now " << to_visit.size() << " elements to visit, "
            << distances.size() << " known distances, " << was_visited.size() <<  " already visited.\n";
    }

    cout << "Done, looking now...\n";

    vector<typename std::unordered_map<node, int>::value_type> results;
    std::copy_if(distances.begin(), distances.end(), std::back_inserter(results),
            [W, H](const auto &p) { return p.first.row == (H - 1) && p.first.col == (W - 1); });
    cout << "Found " << results.size() << " possible results\n";

    int min_dist = std::numeric_limits<int>::max();
    node min_node;
    for (const auto &r : as_const(results)) {
        if (r.second < min_dist) {
            min_dist = r.second;
            min_node = r.first;
        }
    }

    cout << "Minimum distance of those results was " << min_dist << "\n";

    if constexpr (g_show_final) {
        int sum = 0;
        while(predecessors.contains(min_node)) {
            int d = (g.at(min_node.col, min_node.row) - '0');
            sum += d;
            cout << "to: [" << min_node << "] from: [" << predecessors[min_node] << "] " << d << " -> " << sum << "\n";
            min_node = predecessors[min_node];
        }
    }

    return 0;
}

// vim: fdm=marker:
