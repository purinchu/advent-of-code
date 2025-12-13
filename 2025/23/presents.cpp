#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstring>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <optional>
#include <ranges>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

using std::array;
using std::cerr;
using std::cout;
using std::get;
using std::make_pair;
using std::make_tuple;
using std::optional;
using std::pair;
using std::size_t;
using std::string;
using std::string_view;
using std::tuple;
using std::unordered_map;
using std::vector;

namespace stdr = std::ranges;
namespace stdv = std::views;
using namespace std::literals::string_view_literals;

using Line = array<uint8_t, 3>;
using Present = array<Line, 3>; // A present is always a 3x3 bitmask
using Presents = vector<Present>; // index is important to the problem
using Configuration = tuple<int, int, vector<int>>; // w, h, list of present counts
using Configurations = vector<Configuration>;
using Problem = pair<Presents, Configurations>;
using Board = tuple<int, int, vector<uint8_t>>; // a filled-in board

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

static auto break_off_prefix_by(string_view line, char delim)
    -> pair<string_view, string_view> // [prefix, rest of line]
{
    size_t pos = line.find(delim);
    if (pos < line.size()) {
        return make_pair(line.substr(0, pos), line.substr(pos + 1));
    }
    return make_pair(string_view{}, line);
}

static auto get_present(string_view data)
    -> pair<Present, string_view>
{
    // calling code has already checked the first line is a present, skip it
    const auto &[_, pres_data] = break_off_prefix_by(data, '\n');
    const auto enter_line = [](Line &out, string_view chars) {
        for (size_t idx = 0; idx < out.size(); idx++) {
            out[idx] = (chars[idx] == '#' ? 1 : 0);
        }
    };

    Present out;

    const auto &[line1, lines23aft] = break_off_prefix_by(pres_data, '\n');
    enter_line(out[0], line1);

    const auto &[line2, lines3aft] = break_off_prefix_by(lines23aft, '\n');
    enter_line(out[1], line2);

    const auto &[line3, after] = break_off_prefix_by(lines3aft, '\n');
    enter_line(out[2], line3);

    return make_pair(std::move(out), after.substr(after.find_first_of("0123456789"sv)));
}

static Configuration get_configuration(string_view line)
{
    auto &&[w, w_after] = break_off_prefix_by(line, 'x');
    auto &&[h, h_after] = break_off_prefix_by(w_after, ':');

    vector<int> present_count;
    auto cur_str = skip_ws(h_after);
    while (!cur_str.empty()) {
        auto &&[num, cur_after] = break_off_prefix_by(cur_str, ' ');
        if (!num.empty()) {
            present_count.emplace_back(int_from_str(num));
            cur_str = cur_after;
        }
        else {
            present_count.emplace_back(int_from_str(cur_after));
            break;
        }
    }

    return make_tuple(int_from_str(w), int_from_str(h), std::move(present_count));
}

static Problem get_input_problem(string_view lines)
{
    // read presents until we run into the config section
    Presents out_presents;
    string_view cur_data = lines;

    while (cur_data.substr(0, 4).find('x') == string::npos) {
        auto [present, rest_of_string] = get_present(cur_data);
        cur_data = rest_of_string;
        out_presents.emplace_back(std::move(present));
    }

    Configurations out_configs = stdv::split(cur_data, '\n')
        | stdv::transform([](const auto &subr) { return string_view{subr.begin(), subr.end()}; })
        | stdv::filter([](const auto &line) { return !line.empty(); })
        | stdv::transform(get_configuration)
        | stdr::to<vector>();
    return make_pair(std::move(out_presents), std::move(out_configs));
}

static constexpr uint8_t board_at(const Board &b, size_t x, size_t y)
{
    const auto &[w, _, vec] = b;
    return vec[y * w + x];
}

void dump_board (const Board &b)
{
    const auto &[w, h, vec] = b;

    cout << "Board configuration (" << w << "x" << h << "):\n";
    for (int row = 0; row < h; row++) {
        for (int col = 0; col < w; col++) {
            cout << ((board_at(b, col, row) > 0)
                ? '#'
                : '.');
        }
        cout << "\n";
    }
}

static int num_bits_for_present(const Present &p)
{
    const auto sum_line = [](const Line &l) {
        return stdr::fold_left(l, 0, std::plus{});
    };
    return stdr::fold_left(p | stdv::transform(sum_line), 0, std::plus{});
}

static constexpr Present rotate_present_cw(const Present &p)
{
    Present out {
        Line { p[2][0], p[1][0], p[0][0] },
        Line { p[2][1], p[1][1], p[0][1] },
        Line { p[2][2], p[1][2], p[0][2] },
    };

    return out;
}

