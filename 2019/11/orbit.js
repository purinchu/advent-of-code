#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 6, part 1

function loadInput() {
    const in_file = scriptArgs[1] || '../11/input';
    const lines = std.loadFile(in_file)
        .split("\n")
        .filter((x) => x.length > 0);
    const orbits = lines.map((l) => l.split(')'));
    return orbits;
}

function * seq(start = 0, end = Infinity, step = 1) {
    for(let i = start; i < end; i += step) {
        yield i;
    }
}

function isPossible(val) {
    // Being six digit is required but this was checked for the whole range earlier
    // Likewise for being in puzzle range

    // Ensure we have at least one group of two of the same digit not followed
    // by a third or longer in the same consecutive run
    const s = val.toString();
    const matches = [...s.matchAll(/([0-9])\1+/g)];

    if (!matches.some((group) => group[0].length == 2)) {
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
    const orbits = loadInput();

    let centers = new Map();

    for (const o of orbits) {
        const [orbited, orbiter] = o;
//      print(`${orbiter} orbits ${orbited}`);
        centers.set(orbiter, orbited);
    }

    let sum = 0;

    let planets = new Set(centers.values());
    for (const p of centers.keys()) {
        planets.add(p);
    }

    for (const planet of planets.entries()) {
        let count = 0;
        let cur_planet = planet[0];
        while (centers.has(cur_planet)) {
            count += 1;
            cur_planet = centers.get(cur_planet);
        }
//      print (`${planet[0]} has ${count} orbits`);
        sum += count;
    }

    print (`Sum of all orbits: ${sum}`);

} catch (err) {
    std.err.puts(`Caught exception: "${err.message}"\n${err.stack}\n`);
    std.exit(1);
}

