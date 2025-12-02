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

using DialAmt = uint16_t;
using Turn = tuple<Dir, DialAmt>;
using Turns = vector<Turn>;

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

static uint8_t rotate_ptr(uint8_t ptr, const Turn &turn)
{
    int16_t out = ptr;
    const auto &[dir, amt] = turn;
    if (dir == Dir::Left) {
        out -= amt;
    }
    else {
        out += amt;
    }

    while (out < 0)    { out += 100 ; };
    while (out >= 100) { out -= 100 ; };

    return out;
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
        uint8_t ptr = 50;
        uint16_t zeroes = 0;

        for (const auto &t : turns) {
            ptr = rotate_ptr(ptr, t);
            if (ptr == 0) {
                zeroes ++;
            }
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
