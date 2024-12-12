#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 1, part 1

function loadInputLines() {
    const in_file = scriptArgs[1] || 'input';
    return std.loadFile(in_file)
        .split("\n")
        .filter((x) => x.length > 0)
    ;
}

try {
    const sum = loadInputLines().map((line) => {
        return Math.floor(line / 3) - 2;
    }).reduce(
        (acc, next) => (+acc) + (+next)
    );

    print (sum);

} catch (err) {
    std.err.printf("Caught exception %s\n", err.toString());
    std.exit(1);
}

