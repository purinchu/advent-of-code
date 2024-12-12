#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 1, part 2

function loadInputLines() {
    const in_file = scriptArgs[1] || '../01/input';
    return std.loadFile(in_file)
        .split("\n")
        .filter((x) => x.length > 0)
    ;
}

function fuelInception(weight) {
    let extraFuel = Math.floor(weight / 3) - 2;

    if (extraFuel <= 0) {
        return 0;
    } else {
        return extraFuel + fuelInception(extraFuel);
    }
}

try {
    const bulked_up = loadInputLines().map((line) => fuelInception(+line));
    const sum = bulked_up.reduce((ac, next) => ac + next);

    print (sum);

} catch (err) {
    std.err.printf("Caught exception %s\n", err.toString());
    std.exit(1);
}