static constexpr Present flip_present_vert(const Present &p)
{
    Present out(p);
    for (size_t i = 0; i < p[0].size(); i++) {
        out[i][0] = p[i][2];
        out[i][2] = p[i][0];
    }

    return out;
}

static constexpr Present flip_present_horiz(const Present &p)
{
    return Present{p[2], p[1], p[0]};
}

// rotation is a 3-bit value
// bit 0 rotates clockwise 90 deg
// bit 1 flips horizontally
// bit 2 flips vertically
static constexpr Present rotate_present(const Present &p, int rotation)
{
    if constexpr (false) {
        if (rotation < 0 || rotation >= 8) {
            throw std::runtime_error("invalid rotation");
        }
    }

    const bool do_rotate = (rotation & (1 << 0)) > 0;
    const bool do_fliph  = (rotation & (1 << 1)) > 0;
    const bool do_flipv  = (rotation & (1 << 2)) > 0;

    Present out(p);
    if (do_rotate) { out = rotate_present_cw(out); }
    if (do_fliph ) { out = flip_present_horiz(out); }
    if (do_flipv ) { out = flip_present_vert(out); }

    return out;
}

static constexpr auto place_present_at(const Board &b, const Present &p, int x, int y)
    -> optional<Board>
{
    Board out(b);
    auto &[w, _, vec] = out;

    for (size_t r = 0; r < p.size(); r++) {
        auto r_it = &vec[(y + r) * w + x];

        for (const auto &i : p[r]) {
            (*r_it) += i;
            r_it++;
        }
    }

    if (stdr::find(vec, 2) != vec.end()) {
        return {}; // no match
    }

    return std::make_optional(std::move(out));
}

static bool validate_fit_recursive(const Board b, const Presents &p, const Configuration &c)
{
    // fit just one present and, if that's possible, recurse to solve remainder
    // of the problem
    const auto &[w, h, pres_remain] = c;

    if (stdr::all_of(pres_remain, [](int c) { return c == 0; })) {
//      dump_board(b);
        return true; // no presents left, base case
    }

    for (size_t idx = 0; idx < pres_remain.size(); idx++) {
        const size_t p_idx = pres_remain.size() - 1 - idx; // count from end, I guess
        if (pres_remain[p_idx] == 0) {
            continue;
        }

        // found the present we want to find, now actually find it
        const Present &present = p[p_idx];

        // setup info for new config for recursive sub-calls
        vector<int> new_vec(pres_remain);
        new_vec[p_idx]--;
        const Configuration new_c = make_tuple(w, h, std::move(new_vec));
        const int max_row = h + 1 - 3;
        const int max_col = w + 1 - 3;

        for (int rot = 0; rot < 8; rot++) {
            // even if some configurations will allow a fit now, it might cause
            // later pieces not to fit, so we have to cycle through every
            // possible x,y combo *HERE* so that we can backtrack properly if
            // validate_fit_recursive later fails.

            for (int row = 0; row < max_row; row++) {
                for (int col = 0; col < max_col; col++) {
                    const Present &tmp_p(rotate_present(present, rot));
                    const auto &out = place_present_at(b, tmp_p, col, row);
                    if (out) {
                        bool res = validate_fit_recursive(*out, p, new_c);
                        if (res) {
                            return true;
                        }
                    }
                }
            }
        }

        // if we made it here we couldn't fit the present into the board
        return false;
    }

    return false;
}

static bool is_valid_configuration(const Presents &p, const Configuration &c)
{
    // first idiot check, are there even enough bits in the board to fit them
    // all?

    const auto &[w, h, cs] = c;
    int num_bits = 0;
    for (size_t idx = 0; idx < cs.size(); idx++) {
        num_bits += cs[idx] * num_bits_for_present(p[idx]);
    }

    if (num_bits > (w * h)) {
        cout << "not enough bits!\n";
        return false;
    }

    cout << "enough bits, might be ok\n";

    // now check if there's no possible way to run out of space by assuming no
    // overlapping.
    const auto num_presents = stdr::fold_left(cs, 0, std::plus{});
    const auto box_w = w / 3;
    const auto box_h = h / 3;
    if (box_w * box_h >= num_presents) {
        // every present can get it's own 9x9 box
        return true;
    }

    // undetermined, would need to look for overlapping
    vector<uint8_t> board(w * h, 0);
    Board b = make_tuple(w, h, std::move(board));

    return validate_fit_recursive(b, p, c);
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

        const auto data  = file_slurp(fname); // needs to outlive get_input_problem and num_paths_to
        const auto &[presents, config] = get_input_problem(data);

        int count = 0;

        for (const auto &c : config) {
            if (is_valid_configuration(presents, c)) {
                count++;
            }
        }

        const auto stop = steady_clock::now();

        cout << count;
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
