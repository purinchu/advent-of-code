#include <algorithm>
#include <array>
#include <fstream>
#include <iostream>
#include <ranges>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

using std::array;
using std::make_pair;
using std::pair;
using std::size_t;
using std::string;
using std::string_view;
using std::vector;

namespace stdr = std::ranges;
namespace stdv = std::views;

using namespace std::literals::string_view_literals;

using ID          = std::uint64_t;
using FreshRange  = std::pair<ID, ID>;
using FreshIDs    = vector<FreshRange>;
using Ingredients = vector<ID>;
using Data        = std::pair<FreshIDs, Ingredients>;

static auto bounds_from_range(std::string_view freshness)
    -> pair<ID, ID>
{
    size_t pos = freshness.find("-"sv);

    const auto left = freshness.substr(0, pos);
    const auto right = freshness.substr(pos + 1);

    ID outl, outr;
    std::from_chars(left.data(), left.data() + left.size(), outl);
    std::from_chars(right.data(), right.data() + right.size(), outr);

    return std::make_pair(outl, outr);
}

static Data get_freshness_input(const string &fname)
{
    FreshIDs ids;
    Ingredients ingrs;

    std::ifstream in_f(fname, std::ios::in);
    if (!in_f.is_open()) {
        throw std::runtime_error("Failed to open file");
    }

    string out;
    while(std::getline(in_f, out) && !out.empty()) {
        ids.emplace_back(bounds_from_range(out));
    }

    stdr::sort(ids);

    while(std::getline(in_f, out)) {
        ID out_id;
        std::from_chars(out.data(), out.data() + out.size(), out_id);
        ingrs.emplace_back(out_id);
    }

    stdr::sort(ingrs);

    return make_pair(std::move(ids), std::move(ingrs));
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        std::cerr << "Pass filename to read\n";
        return 1;
    }

    const string fname(argv[1]);
    try {
        const auto [freshness, ingredients] = get_freshness_input(fname);

        // we already sorted the freshness data so just go through it row by
        // row
        ID last_l = 0, last_r = 0;
        ID sum = 0;
        for (const auto &[l, r] : freshness) {
            if (l <= last_r) {
                // overlap
                last_r = std::max(r, last_r);
            }
            else {
                // end of overlap
                if (last_l > 0) {
                    ID delta = last_r - last_l + 1;
                    sum += delta;
                }

                last_l = l;
                last_r = r;
            }
        }

        // end of overlap
        ID delta = last_r - last_l + 1;
        sum += delta;

        std::cout << sum << "\n";
    }
    catch (std::runtime_error &err) {
        std::cerr << "Error " << err.what() << " while handling " << fname << "\n";
        return 1;
    }
    catch (...) {
        std::cerr << "Unknown error handling " << fname << "\n";
        return 1;
    }

    return 0;
}
