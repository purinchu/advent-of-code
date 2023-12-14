// AoC 2023 - Puzzle 28
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
#include <numeric>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

// config

static const bool g_show_input = false;
static const bool g_show_dirs = false;
static const bool g_show_steps = false;
static const bool g_show_final = false;
static const std::uint_least64_t g_max_cycles = 1'000'000'000;

// common types

using std::as_const;
using std::vector;

enum class Dir { west, east, north, south };

// coordinate system:
// leftmost character is 0, increases by 1 each character going to the right
// topmost character is 0, increases by 1 each additional line down
template <std::integral T>
struct grid
{
    using container_t = vector<char>;
    using pos_t       = T;

    void add_line(const std::string &line);

    container_t extract_line(const pos_t pos, const Dir dir) const;
    void set_line(const container_t &line, const pos_t pos, const Dir dir);

    void fall(Dir dir);

    pos_t height() const { return m_height; }
    pos_t width() const { return m_width; }
    std::string_view view() const { return std::string_view(m_grid.data(), m_width * m_height); }

    void dump_grid() const;

public:
    container_t m_grid;
    pos_t m_width = 0, m_height = 0;
};

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

template <std::integral T>
auto grid<T>::extract_line(pos_t pos, Dir dir) const
    -> container_t
{
    container_t result;
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
    for (pos_t i = start; i != end; i += stride) {
        result.push_back(m_grid[i]);
    }

    return result;
}

template <std::integral T>
void grid<T>::set_line(const container_t &line, const pos_t pos, const Dir dir)
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
    auto it = line.begin();
    for (pos_t i = start; i != end; i += stride) {
        m_grid[i] = *it++;
    }
}

template <std::integral T>
void grid<T>::fall(Dir dir)
{
    using std::find;

    const pos_t max_extent =
        (dir == Dir::north || dir == Dir::south)
            ? m_height
            : m_width;

    for (pos_t i = 0; i < max_extent; i++) {
        // the line we extract has position 0 farther AWAY from the given dir
        // and position foo.size() - 1 farthest TOWARDS.
        // So to make rocks 'O' fall NORTH (dir == dir::north), we must push
        // them to the far right of the array.
        auto l = this->extract_line(i, dir);

        // sort in areas between boulders '#'
        auto start_pos = find_if(l.begin(), l.end(), [](const auto &v) { return v != '#'; });
        auto end_pos = find(start_pos, l.end(), '#');
        while(start_pos != l.end() || end_pos != l.end()) {
            sort(start_pos, end_pos); // take advantage that '.' < 'O'

            start_pos = find_if(end_pos, l.end(), [](const auto &v) { return v != '#'; });
            end_pos = find(start_pos, l.end(), '#');
        }

        this->set_line(l, i, dir);
    }
}

template <typename T>
static int load_factor(const grid<T> &g, const Dir dir)
{
    vector<int> weights(g.height(), 0);
    std::iota(weights.begin(), weights.end(), 1);

    int sum = 0;

    for (int i = 0; i < g.width(); i++) {
        auto l = g.extract_line(i, dir);

        // Mask stones to apply with inner product
        std::transform(l.begin(), l.end(), l.begin(), [](const auto &v) { return v == 'O'; });
        sum += std::inner_product(l.begin(), l.end(), weights.begin(), 0);
    }

    return sum;
}

static const char *dir_name(Dir d)
{
    switch(d) {
        case Dir::east:  return "east";
        case Dir::west:  return "west";
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

    if constexpr (g_show_dirs) {
        const Dir dirs[] = { Dir::north, Dir::south, Dir::east, Dir::west };

        for (const auto &dir : dirs) {
            for (int i = 0; i < 10; i++) {
                const auto chars = g.extract_line(i, dir);
                cout << "Dir " << dir_name(dir) << ": ";
                std::copy(chars.begin(), chars.end(), std::ostream_iterator<char>(cout));
                cout << "\n";
            }

            cout << "\n";
        }
    }

    // Do the spin cycles but look for a shortcut to abort early.
    std::unordered_map<std::size_t, std::uint_least64_t> cache;
    for (std::uint_least64_t i = 0; i < g_max_cycles; i++) {
        g.fall(Dir::north);
        g.fall(Dir::west);
        g.fall(Dir::south);
        g.fall(Dir::east); // spin cycle!

        if constexpr (g_show_steps) {
            cout << "After cycle " << i << "\n";
            g.dump_grid();
        }

        // Check if we've been in this exact state before
        const auto sv = g.view();

        // Generate hash code separately because directly using a view with
        // unordered_map won't work as the different views point to same
        // memory (always compares equal) and I don't want to store entire
        // grid for each key.
        const auto h = std::hash<std::string_view>{}(sv);

        if (const auto it = cache.find(h); it != cache.end()) {
            const auto &[prev_h, prev_cycle] = *it;
            const auto cycle_length = i - prev_cycle;
            const auto remainder = (g_max_cycles - i - 1) % cycle_length;
            if (!remainder) {
                cout << "Stopping at cycle " << i << ", cycle length " << cycle_length << "\n";
                break;
            }
        } else {
            cache.emplace(h, i);
        }
    }

    if constexpr (g_show_final) {
        g.dump_grid();
    }

    cout << load_factor(g, Dir::north) << "\n";

    return 0;
}
