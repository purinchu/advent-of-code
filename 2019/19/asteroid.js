#!/usr/bin/env node

'use strict';

// Advent of Code 2019 - Day 10, part 1

const fs = require('node:fs');
const process = require('node:process');

function * seq(start = 0, end = Infinity, step = 1) {
    for(let i = start; i < end; i += step) {
        yield i;
    }
}

function trap(msg) {
    throw new Error(msg);
}

function print(msg) {
    console.log(msg);
}

function gcd(n1, n2) {
    if (n2 === 0) {
        return n1;
    }
    return gcd(n2, n1 % n2);
}

function idx_from_pos(x, y, w) {
    return y * w + x;
}

function num_visible_from(field, x1, y1, w, h) {
    // sort other asteroids by distance so we can look for potential
    // occlusions first
    let dist_array = [];

    const ast = [x1, y1];

    for (const other of field) {
        const [x2, y2] = other;
        const distance = Math.abs(x2-x1) + Math.abs(y2-y1);

        if (distance == 0) {
            continue;
        }

        dist_array[distance] ||= [];
        dist_array[distance].push([x2, y2]);
    }

    // forEach is deliberate to skip undefined entries in this sparse array
    let blocked = new Set();
    let visible = new Set();

    dist_array.forEach((vals, dist) => {
        for (const v of vals) {
            const [x2, y2] = v;
            let [dx, dy] = [x2 - x1, y2 - y1];
            const div = gcd(Math.abs(dx), Math.abs(dy));

            dx /= div;
            dy /= div;

            if (blocked.has(idx_from_pos(x2, y2, w))) {
                continue;
            }

            visible.add(idx_from_pos(x2, y2, w));

            let y = y2;
            let x = x2;

            while ((x >= 0) && (x < w) && (y >= 0) && (y < h)) {
                blocked.add(idx_from_pos(x, y, w));
                x += dx;
                y += dy;
            }
        }
    });

    return visible.size;
}

try {
    const in_file = process.argv[2] || '../19/input';

    const file = fs.readFileSync(in_file, { encoding: 'utf8' });
    if (!file) {
        trap(`Unknown file ${in_file}!`);
    }

    let puzzle = new Set();

    const rows = file.split("\n").filter(x => x.length > 0);
    const w = rows[0].length;
    const h = rows.length;

    for (let y = 0; y < rows.length; y++) {
        const row = rows[y];
        for (let x = 0; x < row.length; x++) {
            if (row[x] == '#') {
                puzzle.add([x, y]);
            }
        }
    }

    let best = undefined;
    let count_max = 0;
    let max_ast = 0;

    for (const ast of puzzle) {
        const num_visible = num_visible_from(puzzle, ast[0], ast[1], w, h);
        if (num_visible > max_ast) {
            max_ast = num_visible;
            best = ast;
            count_max = 0;
        }

        if (num_visible == max_ast) {
            count_max += 1;
        }
    }

    if (count_max == 1) {
        print (`There were ${max_ast} asteroids visible from ${best}`);
    } else {
        throw new Error(`Found improper number of maxes ${count_max}`);
    }
} catch (err) {
    console.error(`Caught exception: "${err.message}"\n${err.stack}\n`);
    process.exit(1);
}

