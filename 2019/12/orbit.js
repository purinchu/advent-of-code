#!../../qjs/qjs --std

'use strict';

// Advent of Code 2019 - Day 6, part 2

function loadInput() {
    const in_file = scriptArgs[1] || '../11/input';
    const lines = std.loadFile(in_file)
        .split("\n")
        .filter((x) => x.length > 0);
    const orbits = lines.map((l) => l.split(')'));
    return orbits;
}

try {
    // No input for this one, instead pass range on command line
    const orbits = loadInput();

    let centers = new Map();

    for (const o of orbits) {
        const [orbited, orbiter] = o;
        centers.set(orbiter, orbited);
    }

    let costs = [new Map(), new Map()];
    let moves = [        0,         0];
    let locs  = [    'YOU',     'SAN'].map((x) => centers.get(x));

    while(true) {
        for(let i = 0; i < costs.length; i++) {
            const other_idx = 1 - i;

            // we may have already made it as far as possible and should wait
            if (locs[i] != 'COM') {
                moves[i] += 1;
                locs[i] = centers.get(locs[i]);
            }

            if (costs[other_idx].has(locs[i])) {
                const total = moves[i] + costs[other_idx].get(locs[i]);
                print(`Total cost: ${total}`);
                std.exit(0);
            } else {
                costs[i].set(locs[i], moves[i]);
            }
        }
    }

} catch (err) {
    std.err.puts(`Caught exception: "${err.message}"\n${err.stack}\n`);
    std.exit(1);
}

