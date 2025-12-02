#include <print>
#include <charconv>
#include <fstream>
#include <string>
#include <string_view>
#include <vector>

using std::tuple;
using std::string;
using std::vector;

enum class Dir {
    Left, Right,
};

using Pos = uint8_t;
using DialAmt = uint16_t;
using Turn = tuple<Dir, DialAmt>;
using Turns = vector<Turn>;
using RotateRes = tuple<Pos, int>;

static Turns get_turns(const string &fname)
{
    Turns out;
    std::ifstream in_f(fname, std::ios::in);
    if (!in_f.is_open()) {
        throw std::runtime_error("Failed to open file");
    }

    string buf(10, '\0');

    while (in_f.getline(buf.data(), buf.size())) {
        char dir = buf[0];
        DialAmt amt;
        std::from_chars(buf.data() + 1, buf.data() - 1 + buf.size(), amt);

        out.emplace_back(std::make_tuple(dir == 'R' ? Dir::Right : Dir::Left, amt));
    }

    return out;
}

static RotateRes rotate_ptr(Pos ptr, const Turn &turn)
{
    // we want to count zeroes we ever hit so the cleanest thing
    // is to simply figure out how far to turn the dial until the next zero
    // But we do need to account for counting down from 0 (if we're turning left)

    auto [dir, amt] = turn;
    int16_t out  = (dir == Dir::Left && ptr == 0) ? 100 : ptr;
    int16_t sign = (dir == Dir::Left)             ? -1  : 1;
    int16_t rem  = (dir == Dir::Left)             ? out : 100 - ptr;

    int zeroes = 0;
    if (amt >= rem) {
        // will definitely hit zero, do so and remove any excess full turns
        amt -= rem;
        zeroes = 1;

        while (amt >= 100) {
            amt -= 100;
            zeroes++;
        }

        // Final rotation, if any, cannot cross zero again, so finalize out
        // to a valid range
        out = 0;
        if (dir == Dir::Left && amt > 0) {
            out = 100;
        }
    }

    // Final adjustment will not cross zero
    out += sign * amt;
    return std::make_tuple(Pos(out), zeroes);
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        std::println("Pass filename to read");
        return 1;
    }

    string fname(argv[1]);

    try {
        const Turns turns = get_turns(fname);
        Pos ptr = 50;
        uint16_t zeroes = 0;

        for (const auto &t : turns) {
            const auto [new_ptr, num_zeroes] = rotate_ptr(ptr, t);

            ptr = new_ptr;
            zeroes += num_zeroes;
        }

        std::println("Final ptr {}, num zeroes = {}", ptr, zeroes);
    }
    catch (std::runtime_error &err) {
        std::println("Error {} while handling {}", err.what(), fname);
        return 1;
    }
    catch (...) {
        std::println("Unknown error handling {}", fname);
        return 1;
    }

    return 0;
}
