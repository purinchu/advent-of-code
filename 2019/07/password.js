#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 4, part 1

function loadInput() {
    const in_file = scriptArgs[1] || '../09/input';
    const lines = std.loadFile(in_file)
        .split("\n")
        .filter((x) => x.length > 0);
    const wires = lines.map((l) => l.split(','));
    return wires;
}

function * seq(start = 0, end = Infinity, step = 1) {
    for(let i = start; i < end; i += step) {
        yield i;
    }
}

function isPossible(val) {
    // Being six digit is required but this was checked for the whole range earlier
    // Likewise for being in puzzle range
    const s = val.toString();
    if (!s.match(/([0-9])\1/)) {
        return false;
    }

    const digits = s.split('');
    for (let i = 1; i < digits.length; i++) {
        if (digits[i - 1] > digits[i]) {
            return false;
        }
    }

    return true;
}

try {
    // No input for this one, instead pass range on command line
    const [low, high] = scriptArgs.slice(1, 3).map((x) => parseInt(x, 10));
    if (!low || !high || low < 100000 || low > 999999 || high < 100000 || high > 999999 || low >= high) {
        std.err.puts(`Invalid range ${low}-${high}. Usage $script <low> <high>, each 6-digit ints\n`);
        std.exit(1);
    }

    print(`Searching between ${low} and ${high}`);

    let count = 0;
    for (const i of seq(low, high + 1)) {
        if (isPossible(i)) {
            count++;
        }
    }

    print(`Total possible = ${count}`);
} catch (err) {
    std.err.puts(`Caught exception: "${err.message}"\n${err.stack}\n`);
    std.exit(1);
}

